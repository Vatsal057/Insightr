"""
Insight card feed — the primary view of a KnowledgeEntry.

entry_to_card() is the complete serialisation of all 12 insight features,
designed to be consumed directly by the mobile/web frontend without any
additional transformation. Every field name here IS the frontend API contract.
"""

from __future__ import annotations

import db
import re
from schema import KnowledgeEntry







def entry_to_card(entry: KnowledgeEntry, db_path: str = None) -> dict:
    """
    Full insight card structured into three zones for ADHD-friendly rendering.
    """
    action_items_dumped = [a.model_dump() for a in entry.action_items]

    # Top action: the single highest-priority item for zone 1 callout
    top_action = next(
        (a for a in action_items_dumped if a.get("priority") == "now"),
        action_items_dumped[0] if action_items_dumped else None,
    )

    return {
        # ── Meta ────────────────────────────────────────────────────────
        "id": getattr(entry, "id", None),
        "title": entry.title,
        "source_url": entry.source_url,
        "field": entry.field,
        "tags": entry.tags,
        "content_type": entry.content_type,
        "type_specific_fields": [f.model_dump() for f in entry.type_specific_fields],
        "is_favorite": entry.is_favorite,
        "is_implementing": entry.is_implementing,
        "created_at": entry.created_at,

        # ── Zone 1: The Grab ─────────────────────────────────────────────
        # Show these immediately, above the fold, without any tap.
        "zone_grab": {
            # The one-line reason to care right now
            "hook": entry.hook or entry.title,
            # The single thing to do right now — most prominent CTA
            "next_step": entry.next_step,
            # The single highest-priority action item for a quick "do this now" chip
            "top_action": top_action,
        },

        # ── Zone 2: The Substance ─────────────────────────────────────────
        # What the creator actually said/showed, structured for scanning.
        "zone_substance": {
            # AI-decided adaptive blocks — the actual content of the reel
            "note_blocks": [b.model_dump() for b in entry.note_blocks],
            # Full action checklist (all items, sorted by priority)
            "action_items": sorted(
                action_items_dumped,
                key=lambda a: {"now": 0, "soon": 1, "someday": 2}.get(a.get("priority", "soon"), 1)
            ),
        },

        # ── Zone 3: The Deep End ──────────────────────────────────────────
        # Collapsed by default. For users who want more, not everyone.
        "zone_deep": {
            # Knowledge cards vault
            "knowledge_cards": [c.model_dump() for c in entry.concepts],
            # Named things referenced — books, courses, papers
            "referenced_artifacts": [a.model_dump() for a in entry.referenced_artifacts],
            # Related entries in the vault
            "connections": [c.model_dump() for c in entry.connections],
        },
    }



def entry_to_summary_card(entry: KnowledgeEntry) -> dict:
    """
    Minimal card for feed/list views.

    The feed card shows: title + hook (the attention grab) +
    count chips + the top_action so the user can see
    what doing something about this looks like before they even open the note.
    """
    action_items = [a.model_dump() for a in entry.action_items]
    top_action = next(
        (a for a in action_items if a.get("priority") == "now"),
        action_items[0] if action_items else None,
    )
    return {
        "id": getattr(entry, "id", None),
        "title": entry.title,
        # hook is the attention grab shown on the feed card
        "hook": entry.hook or entry.title,
        "field": entry.field,
        "content_type": entry.content_type,
        "tags": entry.tags,
        "created_at": entry.created_at,
        # The single most urgent action — shown as a chip on the feed card
        # so the user sees what "doing this" looks like before opening it
        "top_action": top_action,
        "action_item_count": len(entry.action_items),
        "now_action_count": sum(1 for a in entry.action_items if a.priority == "now"),
    }


def concept_to_card(concept) -> dict:
    """Renders a Concept (Knowledge Card) for the vault index view."""
    return {
        "id": concept.id,
        "concept_type": concept.concept_type,
        "name": concept.name,
        "summary": concept.summary,
    }
