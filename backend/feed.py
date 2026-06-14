"""
Insight card feed — the primary view of a KnowledgeEntry.

entry_to_card() is the complete serialisation of all 12 insight features,
designed to be consumed directly by the mobile/web frontend without any
additional transformation. Every field name here IS the frontend API contract.
"""

from __future__ import annotations

from schema import KnowledgeEntry


def entry_to_card(entry: KnowledgeEntry) -> dict:
    """
    Full insight card structured into three zones for ADHD-friendly rendering.

    Zone 1 — "The Grab" (always visible, renders immediately):
      hook, next_step, top action item, effort pill.
      The user should be able to act on zone 1 without reading anything else.

    Zone 2 — "The Substance" (expanded on tap):
      note_blocks (the actual content), full action checklist, tools.

    Zone 3 — "The Deep End" (collapsed by default, opt-in):
      claims, missing_context, rabbit_hole, knowledge_cards, connections.

    The frontend should render zones in order and collapse zone 3 behind a
    "Go deeper" toggle. Zone 1 is never hidden.
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
        "created_at": entry.created_at,

        # ── Zone 1: The Grab ─────────────────────────────────────────────
        # Show these immediately, above the fold, without any tap.
        "zone_grab": {
            # The one-line reason to care right now
            "hook": getattr(entry, "hook", entry.summary.headline),
            # The single thing to do right now — most prominent CTA
            "next_step": entry.next_step,
            # The single highest-priority action item for a quick "do this now" chip
            "top_action": top_action,
            # Effort pill for instant calibration: is this a 5-min thing or a 2-week commitment?
            "effort_pill": _effort_pill(entry),
        },

        # ── Zone 2: The Substance ─────────────────────────────────────────
        # What the creator actually said/showed, structured for scanning.
        "zone_substance": {
            "core_takeaway": {
                "headline": entry.summary.headline,
                "body": entry.summary.body,
            },
            # AI-decided adaptive blocks — the actual content of the reel
            "note_blocks": [b.model_dump() for b in entry.note_blocks],
            # Full action checklist (all items, sorted by priority)
            "action_items": sorted(
                action_items_dumped,
                key=lambda a: {"now": 0, "soon": 1, "someday": 2}.get(a.get("priority", "soon"), 1)
            ),
            # Scannable key points (the creator's breakdown)
            "key_points": entry.key_points,
            # Tools mentioned — often what the user actually wants to look up
            "tools_resources": [t.model_dump() for t in entry.tools_resources],
            # Implementation plan — only present when content is a how-to
            "implementation_plan": [s.model_dump() for s in entry.implementation_plan],
        },

        # ── Zone 3: The Deep End ──────────────────────────────────────────
        # Collapsed by default. For users who want more, not everyone.
        "zone_deep": {
            # What the creator didn't tell you — critical thinking layer
            "missing_context": [m.model_dump() for m in entry.missing_context],
            # Fact-check layer
            "claims": [c.model_dump() for c in entry.claims],
            # Rabbit hole — for going further
            "rabbit_hole": {
                "follow_up_questions": entry.rabbit_hole.follow_up_questions,
                "knowledge_gaps": entry.rabbit_hole.knowledge_gaps,
                "adjacent_topics": entry.rabbit_hole.adjacent_topics,
                "advanced_concepts": entry.rabbit_hole.advanced_concepts,
                # Fetched separately via /api/entries/{id}/deep-research-prompt
            },
            # Knowledge cards vault
            "knowledge_cards": [c.model_dump() for c in entry.concepts],
            # Named things referenced — books, courses, papers
            "referenced_artifacts": [a.model_dump() for a in entry.referenced_artifacts],
            # Topic map — for navigation / linking
            "topic_map": entry.topic_map.model_dump(),
            # Effort estimation
            "effort_estimation": entry.effort_estimation.model_dump() if entry.effort_estimation else None,
            # Related entries in the vault
            "connections": [c.model_dump() for c in entry.connections],
        },
    }


def _effort_pill(entry: KnowledgeEntry) -> dict:
    """
    Returns a compact effort summary for the zone 1 pill chip.
    e.g. {"label": "10 min · Easy", "difficulty": 1, "time": "10 min"}
    """
    if not entry.effort_estimation:
        return None
    e = entry.effort_estimation
    difficulty_labels = {1: "Easy", 2: "Light", 3: "Moderate", 4: "Challenging", 5: "Hard"}
    label = difficulty_labels.get(e.difficulty, "")
    # Prefer implement time if it's short (< 1 hour), otherwise learn time
    time_str = e.time_to_implement or e.time_to_learn or ""
    return {
        "label": f"{time_str} · {label}" if time_str else label,
        "difficulty": e.difficulty,
        "effort": e.effort,
        "time_to_implement": e.time_to_implement,
        "time_to_learn": e.time_to_learn,
    }


def entry_to_summary_card(entry: KnowledgeEntry) -> dict:
    """
    Minimal card for feed/list views.

    The feed card shows: title + hook (the attention grab) + effort pill +
    count chips ("3 actions · 2 tools") + the top_action so the user can see
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
        # hook is the attention grab shown on the feed card — not the headline
        "hook": getattr(entry, "hook", entry.summary.headline),
        "field": entry.field,
        "content_type": entry.content_type,
        "tags": entry.tags,
        "created_at": entry.created_at,
        # The single most urgent action — shown as a chip on the feed card
        # so the user sees what "doing this" looks like before opening it
        "top_action": top_action,
        # Chips: "3 actions · 5 steps · 2 tools"
        "action_item_count": len(entry.action_items),
        "now_action_count": sum(1 for a in entry.action_items if a.priority == "now"),
        "implementation_step_count": len(entry.implementation_plan),
        "tool_count": len(entry.tools_resources),
        # Effort pill: "2 weeks · Moderate"
        "effort_pill": _effort_pill(entry),
    }


def concept_to_card(concept) -> dict:
    """Renders a Concept (Knowledge Card) for the vault index view."""
    return {
        "id": concept.id,
        "concept_type": concept.concept_type,
        "name": concept.name,
        "summary": concept.summary,
    }
