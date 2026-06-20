"""
Connections: finds related existing entries for a newly-saved entry.

Still deliberately local and simple — no embeddings, no extra LLM call, no
external services. Improves on plain tag overlap by combining several
weighted signals into one score:

    - shared tags
    - shared referenced artifacts (tools/books/etc by name)
    - same field/category
    - shared keywords extracted from the takeaway + claims text

This module is self-contained: scoring, weights, and keyword extraction all
live here, so the approach can be swapped out later (e.g. for an embedding-
based version) without touching db.py or main.py.
"""

from __future__ import annotations

from typing import List

from schema import KnowledgeEntry, Connection
from keywords import extract_keywords
import db


# Scoring weights for each signal. Tweak here if results feel off.
WEIGHT_TAG = 3
WEIGHT_ARTIFACT = 2
WEIGHT_FIELD = 1
WEIGHT_CONTENT_TYPE = 1
WEIGHT_KEYWORD = 1

KEYWORDS_PER_ENTRY = 8


def _normalize(items: List[str]) -> set:
    return {i.strip().lower() for i in items if i.strip()}


def _entry_keywords(entry: KnowledgeEntry, top_n: int = KEYWORDS_PER_ENTRY) -> set:
    """Extracts keywords from an entry's title, hook, next_step, and dynamic note blocks."""
    text_parts = [entry.title, entry.hook, entry.next_step]
    text_parts.extend(b.content for b in entry.note_blocks if b.content)
    return set(extract_keywords(" ".join(text_parts), top_n=top_n))


def find_connections(db_path: str, entry: KnowledgeEntry, entry_id: int,
                      max_connections: int = 3, min_score: int = 2) -> List[Connection]:
    new_tags = _normalize(entry.tags)
    new_artifacts = _normalize(a.name for a in entry.referenced_artifacts)
    new_keywords = _entry_keywords(entry)

    candidates = db.get_all_entries_summary(db_path, exclude_id=entry_id)

    scored = []
    for c in candidates:
        c_tags = _normalize(c["tags"])
        c_artifacts = _normalize(c.get("artifacts", []))
        c_keywords = set(c.get("keywords", []))

        shared_tags = new_tags & c_tags
        shared_artifacts = new_artifacts & c_artifacts
        shared_keywords = new_keywords & c_keywords

        score = (
            len(shared_tags) * WEIGHT_TAG
            + len(shared_artifacts) * WEIGHT_ARTIFACT
            + len(shared_keywords) * WEIGHT_KEYWORD
        )
        if c["field"].lower() == entry.field.lower():
            score += WEIGHT_FIELD
        if c["content_type"] == entry.content_type:
            score += WEIGHT_CONTENT_TYPE

        if score >= min_score:
            reasons = []
            if shared_tags:
                reasons.append(f"tags: {', '.join(sorted(shared_tags))}")
            if shared_artifacts:
                reasons.append(f"both mention: {', '.join(sorted(shared_artifacts))}")
            if shared_keywords:
                reasons.append(f"keywords: {', '.join(sorted(shared_keywords))}")
            if not reasons:
                reasons.append(f"same field: {c['field']}")
            scored.append((score, Connection(entry_id=c["id"], title=c["title"], reason="; ".join(reasons))))

    scored.sort(key=lambda x: x[0], reverse=True)
    return [conn for _, conn in scored[:max_connections]]
