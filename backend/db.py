"""
SQLite storage layer for Insightr — all 12 insight features.
"""

from __future__ import annotations

import json
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from schema import (
    KnowledgeEntry, Connection, Concept, TypeSpecificField,
    ReferencedArtifact, NoteBlock,
)
from keywords import extract_keywords


SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS users (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS entries (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id              INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title                TEXT NOT NULL,
    source_url           TEXT NOT NULL,
    field                TEXT NOT NULL,
    content_type         TEXT NOT NULL DEFAULT 'general',
    type_specific_fields TEXT NOT NULL DEFAULT '[]',
    hook                 TEXT NOT NULL DEFAULT '',
    summary              TEXT NOT NULL,
    key_points           TEXT NOT NULL,
    implementation_plan  TEXT NOT NULL DEFAULT '[]',
    tools_resources      TEXT NOT NULL DEFAULT '[]',
    rabbit_hole          TEXT NOT NULL DEFAULT '{}',
    referenced_artifacts TEXT NOT NULL DEFAULT '[]',
    effort_estimation    TEXT,
    missing_context      TEXT NOT NULL DEFAULT '[]',
    explore_further      TEXT NOT NULL DEFAULT '[]',
    next_step            TEXT NOT NULL,
    keywords             TEXT NOT NULL DEFAULT '[]',
    note_blocks          TEXT NOT NULL DEFAULT '[]',
    is_favorite          INTEGER NOT NULL DEFAULT 0,
    is_implementing      INTEGER NOT NULL DEFAULT 0,
    created_at           TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS tags (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS entry_tags (
    entry_id INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    tag_id   INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (entry_id, tag_id)
);

CREATE TABLE IF NOT EXISTS action_items (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id      INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    text          TEXT NOT NULL,
    done          INTEGER NOT NULL DEFAULT 0,
    priority      TEXT NOT NULL DEFAULT 'soon',
    time_estimate TEXT
);

CREATE TABLE IF NOT EXISTS claims (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id      INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    claim         TEXT NOT NULL,
    verifiability TEXT NOT NULL DEFAULT 'unverified',
    note          TEXT
);

CREATE TABLE IF NOT EXISTS connections (
    entry_id         INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    related_entry_id INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    reason           TEXT NOT NULL,
    PRIMARY KEY (entry_id, related_entry_id)
);

CREATE TABLE IF NOT EXISTS concepts (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    concept_type TEXT NOT NULL,
    name         TEXT NOT NULL,
    summary      TEXT NOT NULL,
    created_at   TEXT NOT NULL,
    UNIQUE (concept_type, name COLLATE NOCASE)
);

CREATE TABLE IF NOT EXISTS entry_concepts (
    entry_id   INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    concept_id INTEGER NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,
    PRIMARY KEY (entry_id, concept_id)
);

CREATE TABLE IF NOT EXISTS collections (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name    TEXT NOT NULL,
    UNIQUE (user_id, name)
);

CREATE TABLE IF NOT EXISTS collection_entries (
    collection_id INTEGER NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    entry_id      INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    PRIMARY KEY (collection_id, entry_id)
);

CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
    title, summary_text, key_points, claims_text, tags_text, tools_text, action_items_text,
    content='', tokenize='porter'
);
"""

# New columns added after initial release — applied via _migrate()
MIGRATION_COLUMNS = [
    ("content_type",         "TEXT NOT NULL DEFAULT 'general'"),
    ("type_specific_fields", "TEXT NOT NULL DEFAULT '[]'"),
    ("keywords",             "TEXT NOT NULL DEFAULT '[]'"),
    ("implementation_plan",  "TEXT NOT NULL DEFAULT '[]'"),
    ("tools_resources",      "TEXT NOT NULL DEFAULT '[]'"),
    ("rabbit_hole",          "TEXT NOT NULL DEFAULT '{}'"),
    ("effort_estimation",    "TEXT"),
    ("missing_context",      "TEXT NOT NULL DEFAULT '[]'"),
    ("note_blocks",          "TEXT NOT NULL DEFAULT '[]'"),
    # v2 additions
    ("hook",                 "TEXT NOT NULL DEFAULT ''"),
    ("is_favorite",          "INTEGER NOT NULL DEFAULT 0"),
    ("is_implementing",      "INTEGER NOT NULL DEFAULT 0"),
    # v3 multi-user
    ("user_id",              "INTEGER NOT NULL DEFAULT 1"),
]

# Migrations for child tables (action_items columns added post-launch)
MIGRATION_ACTION_ITEMS_COLUMNS = [
    ("priority",      "TEXT NOT NULL DEFAULT 'soon'"),
    ("time_estimate", "TEXT"),
]

# Migrations for collections table
MIGRATION_COLLECTIONS_COLUMNS = [
    ("user_id", "INTEGER NOT NULL DEFAULT 1"),
]


def get_connection(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.row_factory = sqlite3.Row
    return conn


def _migrate(conn: sqlite3.Connection) -> None:
    # 0. Ensure users table exists (for upgrades from pre-multiuser schema)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    # Ensure a default user exists for legacy data
    existing_default = conn.execute("SELECT id FROM users WHERE id = 1").fetchone()
    if not existing_default:
        conn.execute(
            "INSERT OR IGNORE INTO users (id, username, created_at) VALUES (1, 'default', ?)",
            (datetime.now().isoformat(),)
        )

    # 1. Standard entries table migrations
    existing = {row["name"] for row in conn.execute("PRAGMA table_info(entries)")}
    for col_name, col_def in MIGRATION_COLUMNS:
        if col_name not in existing:
            conn.execute(f"ALTER TABLE entries ADD COLUMN {col_name} {col_def}")

    # 2. action_items table migrations
    existing_ai = {row["name"] for row in conn.execute("PRAGMA table_info(action_items)")}
    for col_name, col_def in MIGRATION_ACTION_ITEMS_COLUMNS:
        if col_name not in existing_ai:
            conn.execute(f"ALTER TABLE action_items ADD COLUMN {col_name} {col_def}")

    # 3. collections table migrations
    existing_coll = {row["name"] for row in conn.execute("PRAGMA table_info(collections)")}
    for col_name, col_def in MIGRATION_COLLECTIONS_COLUMNS:
        if col_name not in existing_coll:
            conn.execute(f"ALTER TABLE collections ADD COLUMN {col_name} {col_def}")
    
    # 4. FTS migration — FTS5 doesn't support ALTER TABLE. 
    try:
        conn.execute("SELECT action_items_text FROM entries_fts LIMIT 1")
    except sqlite3.OperationalError:
        conn.execute("DROP TABLE IF EXISTS entries_fts")
        fts_sql = """
        CREATE VIRTUAL TABLE entries_fts USING fts5(
            title, summary_text, key_points, claims_text, tags_text, tools_text, action_items_text,
            content='', tokenize='porter'
        )
        """
        conn.execute(fts_sql)
        conn.execute("""
            INSERT INTO entries_fts (rowid, title, summary_text, key_points, claims_text, tags_text, tools_text, action_items_text)
            SELECT e.id, e.title, e.summary, e.key_points, '', '', '', ''
            FROM entries e
        """)
        
    conn.commit()


def init_db(db_path: str) -> None:
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = get_connection(db_path)
    try:
        conn.executescript(SCHEMA_SQL)
        conn.commit()
        _migrate(conn)
    finally:
        conn.close()


def _get_or_create_tag(conn: sqlite3.Connection, name: str) -> int:
    name = name.strip().lower()
    cur = conn.execute("SELECT id FROM tags WHERE name = ?", (name,))
    row = cur.fetchone()
    if row:
        return row["id"]
    cur = conn.execute("INSERT INTO tags (name) VALUES (?)", (name,))
    return cur.lastrowid


# ---------------------------------------------------------------------------
# User management
# ---------------------------------------------------------------------------

def get_or_create_user(db_path: str, username: str) -> int:
    """Gets existing user by username or creates a new one. Returns user_id."""
    conn = get_connection(db_path)
    try:
        username = username.strip().lower()
        row = conn.execute("SELECT id FROM users WHERE username = ?", (username,)).fetchone()
        if row:
            return row["id"]
        cur = conn.execute(
            "INSERT INTO users (username, created_at) VALUES (?, ?)",
            (username, datetime.now().isoformat()),
        )
        conn.commit()
        return cur.lastrowid
    finally:
        conn.close()


def list_users(db_path: str) -> List[sqlite3.Row]:
    """Returns all registered users."""
    conn = get_connection(db_path)
    try:
        return conn.execute("SELECT id, username, created_at FROM users ORDER BY id").fetchall()
    finally:
        conn.close()


def save_entry(db_path: str, entry: KnowledgeEntry, user_id: int = 1) -> int:
    conn = get_connection(db_path)
    try:
        # Build keyword corpus from blocks, concepts, artifacts
        block_text = " ".join(b.content for b in entry.note_blocks)
        concept_names = " ".join(c.name for c in entry.concepts)
        artifact_names = " ".join(a.name for a in entry.referenced_artifacts)
        keyword_text = " ".join(filter(None, [entry.title, block_text, concept_names, artifact_names]))
        entry_keywords = extract_keywords(keyword_text)

        cur = conn.execute(
            """
            INSERT INTO entries (
                user_id, title, source_url, field, content_type, type_specific_fields,
                hook, summary, key_points,
                implementation_plan, tools_resources, rabbit_hole,
                referenced_artifacts,
                effort_estimation, missing_context,
                explore_further, next_step, keywords, note_blocks, is_favorite, is_implementing, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                entry.title,
                entry.source_url,
                entry.field,
                entry.content_type,
                json.dumps([f.model_dump() for f in entry.type_specific_fields]),
                entry.hook,
                '{}', # deprecated summary
                '', # deprecated key_points
                '[]', # deprecated implementation_plan
                '[]', # deprecated tools_resources
                '{}', # deprecated rabbit_hole
                json.dumps([a.model_dump() for a in entry.referenced_artifacts]),
                None, # deprecated effort_estimation
                '[]', # deprecated missing_context
                '[]', # deprecated explore_further
                entry.next_step,
                json.dumps(entry_keywords),
                json.dumps([b.model_dump() for b in entry.note_blocks]),
                1 if entry.is_favorite else 0,
                1 if entry.is_implementing else 0,
                entry.created_at,
            ),
        )
        entry_id = cur.lastrowid

        for tag in entry.tags:
            tag_id = _get_or_create_tag(conn, tag)
            conn.execute(
                "INSERT OR IGNORE INTO entry_tags (entry_id, tag_id) VALUES (?, ?)",
                (entry_id, tag_id),
            )

        for item in entry.action_items:
            conn.execute(
                "INSERT INTO action_items (entry_id, text, done, priority, time_estimate) VALUES (?, ?, ?, ?, ?)",
                (entry_id, item.text, int(item.done), item.priority, item.time_estimate),
            )



        # FTS index — include blocks, concepts, artifacts, action items
        blocks_text = " ".join(b.content for b in entry.note_blocks)
        tags_text = " ".join(entry.tags)
        artifacts_text = " ".join(a.name for a in entry.referenced_artifacts)
        concepts_text = " ".join(c.name for c in entry.concepts)
        action_items_text = " ".join(a.text for a in entry.action_items)
        conn.execute(
            """
            INSERT INTO entries_fts (rowid, title, summary_text, key_points, claims_text, tags_text, tools_text, action_items_text)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                entry_id,
                entry.title,
                blocks_text, # using summary_text for blocks
                concepts_text, # using key_points for concepts
                '', # deprecated claims
                tags_text,
                artifacts_text, # using tools_text for artifacts
                action_items_text,
            ),
        )

        conn.commit()
        return entry_id
    finally:
        conn.close()


def save_connections(db_path: str, entry_id: int, connections: List[Connection]) -> None:
    if not connections:
        return
    conn = get_connection(db_path)
    try:
        for c in connections:
            conn.execute(
                "INSERT OR REPLACE INTO connections (entry_id, related_entry_id, reason) VALUES (?, ?, ?)",
                (entry_id, c.entry_id, c.reason),
            )
        conn.commit()
    finally:
        conn.close()


def _row_to_entry(conn: sqlite3.Connection, row: sqlite3.Row) -> KnowledgeEntry:
    entry_id = row["id"]

    tags = [
        r["name"] for r in conn.execute(
            "SELECT t.name FROM tags t JOIN entry_tags et ON et.tag_id = t.id WHERE et.entry_id = ?",
            (entry_id,),
        )
    ]

    action_items = [
        {
            "id": r["id"],
            "entry_id": entry_id,
            "text": r["text"],
            "done": bool(r["done"]),
            "priority": r["priority"] if "priority" in r.keys() else "soon",
            "time_estimate": r["time_estimate"] if "time_estimate" in r.keys() else None,
        }
        for r in conn.execute(
            """SELECT id, text, done, priority, time_estimate FROM action_items
               WHERE entry_id = ?
               ORDER BY CASE priority WHEN 'now' THEN 0 WHEN 'soon' THEN 1 WHEN 'someday' THEN 2 ELSE 1 END, id ASC""",
            (entry_id,),
        )
    ]



    connections = [
        Connection(entry_id=r["related_entry_id"], title=r["title"], reason=r["reason"])
        for r in conn.execute(
            """
            SELECT c.related_entry_id, c.reason, e.title
            FROM connections c JOIN entries e ON e.id = c.related_entry_id
            WHERE c.entry_id = ?
            """,
            (entry_id,),
        )
    ]

    concepts = [
        Concept(id=r["id"], concept_type=r["concept_type"], name=r["name"],
                summary=r["summary"], source_entry_id=entry_id)
        for r in conn.execute(
            """
            SELECT c.id, c.concept_type, c.name, c.summary
            FROM concepts c JOIN entry_concepts ec ON ec.concept_id = c.id
            WHERE ec.entry_id = ? ORDER BY c.id
            """,
            (entry_id,),
        )
    ]

    # Parse new fields with fallback for older DB rows
    def _parse_json(raw, default):
        try:
            return json.loads(raw) if raw else default
        except Exception:
            return default

    note_blocks = [
        NoteBlock(**b)
        for b in _parse_json(row["note_blocks"] if "note_blocks" in row.keys() else None, [])
    ]

    hook = row["hook"] if "hook" in row.keys() else ""
    is_favorite = bool(row["is_favorite"]) if "is_favorite" in row.keys() else False
    is_implementing = bool(row["is_implementing"]) if "is_implementing" in row.keys() else False

    return KnowledgeEntry(
        title=row["title"],
        source_url=row["source_url"],
        field=row["field"],
        tags=tags,
        content_type=row["content_type"],
        type_specific_fields=[TypeSpecificField(**f) for f in _parse_json(row["type_specific_fields"], [])],
        hook=hook,
        action_items=action_items,
        referenced_artifacts=[
            ReferencedArtifact(**a)
            for a in _parse_json(row["referenced_artifacts"], [])
        ],
        next_step=row["next_step"],
        note_blocks=note_blocks,
        is_favorite=is_favorite,
        is_implementing=is_implementing,
        created_at=row["created_at"],
        connections=connections,
        concepts=concepts,
    )


def get_entry(db_path: str, entry_id: int) -> Optional[KnowledgeEntry]:
    conn = get_connection(db_path)
    try:
        row = conn.execute("SELECT * FROM entries WHERE id = ?", (entry_id,)).fetchone()
        if not row:
            return None
        entry = _row_to_entry(conn, row)
        entry.id = row["id"]
        return entry
    finally:
        conn.close()


def list_entries(db_path: str, limit: int = 50, user_id: int = None) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        if user_id:
            return conn.execute(
                "SELECT id, title, field, created_at FROM entries WHERE user_id = ? ORDER BY id DESC LIMIT ?",
                (user_id, limit),
            ).fetchall()
        return conn.execute(
            "SELECT id, title, field, created_at FROM entries ORDER BY id DESC LIMIT ?",
            (limit,),
        ).fetchall()
    finally:
        conn.close()


def search_entries(db_path: str, query: str, tag: Optional[str] = None,
                    field: Optional[str] = None, content_type: Optional[str] = None,
                    limit: int = 20, user_id: int = None) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        sql = """
            SELECT e.id, e.title, e.field, e.content_type, e.created_at
            FROM entries_fts f
            JOIN entries e ON e.id = f.rowid
        """
        params: list = []
        conditions = []

        if user_id:
            conditions.append("e.user_id = ?")
            params.append(user_id)

        if query:
            # Simple sanitization for FTS5: quote the query if it contains special chars
            # but preserve OR/AND if the user is using them (basic approach)
            clean_query = query.replace('"', '""')
            if any(c in clean_query for c in "-*+"):
                clean_query = f'"{clean_query}"'
            
            conditions.append("entries_fts MATCH ?")
            params.append(clean_query)

        if tag:
            sql += """
                JOIN entry_tags et ON et.entry_id = e.id
                JOIN tags t ON t.id = et.tag_id
            """
            conditions.append("t.name = ?")
            params.append(tag.strip().lower())

        if field:
            conditions.append("e.field = ?")
            params.append(field)

        if content_type:
            conditions.append("e.content_type = ?")
            params.append(content_type)

        if conditions:
            sql += " WHERE " + " AND ".join(conditions)

        sql += " ORDER BY e.id DESC LIMIT ?"
        params.append(limit)

        return conn.execute(sql, params).fetchall()
    finally:
        conn.close()


def list_action_items(db_path: str, done: Optional[bool] = None, user_id: int = None) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        base = """
            SELECT a.id, a.text, a.done, a.priority, a.time_estimate,
                   e.id as entry_id, e.title, e.field
            FROM action_items a JOIN entries e ON e.id = a.entry_id
            WHERE e.is_implementing = 1
        """
        params: list = []

        if user_id:
            base += " AND e.user_id = ?"
            params.append(user_id)

        if done is not None:
            base += " AND a.done = ?"
            params.append(int(done))
        order = """
            ORDER BY
                CASE a.priority WHEN 'now' THEN 0 WHEN 'soon' THEN 1 WHEN 'someday' THEN 2 ELSE 1 END,
                a.entry_id DESC, a.id
        """
        return conn.execute(base + order, params).fetchall()
    finally:
        conn.close()


def set_action_item_done(db_path: str, action_item_id: int, done: bool) -> bool:
    conn = get_connection(db_path)
    try:
        cur = conn.execute(
            "UPDATE action_items SET done = ? WHERE id = ?", (int(done), action_item_id)
        )
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Collections
# ---------------------------------------------------------------------------

def get_or_create_collection(db_path: str, name: str, user_id: int = 1) -> int:
    conn = get_connection(db_path)
    try:
        cur = conn.execute("SELECT id FROM collections WHERE name = ? AND user_id = ?", (name, user_id))
        row = cur.fetchone()
        if row:
            return row["id"]
        cur = conn.execute("INSERT INTO collections (name, user_id) VALUES (?, ?)", (name, user_id))
        conn.commit()
        return cur.lastrowid
    finally:
        conn.close()


def add_to_collection(db_path: str, collection_name: str, entry_id: int, user_id: int = 1) -> None:
    collection_id = get_or_create_collection(db_path, collection_name, user_id)
    conn = get_connection(db_path)
    try:
        conn.execute(
            "INSERT OR IGNORE INTO collection_entries (collection_id, entry_id) VALUES (?, ?)",
            (collection_id, entry_id),
        )
        conn.commit()
    finally:
        conn.close()


def list_collections(db_path: str, user_id: int = None) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        if user_id:
            return conn.execute(
                """
                SELECT c.id, c.name, COUNT(ce.entry_id) as entry_count
                FROM collections c
                LEFT JOIN collection_entries ce ON ce.collection_id = c.id
                WHERE c.user_id = ?
                GROUP BY c.id ORDER BY c.name
                """,
                (user_id,),
            ).fetchall()
        return conn.execute(
            """
            SELECT c.id, c.name, COUNT(ce.entry_id) as entry_count
            FROM collections c
            LEFT JOIN collection_entries ce ON ce.collection_id = c.id
            GROUP BY c.id ORDER BY c.name
            """
        ).fetchall()
    finally:
        conn.close()


def get_collection_entries(db_path: str, collection_name: str) -> List[KnowledgeEntry]:
    conn = get_connection(db_path)
    try:
        rows = conn.execute(
            """
            SELECT e.* FROM entries e
            JOIN collection_entries ce ON ce.entry_id = e.id
            JOIN collections c ON c.id = ce.collection_id
            WHERE c.name = ?
            ORDER BY e.id
            """,
            (collection_name,),
        ).fetchall()
        entries = []
        for row in rows:
            entry = _row_to_entry(conn, row)
            entry.id = row["id"]
            entries.append(entry)
        return entries
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Connections scoring (see connections.py)
# ---------------------------------------------------------------------------

def get_all_entries_summary(db_path: str, exclude_id: Optional[int] = None) -> List[dict]:
    conn = get_connection(db_path)
    try:
        rows = conn.execute(
            "SELECT id, title, field, content_type, referenced_artifacts, keywords FROM entries"
        ).fetchall()
        result = []
        for row in rows:
            if exclude_id is not None and row["id"] == exclude_id:
                continue
            artifacts = [a["name"] for a in json.loads(row["referenced_artifacts"] or "[]")]
            tags = [
                r["name"] for r in conn.execute(
                    "SELECT t.name FROM tags t JOIN entry_tags et ON et.tag_id = t.id WHERE et.entry_id = ?",
                    (row["id"],),
                )
            ]
            concepts = [
                r["name"] for r in conn.execute(
                    "SELECT c.name FROM concepts c JOIN entry_concepts ec ON ec.concept_id = c.id WHERE ec.entry_id = ?",
                    (row["id"],),
                )
            ]
            result.append({
                "id": row["id"],
                "title": row["title"],
                "field": row["field"],
                "content_type": row["content_type"],
                "tags": tags,
                "artifacts": artifacts,
                "concepts": concepts,
                "keywords": json.loads(row["keywords"] or "[]"),
            })
        return result
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Knowledge Cards (Concepts)
# ---------------------------------------------------------------------------

def save_concepts(db_path: str, entry_id: int, concepts: List[Concept]) -> List[int]:
    if not concepts:
        return []

    conn = get_connection(db_path)
    concept_ids = []
    try:
        for concept in concepts:
            # Basic normalization: title case and strip punctuation
            name = concept.name.strip().strip(".").title()
            # Special case for known acronyms if needed, but Title case is a good default
            
            existing = conn.execute(
                "SELECT id FROM concepts WHERE name = ? COLLATE NOCASE",
                (name,),
            ).fetchone()

            if existing:
                concept_id = existing["id"]
                # Optional: Update concept_type if the new one is more specific? 
                # For now, we just stick with the first one created.
            else:
                cur = conn.execute(
                    "INSERT INTO concepts (concept_type, name, summary, created_at) VALUES (?, ?, ?, ?)",
                    (concept.concept_type, name, concept.summary, datetime.now().isoformat()),
                )
                concept_id = cur.lastrowid

            conn.execute(
                "INSERT OR IGNORE INTO entry_concepts (entry_id, concept_id) VALUES (?, ?)",
                (entry_id, concept_id),
            )
            concept_ids.append(concept_id)

        conn.commit()
        return concept_ids
    finally:
        conn.close()


def get_concepts_for_entry(db_path: str, entry_id: int) -> List[Concept]:
    conn = get_connection(db_path)
    try:
        rows = conn.execute(
            """
            SELECT c.id, c.concept_type, c.name, c.summary
            FROM concepts c JOIN entry_concepts ec ON ec.concept_id = c.id
            WHERE ec.entry_id = ? ORDER BY c.id
            """,
            (entry_id,),
        ).fetchall()
        return [
            Concept(id=r["id"], concept_type=r["concept_type"], name=r["name"],
                    summary=r["summary"], source_entry_id=entry_id)
            for r in rows
        ]
    finally:
        conn.close()


def list_concepts(db_path: str, concept_type: Optional[str] = None,
                   query: Optional[str] = None, limit: int = 50) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        sql = "SELECT id, concept_type, name, summary FROM concepts"
        conditions, params = [], []

        if concept_type:
            conditions.append("concept_type = ?")
            params.append(concept_type)
        if query:
            conditions.append("name LIKE ?")
            params.append(f"%{query}%")

        if conditions:
            sql += " WHERE " + " AND ".join(conditions)
        sql += " ORDER BY name LIMIT ?"
        params.append(limit)

        return conn.execute(sql, params).fetchall()
    finally:
        conn.close()


def get_entries_for_concept(db_path: str, concept_id: int) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        return conn.execute(
            """
            SELECT e.id, e.title, e.field, e.created_at
            FROM entries e JOIN entry_concepts ec ON ec.entry_id = e.id
            WHERE ec.concept_id = ? ORDER BY e.id DESC
            """,
            (concept_id,),
        ).fetchall()
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Deep Research Prompt — on-demand generation endpoint helper
# ---------------------------------------------------------------------------

def get_deep_research_prompt(db_path: str, entry_id: int) -> Optional[str]:
    """Generates a deep research prompt dynamically from the entry."""
    conn = get_connection(db_path)
    try:
        row = conn.execute("SELECT title FROM entries WHERE id = ?", (entry_id,)).fetchone()
        if not row:
            return None
        
        title = row["title"]
        prompt = f"You are a research assistant. I just learned about '{title}'.\n\nPlease provide a comprehensive deep dive covering advanced concepts and adjacent topics related to this."
        return prompt
    finally:
        conn.close()


def set_entry_favorite(db_path: str, entry_id: int, is_favorite: bool) -> bool:
    """Toggles the favorite flag on an entry."""
    conn = get_connection(db_path)
    try:
        cur = conn.execute(
            "UPDATE entries SET is_favorite = ? WHERE id = ?",
            (1 if is_favorite else 0, entry_id)
        )
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()


def set_entry_implementing(db_path: str, entry_id: int, is_implementing: bool) -> bool:
    """Toggles the implementing flag on an entry."""
    conn = get_connection(db_path)
    try:
        cur = conn.execute(
            "UPDATE entries SET is_implementing = ? WHERE id = ?",
            (1 if is_implementing else 0, entry_id)
        )
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()
