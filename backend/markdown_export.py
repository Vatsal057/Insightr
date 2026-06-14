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
    else:
        # Fallback for entries saved before note_blocks was introduced
        lines += _legacy_render(entry)

    # ── Fixed footer fields ─────────────────────────────────────────────────
    # Rabbit Hole — always at the bottom, not part of the adaptive body
    rh = entry.rabbit_hole
    if any([rh.follow_up_questions, rh.knowledge_gaps, rh.adjacent_topics, rh.advanced_concepts]):
        lines.append("## Go Deeper")
        if rh.follow_up_questions:
            lines.append("**Questions worth exploring**")
            for q in rh.follow_up_questions:
                lines.append(f"- {q}")
        if rh.knowledge_gaps:
            lines.append("\n**What was left out**")
            for g in rh.knowledge_gaps:
                lines.append(f"- {g}")
        if rh.adjacent_topics:
            lines.append("\n**Adjacent topics**")
            for t in rh.adjacent_topics:
                lines.append(f"- {t}")
        if rh.advanced_concepts:
            lines.append("\n**Advanced concepts**")
            for c in rh.advanced_concepts:
                lines.append(f"- {c}")
        if rh.deep_research_prompt:
            lines += ["", "**Deep Research Prompt**", "```", rh.deep_research_prompt, "```"]
        lines.append("")

    # What the Creator Didn't Mention
    if entry.missing_context:
        lines.append("## What the Creator Didn't Mention")
        for m in entry.missing_context:
            lines.append(f"- **[{m.category}]** {m.text}")
        lines.append("")

    # Knowledge Cards
    if entry.concepts:
        lines.append("## Knowledge Cards")
        for c in entry.concepts:
            lines.append(f"- **[{c.concept_type}] {c.name}** — {c.summary}")
        lines.append("")

    # Time & Effort
    if entry.effort_estimation:
        e = entry.effort_estimation
        lines += [
            "## Time & Effort",
            f"- **Learn:** {e.time_to_learn}",
            f"- **Implement:** {e.time_to_implement}",
            f"- **Difficulty:** {'★' * e.difficulty}{'☆' * (5 - e.difficulty)} ({e.difficulty}/5)",
            f"- **Effort:** {'★' * e.effort}{'☆' * (5 - e.effort)} ({e.effort}/5)",
        ]
        if e.difficulty_rationale:
            lines.append(f"- _{e.difficulty_rationale}_")
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


def _legacy_render(entry: KnowledgeEntry) -> list[str]:
    """
    Fallback renderer for entries that predate note_blocks.
    Reproduces the original hardcoded layout so old entries still export cleanly.
    """
    lines = []

    if entry.type_specific_fields:
        template = get_template(entry.content_type)
        lines.append(f"## {template['display_name']}")
        for f in entry.type_specific_fields:
            lines += [f"**{f.label}**", f.value, ""]
        lines.append("")

    lines += ["## Key Points", entry.key_points, ""]

    if entry.action_items:
        lines.append("## Action Items")
        for item in entry.action_items:
            cb = "x" if item.done else " "
            lines.append(f"- [{cb}] {item.text}")
        lines.append("")

    if entry.implementation_plan:
        lines.append("## Implementation Plan")
        for step in entry.implementation_plan:
            time = f" _{step.time_estimate}_" if step.time_estimate else ""
            lines += [f"### Step {step.step_number}: {step.title}{time}", step.description, ""]
        lines.append("")

    if entry.claims:
        lines.append("## Claims Made")
        for c in entry.claims:
            note = f" — {c.note}" if c.note else ""
            lines.append(f"- **[{c.verifiability}]** {c.claim}{note}")
        lines.append("")

    if entry.tools_resources:
        lines.append("## Tools & Resources")
        for t in entry.tools_resources:
            desc = f": {t.description}" if t.description else ""
            url = f" ({t.url})" if t.url else ""
            lines.append(f"- **{t.name}** [{t.type}]{desc}{url}")
        lines.append("")

    if entry.referenced_artifacts:
        lines.append("## Referenced Artifacts")
        for a in entry.referenced_artifacts:
            desc = f": {a.description}" if a.description else ""
            url = f" → {a.url}" if a.url else ""
            lines.append(f"- **{a.name}** ({a.type}){desc}{url}")
            if a.snippet:
                lines += ["```", a.snippet, "```"]
        lines.append("")

    lines += ["## Topic Map", f"- **{entry.topic_map.main_topic}**"]
    for sub in entry.topic_map.subtopics:
        lines.append(f"  - {sub}")
    lines.append("")

    lines += ["## Next Step", entry.next_step, ""]

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
