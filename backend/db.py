"""
SQLite storage layer for Insightr.

Replaces vault.py's "write a markdown file and regex-edit an index" approach.
Everything lives in insightr.db; Markdown is generated on demand from this
data (see markdown_export.py).
"""

from __future__ import annotations

import json
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from schema import KnowledgeEntry, Connection, Concept, TypeSpecificField
from keywords import extract_keywords


SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS entries (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    title           TEXT NOT NULL,
    source_url      TEXT NOT NULL,
    field           TEXT NOT NULL,
    content_type    TEXT NOT NULL DEFAULT 'general',
    type_specific_fields TEXT NOT NULL DEFAULT '[]', -- JSON array of {label, value}
    summary         TEXT NOT NULL,   -- JSON: {headline, body}
    key_points      TEXT NOT NULL,
    explore_further TEXT NOT NULL,   -- JSON array of strings
    topic_map       TEXT NOT NULL,   -- JSON: {main_topic, subtopics}
    referenced_artifacts TEXT NOT NULL, -- JSON array
    next_step       TEXT NOT NULL,
    keywords        TEXT NOT NULL DEFAULT '[]', -- JSON array, precomputed for connections
    created_at      TEXT NOT NULL
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
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    text     TEXT NOT NULL,
    done     INTEGER NOT NULL DEFAULT 0
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
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS collection_entries (
    collection_id INTEGER NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    entry_id      INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
    PRIMARY KEY (collection_id, entry_id)
);

CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
    title, summary_text, key_points, claims_text, tags_text,
    content='', tokenize='porter'
);
"""


def get_connection(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.row_factory = sqlite3.Row
    return conn


def _migrate(conn: sqlite3.Connection) -> None:
    """
    Lightweight forward migration: adds columns introduced after the initial
    release if they're missing on an existing database. No migration
    framework — just ALTER TABLE ... ADD COLUMN, ignored if already present.
    """
    existing = {row["name"] for row in conn.execute("PRAGMA table_info(entries)")}
    if "content_type" not in existing:
        conn.execute("ALTER TABLE entries ADD COLUMN content_type TEXT NOT NULL DEFAULT 'general'")
    if "type_specific_fields" not in existing:
        conn.execute("ALTER TABLE entries ADD COLUMN type_specific_fields TEXT NOT NULL DEFAULT '[]'")
    if "keywords" not in existing:
        conn.execute("ALTER TABLE entries ADD COLUMN keywords TEXT NOT NULL DEFAULT '[]'")
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


def save_entry(db_path: str, entry: KnowledgeEntry) -> int:
    """
    Inserts a KnowledgeEntry (and its tags/action items/claims) into the DB.
    Returns the new entry's id.
    """
    conn = get_connection(db_path)
    try:
        keyword_text = " ".join(
            [entry.summary.headline, entry.summary.body]
            + [c.claim for c in entry.claims]
        )
        entry_keywords = extract_keywords(keyword_text)

        cur = conn.execute(
            """
            INSERT INTO entries
                (title, source_url, field, content_type, type_specific_fields,
                 summary, key_points,
                 explore_further, topic_map, referenced_artifacts, next_step, keywords, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                entry.title,
                entry.source_url,
                entry.field,
                entry.content_type,
                json.dumps([f.model_dump() for f in entry.type_specific_fields]),
                entry.summary.model_dump_json(),
                entry.key_points,
                json.dumps(entry.explore_further),
                entry.topic_map.model_dump_json(),
                json.dumps([a.model_dump() for a in entry.referenced_artifacts]),
                entry.next_step,
                json.dumps(entry_keywords),
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
                "INSERT INTO action_items (entry_id, text, done) VALUES (?, ?, ?)",
                (entry_id, item.text, int(item.done)),
            )

        for claim in entry.claims:
            conn.execute(
                "INSERT INTO claims (entry_id, claim, verifiability, note) VALUES (?, ?, ?, ?)",
                (entry_id, claim.claim, claim.verifiability, claim.note),
            )

        # Populate full-text search index
        claims_text = " ".join(c.claim for c in entry.claims)
        tags_text = " ".join(entry.tags)
        conn.execute(
            """
            INSERT INTO entries_fts (rowid, title, summary_text, key_points, claims_text, tags_text)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                entry_id,
                entry.title,
                f"{entry.summary.headline} {entry.summary.body}",
                entry.key_points,
                claims_text,
                tags_text,
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
            """
            SELECT t.name FROM tags t
            JOIN entry_tags et ON et.tag_id = t.id
            WHERE et.entry_id = ?
            """,
            (entry_id,),
        )
    ]

    action_items = [
        {"text": r["text"], "done": bool(r["done"])}
        for r in conn.execute(
            "SELECT text, done FROM action_items WHERE entry_id = ? ORDER BY id", (entry_id,)
        )
    ]

    claims = [
        {"claim": r["claim"], "verifiability": r["verifiability"], "note": r["note"]}
        for r in conn.execute(
            "SELECT claim, verifiability, note FROM claims WHERE entry_id = ? ORDER BY id", (entry_id,)
        )
    ]

    connections = [
        Connection(entry_id=r["related_entry_id"], title=r["title"], reason=r["reason"])
        for r in conn.execute(
            """
            SELECT c.related_entry_id, c.reason, e.title
            FROM connections c
            JOIN entries e ON e.id = c.related_entry_id
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
            FROM concepts c
            JOIN entry_concepts ec ON ec.concept_id = c.id
            WHERE ec.entry_id = ?
            ORDER BY c.id
            """,
            (entry_id,),
        )
    ]

    return KnowledgeEntry(
        title=row["title"],
        source_url=row["source_url"],
        field=row["field"],
        tags=tags,
        content_type=row["content_type"],
        type_specific_fields=[TypeSpecificField(**f) for f in json.loads(row["type_specific_fields"])],
        summary=json.loads(row["summary"]),
        key_points=row["key_points"],
        action_items=action_items,
        claims=claims,
        explore_further=json.loads(row["explore_further"]),
        topic_map=json.loads(row["topic_map"]),
        referenced_artifacts=json.loads(row["referenced_artifacts"]),
        next_step=row["next_step"],
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


def list_entries(db_path: str, limit: int = 50) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        return conn.execute(
            "SELECT id, title, field, created_at FROM entries ORDER BY id DESC LIMIT ?",
            (limit,),
        ).fetchall()
    finally:
        conn.close()


def search_entries(db_path: str, query: str, tag: Optional[str] = None,
                    field: Optional[str] = None, content_type: Optional[str] = None,
                    limit: int = 20) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        sql = """
            SELECT e.id, e.title, e.field, e.content_type, e.created_at
            FROM entries_fts f
            JOIN entries e ON e.id = f.rowid
        """
        params: list = []
        conditions = []

        if query:
            conditions.append("entries_fts MATCH ?")
            params.append(query)

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


def list_action_items(db_path: str, done: Optional[bool] = None) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
        sql = """
            SELECT a.id, a.text, a.done, e.id as entry_id, e.title
            FROM action_items a
            JOIN entries e ON e.id = a.entry_id
        """
        params: list = []
        if done is not None:
            sql += " WHERE a.done = ?"
            params.append(int(done))
        sql += " ORDER BY a.entry_id DESC, a.id"
        return conn.execute(sql, params).fetchall()
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

def get_or_create_collection(db_path: str, name: str) -> int:
    conn = get_connection(db_path)
    try:
        cur = conn.execute("SELECT id FROM collections WHERE name = ?", (name,))
        row = cur.fetchone()
        if row:
            return row["id"]
        cur = conn.execute("INSERT INTO collections (name) VALUES (?)", (name,))
        conn.commit()
        return cur.lastrowid
    finally:
        conn.close()


def add_to_collection(db_path: str, collection_name: str, entry_id: int) -> None:
    collection_id = get_or_create_collection(db_path, collection_name)
    conn = get_connection(db_path)
    try:
        conn.execute(
            "INSERT OR IGNORE INTO collection_entries (collection_id, entry_id) VALUES (?, ?)",
            (collection_id, entry_id),
        )
        conn.commit()
    finally:
        conn.close()


def list_collections(db_path: str) -> List[sqlite3.Row]:
    conn = get_connection(db_path)
    try:
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
# For connection-finding (see connections.py)
# ---------------------------------------------------------------------------

def get_all_entries_summary(db_path: str, exclude_id: Optional[int] = None) -> List[dict]:
    """Lightweight data for similarity scoring against existing entries."""
    conn = get_connection(db_path)
    try:
        rows = conn.execute(
            "SELECT id, title, field, content_type, topic_map, referenced_artifacts, keywords FROM entries"
        ).fetchall()
        result = []
        for row in rows:
            if exclude_id is not None and row["id"] == exclude_id:
                continue
            topic_map = json.loads(row["topic_map"])
            artifacts = [a["name"] for a in json.loads(row["referenced_artifacts"])]
            tags = [
                r["name"] for r in conn.execute(
                    """
                    SELECT t.name FROM tags t
                    JOIN entry_tags et ON et.tag_id = t.id
                    WHERE et.entry_id = ?
                    """,
                    (row["id"],),
                )
            ]
            result.append({
                "id": row["id"],
                "title": row["title"],
                "field": row["field"],
                "content_type": row["content_type"],
                "topic_map": topic_map,
                "tags": tags,
                "artifacts": artifacts,
                "keywords": json.loads(row["keywords"]),
            })
        return result
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Knowledge Cards
# ---------------------------------------------------------------------------

def save_concepts(db_path: str, entry_id: int, concepts: List[Concept]) -> List[int]:
    """
    Inserts concepts, deduplicating by (concept_type, name) case-insensitively.
    If a concept already exists, it is reused and linked to this entry rather
    than duplicated. Returns the list of concept ids linked to this entry.
    """
    if not concepts:
        return []

    conn = get_connection(db_path)
    concept_ids = []
    try:
        for concept in concepts:
            existing = conn.execute(
                "SELECT id FROM concepts WHERE concept_type = ? AND name = ? COLLATE NOCASE",
                (concept.concept_type, concept.name),
            ).fetchone()

            if existing:
                concept_id = existing["id"]
            else:
                cur = conn.execute(
                    "INSERT INTO concepts (concept_type, name, summary, created_at) VALUES (?, ?, ?, ?)",
                    (concept.concept_type, concept.name, concept.summary, datetime.now().isoformat()),
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
            FROM concepts c
            JOIN entry_concepts ec ON ec.concept_id = c.id
            WHERE ec.entry_id = ?
            ORDER BY c.id
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
        conditions = []
        params: list = []

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
            FROM entries e
            JOIN entry_concepts ec ON ec.entry_id = e.id
            WHERE ec.concept_id = ?
            ORDER BY e.id DESC
            """,
            (concept_id,),
        ).fetchall()
    finally:
        conn.close()
