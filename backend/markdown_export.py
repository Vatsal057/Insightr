"""
Markdown export — Obsidian-flavoured, all 12 insight features.
Optional secondary sync target; not the primary storage format.
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
    lines = []

    # Frontmatter
    lines += [
        "---",
        f"tags: [{', '.join(entry.tags)}]",
        f"field: {entry.field}",
        f"content_type: {entry.content_type}",
        "---", "",
        f"# {entry.title}", "",
        f"Source: {entry.source_url}", "",
    ]

    # ── Adaptive note body (AI-decided blocks) ──────────────────────────────
    if entry.note_blocks:
        for block in entry.note_blocks:
            lines += _render_block(block)
        lines.append("")

    # Knowledge Cards
    if entry.concepts:
        lines.append("## Knowledge Cards")
        for c in entry.concepts:
            lines.append(f"- **[{c.concept_type}] {c.name}** — {c.summary}")
        lines.append("")

    # Vault Connections
    if entry.connections:
        lines.append("## Related")
        for c in entry.connections:
            lines.append(f"- [[{slugify(c.title)}|{c.title}]] — {c.reason}")
        lines.append("")

    lines += [
        f"**Hub note to link:** [[{entry.field}]]", "",
        f"*Created: {entry.created_at}*",
    ]

    return "\n".join(lines)


def _render_block(block) -> list[str]:
    """Renders a single NoteBlock to markdown lines for export."""
    lines = []
    bt = block.block_type
    content = block.content.strip()

    if block.title:
        lines.append(f"## {block.title}")

    if bt == "key_insight":
        lines += [f"> {content}", ""]

    elif bt == "text":
        lines += [content, ""]

    elif bt == "bullets":
        for item in content.splitlines():
            item = item.strip()
            if item:
                lines.append(f"- {item}")
        lines.append("")

    elif bt == "steps":
        for i, item in enumerate(content.splitlines(), 1):
            item = item.strip()
            if item:
                # Defensively strip existing "1. " or "1) " prefixes if the LLM included them
                item = re.sub(r"^\d+[\.\)]\s*", "", item)
                lines.append(f"{i}. {item}")
        lines.append("")

    elif bt == "checklist":
        for item in content.splitlines():
            item = item.strip()
            if item:
                lines.append(f"- [ ] {item}")
        lines.append("")

    elif bt == "stat_row":
        # Render as a simple table: value bold, label below
        rows = []
        for item in content.splitlines():
            item = item.strip()
            if "|" in item:
                value, _, label = item.partition("|")
                rows.append((value.strip(), label.strip()))
        if rows:
            lines.append("| " + " | ".join(v for v, _ in rows) + " |")
            lines.append("| " + " | ".join("---" for _ in rows) + " |")
            lines.append("| " + " | ".join(l for _, l in rows) + " |")
        lines.append("")

    elif bt == "comparison":
        row_lines = [l.strip() for l in content.splitlines() if l.strip()]
        if row_lines:
            header = row_lines[0]
            left_h, _, right_h = header.partition("|")
            lines += [
                f"| {left_h.strip()} | {right_h.strip()} |",
                "| --- | --- |",
            ]
            for row in row_lines[1:]:
                left, _, right = row.partition("|")
                lines.append(f"| {left.strip()} | {right.strip()} |")
        lines.append("")

    elif bt == "label_values":
        for item in content.splitlines():
            item = item.strip()
            if ":" in item:
                label, _, value = item.partition(":")
                lines.append(f"**{label.strip()}** — {value.strip()}")
            elif item:
                lines.append(item)
        lines.append("")

    elif bt == "timeline":
        for item in content.splitlines():
            item = item.strip()
            if not item:
                continue
            if ":" in item:
                label, _, desc = item.partition(":")
                lines.append(f"**{label.strip()}** — {desc.strip()}")
            else:
                lines.append(item)
        lines.append("")

    elif bt == "quote":
        lines += [f'> "{content}"', ""]

    elif bt == "code_snippet":
        lines.append("```")
        lines += content.splitlines()
        lines += ["```", ""]

    else:
        lines += [content, ""]

    return lines




def export_entry(entry: KnowledgeEntry, output_dir: str) -> str:
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)
    markdown = entry_to_markdown(entry)
    filename = slugify(entry.title) + ".md"
    filepath = out / filename
    if filepath.exists():
        timestamp = datetime.now().strftime("%H%M%S")
        filepath = out / (slugify(entry.title) + f"-{timestamp}.md")
    filepath.write_text(markdown, encoding="utf-8")
    return str(filepath)


def export_collection(entries: list[KnowledgeEntry], collection_name: str, output_dir: str) -> str:
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)
    parts = [f"# Collection: {collection_name}", ""]
    for entry in entries:
        parts.append(entry_to_markdown(entry))
        parts.append("\n---\n")
    filepath = out / f"{slugify(collection_name)}.md"
    filepath.write_text("\n".join(parts), encoding="utf-8")
    return str(filepath)
