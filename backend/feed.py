"""
Insight card feed — the primary view of a KnowledgeEntry.

This is the actual product: not a Markdown note, but a compact JSON "card"
designed for an app feed. Each card surfaces the headline, the punchy
key-point breakdown, an immediate next step, and pointers into the rest of
the vault (concepts, related entries, action items). The goal is to get the
useful 20% of a video in front of the user fast, and to make the vault feel
like a connected web of ideas rather than a pile of notes.

Markdown export (markdown_export.py) remains available as an optional
secondary sync target (e.g. Obsidian), generated from the same data.
"""

from __future__ import annotations

from schema import KnowledgeEntry


def entry_to_card(entry: KnowledgeEntry) -> dict:
    """
    Renders a KnowledgeEntry as an insight card for the entry view.

    Split into two parts:
      - top-level fields: what you see immediately (headline, summary,
        key points, action items, next step) — the stuff the card is for.
      - "extras": secondary context (referenced tools/links, claims,
        related concepts, follow-up topics, connections to other entries).
        The UI should render this as a collapsed/expandable section, not
        inline with the main card. This keeps reels from feeling cluttered
        with links and tool mentions.
    """
    return {
        "id": getattr(entry, "id", None),
        "title": entry.title,
        "source_url": entry.source_url,
        "field": entry.field,
        "tags": entry.tags,
        "content_type": entry.content_type,
        "created_at": entry.created_at,

        "headline": entry.summary.headline,
        "summary": entry.summary.body,
        "key_points": entry.key_points,
        "type_specific_fields": [f.model_dump() for f in entry.type_specific_fields],
        "action_items": [a.model_dump() for a in entry.action_items],
        "next_step": entry.next_step,

        "extras": {
            "referenced_artifacts": [a.model_dump() for a in entry.referenced_artifacts],
            "claims": [c.model_dump() for c in entry.claims],
            "explore_further": entry.explore_further,
            "topic_map": entry.topic_map.model_dump(),
            "concepts": [c.model_dump() for c in entry.concepts],
            "connections": [c.model_dump() for c in entry.connections],
        },
    }


def entry_to_summary_card(entry: KnowledgeEntry) -> dict:
    """A minimal card for feed/list views — just enough to decide whether to open it."""
    return {
        "id": getattr(entry, "id", None),
        "title": entry.title,
        "headline": entry.summary.headline,
        "field": entry.field,
        "content_type": entry.content_type,
        "tags": entry.tags,
        "created_at": entry.created_at,
    }


def concept_to_card(concept) -> dict:
    """Renders a Concept for the concept index view."""
    return {
        "id": concept.id,
        "concept_type": concept.concept_type,
        "name": concept.name,
        "summary": concept.summary,
    }
