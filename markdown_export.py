"""
Markdown export.

This is an OPTIONAL secondary view generated from the structured
KnowledgeEntry stored in the database — not the storage format, and not the
primary way entries are consumed (see feed.py for the in-app insight card
view). This module exists for people who want to sync their vault into an
Obsidian-style notes folder.
"""

from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path

from schema import KnowledgeEntry
from content_types import get_template


def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_]+", "-", text)
    text = re.sub(r"-+", "-", text)
    return text[:80]


def entry_to_markdown(entry: KnowledgeEntry) -> str:
    """Renders a KnowledgeEntry as an Obsidian-flavoured Markdown note."""
    lines = []

    # Frontmatter
    lines.append("---")
    lines.append(f"tags: [{', '.join(entry.tags)}]")
    lines.append(f"field: {entry.field}")
    lines.append(f"content_type: {entry.content_type}")
    lines.append("---")
    lines.append("")

    lines.append(f"# {entry.title}")
    lines.append("")
    lines.append(f"Source: {entry.source_url}")
    lines.append("")

    lines.append(f"> [!abstract] {entry.summary.headline}")
    lines.append(f"> {entry.summary.body}")
    lines.append("")

    if entry.type_specific_fields:
        template = get_template(entry.content_type)
        lines.append(f"## {template['display_name']}")
        for f in entry.type_specific_fields:
            lines.append(f"**{f.label}**")
            lines.append(f.value)
            lines.append("")
        lines.append("")

    lines.append("## Key Points")
    lines.append(entry.key_points)
    lines.append("")

    if entry.action_items:
        lines.append("## Action Items")
        for item in entry.action_items:
            checkbox = "x" if item.done else " "
            lines.append(f"- [{checkbox}] {item.text}")
        lines.append("")

    if entry.claims:
        lines.append("## Claims Made")
        for c in entry.claims:
            note = f" — {c.note}" if c.note else ""
            lines.append(f"- **[{c.verifiability}]** {c.claim}{note}")
        lines.append("")

    if entry.referenced_artifacts:
        lines.append("## Referenced Artifacts")
        for a in entry.referenced_artifacts:
            if a.url:
                lines.append(f"- **{a.name}** ({a.type}): {a.url}")
            else:
                lines.append(f"- **{a.name}** ({a.type})")
            if a.snippet:
                lines.append("```")
                lines.append(a.snippet)
                lines.append("```")
        lines.append("")

    lines.append("## Topic Map")
    lines.append(f"- **{entry.topic_map.main_topic}**")
    for sub in entry.topic_map.subtopics:
        lines.append(f"  - {sub}")
    lines.append("")

    if entry.explore_further:
        lines.append("## Explore Further")
        for q in entry.explore_further:
            lines.append(f"- {q}")
        lines.append("")

    lines.append("## Next Step")
    lines.append(entry.next_step)
    lines.append("")

    if entry.concepts:
        lines.append("## Concepts")
        for c in entry.concepts:
            lines.append(f"- **[{c.concept_type}] {c.name}** — {c.summary}")
        lines.append("")

    if entry.connections:
        lines.append("## Related")
        for c in entry.connections:
            lines.append(f"- [[{slugify(c.title)}|{c.title}]] — {c.reason}")
        lines.append("")

    lines.append(f"**Hub note to link:** [[{entry.field}]]")
    lines.append("")
    lines.append(f"*Created: {entry.created_at}*")

    return "\n".join(lines)


def export_entry(entry: KnowledgeEntry, output_dir: str) -> str:
    """Writes a single entry's Markdown to output_dir, returns the file path."""
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    markdown = entry_to_markdown(entry)
    filename = slugify(entry.title) + ".md"
    filepath = out / filename

    if filepath.exists():
        timestamp = datetime.now().strftime("%H%M%S")
        filename = slugify(entry.title) + f"-{timestamp}.md"
        filepath = out / filename

    filepath.write_text(markdown, encoding="utf-8")
    return str(filepath)


def export_collection(entries: list[KnowledgeEntry], collection_name: str, output_dir: str) -> str:
    """Writes a combined Markdown file for all entries in a collection."""
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)

    parts = [f"# Collection: {collection_name}", ""]
    for entry in entries:
        parts.append(entry_to_markdown(entry))
        parts.append("\n---\n")

    filepath = out / f"{slugify(collection_name)}.md"
    filepath.write_text("\n".join(parts), encoding="utf-8")
    return str(filepath)
