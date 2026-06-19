"""
Structured knowledge schema for Insightr.

Gemini returns JSON matching KnowledgeEntry, which is validated here before
being written to the database. The schema has been simplified to rely purely
on dynamic `note_blocks` for presentation, while retaining global indexing layers
like action items and concepts.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional, Literal, Any
from pydantic import BaseModel, Field, field_validator

from content_types import all_content_types


class ActionItem(BaseModel):
    id: Optional[int] = None
    entry_id: Optional[int] = None
    text: str
    done: bool = False
    priority: Literal["now", "soon", "someday"] = "soon"
    time_estimate: Optional[str] = None  # e.g. "5 min", "1 hour", "ongoing"


class Connection(BaseModel):
    """Computed after the fact, not produced by the LLM."""
    entry_id: int
    title: str
    reason: str


class NoteBlock(BaseModel):
    """
    One adaptive UI block in the note — decided by the AI, rendered natively
    by the Android app. The AI picks which components to show and in what order
    based on what the reel actually contains.
    """
    block_type: Literal[
        "key_insight", "text", "bullets", "steps", "checklist",
        "stat_row", "comparison", "label_values", "timeline",
        "quote", "code_snippet", "warning", "tip", "divider"
    ]
    title: str = ""
    content: str = ""


class TimelineEntry(BaseModel):
    """A single timestamped snippet, used for both transcript and OCR timelines."""
    timestamp: str  # "MM:SS"
    text: str


ConceptType = Literal["concept", "framework", "tool", "book", "person", "methodology", "website"]


class Concept(BaseModel):
    """
    Feature #7 — Knowledge Cards.
    A reusable, saveable knowledge card extracted from the content.
    Deduplicated and shared across entries.
    """
    concept_type: ConceptType
    name: str
    summary: str
    source_entry_id: Optional[int] = None
    id: Optional[int] = None


class ReferencedArtifact(BaseModel):
    """
    Feature #8 — Named artifacts referenced in the content.
    Expanded type list to include courses, movies, podcasts, research papers.
    """
    name: str
    type: Literal["book", "research_paper", "course", "movie", "podcast", "tool", "link", "template", "other"] = "other"
    description: Optional[str] = None
    url: Optional[str] = None
    snippet: Optional[str] = None


ContentType = str


class TypeSpecificField(BaseModel):
    label: str
    value: str


class KnowledgeEntry(BaseModel):
    """The full structured output for one processed video/post."""

    id: Optional[int] = None
    title: str = Field(description="3-5 word punchy title")
    source_url: str
    field: str = Field(description="One-word category, e.g. 'Productivity'")
    tags: List[str] = Field(default_factory=list)

    content_type: ContentType
    type_specific_fields: List[TypeSpecificField] = Field(default_factory=list)

    # Hook — single punchy sentence for the feed card.
    hook: str = Field(default="", description="One punchy sentence that makes someone want to act. Not a summary — a reason to care right now.")
    next_step: str = Field(description="1-2 sentence directive: what to actually do with this")

    # Global Indexing Layers (Extracted but not rendered strictly in note body)
    action_items: List[ActionItem] = Field(default_factory=list)
    concepts: List[Concept] = Field(default_factory=list)
    referenced_artifacts: List[ReferencedArtifact] = Field(default_factory=list)

    # Adaptive note layout — the AI decides blocks, titles, and order
    note_blocks: List[NoteBlock] = Field(
        default_factory=list,
        description="Ordered list of adaptive blocks that form the note body. The AI decides which blocks to include and how to title them based on this specific content."
    )

    created_at: str = Field(default_factory=lambda: datetime.now().isoformat())
    connections: List[Connection] = Field(default_factory=list)

    @field_validator("content_type")
    @classmethod
    def _validate_content_type(cls, value: str) -> str:
        return value if value in all_content_types() else "general"


# ---------------------------------------------------------------------------
# Gemini response schema (connections, id fields excluded — LLM never produces these)
# ---------------------------------------------------------------------------
GEMINI_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "hook": {"type": "string"},
        "source_url": {"type": "string"},
        "field": {"type": "string"},
        "tags": {"type": "array", "items": {"type": "string"}},
        "content_type": {"type": "string", "enum": all_content_types()},
        "type_specific_fields": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "label": {"type": "string"},
                    "value": {"type": "string"},
                },
                "required": ["label", "value"],
            },
        },
        "next_step": {"type": "string"},
        "action_items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "text": {"type": "string"},
                    "done": {"type": "boolean"},
                    "priority": {"type": "string", "enum": ["now", "soon", "someday"]},
                    "time_estimate": {"type": "string", "nullable": True},
                },
                "required": ["text", "priority"],
            },
        },
        "concepts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "concept_type": {
                        "type": "string",
                        "enum": ["concept", "framework", "tool", "book", "person", "methodology", "website"],
                    },
                    "name": {"type": "string"},
                    "summary": {"type": "string"},
                },
                "required": ["concept_type", "name", "summary"],
            },
        },
        "referenced_artifacts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "type": {
                        "type": "string",
                        "enum": ["book", "research_paper", "course", "movie", "podcast", "tool", "link", "template", "other"],
                    },
                    "description": {"type": "string", "nullable": True},
                    "url": {"type": "string", "nullable": True},
                    "snippet": {"type": "string", "nullable": True},
                },
                "required": ["name", "type"],
            },
        },
        "note_blocks": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "block_type": {
                        "type": "string",
                        "enum": [
                            "key_insight", "text", "bullets", "steps", "checklist",
                            "stat_row", "comparison", "label_values", "timeline",
                            "quote", "code_snippet", "warning", "tip", "divider"
                        ],
                    },
                    "title": {"type": "string"},
                    "content": {"type": "string"},
                },
                "required": ["block_type", "title", "content"],
            },
        },
    },
    "required": [
        "title", "hook", "field", "tags", "content_type", "type_specific_fields",
        "next_step", "action_items", "concepts", "referenced_artifacts", "note_blocks",
    ],
}
