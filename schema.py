"""
Structured knowledge schema for the Vault.

Gemini returns JSON matching KnowledgeEntry, which is validated here before
being written to the database. Every entry is a self-contained "insight
card": a summary, key points, action items, claims worth checking, and
links to broader concepts — designed to be scanned quickly and resurfaced
later, not just archived as a note.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional, Literal
from pydantic import BaseModel, Field, field_validator

from content_types import all_content_types


class Summary(BaseModel):
    headline: str = Field(description="One sentence capturing why this matters.")
    body: str = Field(description="A short paragraph expanding on the headline.")


class ActionItem(BaseModel):
    text: str
    done: bool = False


class Claim(BaseModel):
    claim: str
    verifiability: Literal["fact", "opinion", "unverified"] = "unverified"
    note: Optional[str] = None


class TopicMap(BaseModel):
    main_topic: str
    subtopics: List[str] = Field(default_factory=list)


class ReferencedArtifact(BaseModel):
    name: str
    type: Literal["tool", "book", "link", "template", "other"] = "other"
    url: Optional[str] = None
    snippet: Optional[str] = None


class Connection(BaseModel):
    """Computed after the fact, not produced by the LLM."""
    entry_id: int
    title: str
    reason: str


class TimelineEntry(BaseModel):
    """A single timestamped snippet, used for both transcript and OCR timelines."""
    timestamp: str  # "MM:SS"
    text: str


ConceptType = Literal["concept", "framework", "tool", "book", "person", "methodology", "website"]


class Concept(BaseModel):
    """
    A reusable knowledge object extracted from an entry — a named framework,
    tool, book, person, or idea. Concepts are deduplicated and shared across
    entries so the vault accumulates a growing index of recurring ideas,
    rather than each entry being an isolated note.
    """
    concept_type: ConceptType
    name: str
    summary: str
    source_entry_id: Optional[int] = None
    id: Optional[int] = None


ContentType = str  # validated dynamically against content_types.all_content_types()


class TypeSpecificField(BaseModel):
    """One labeled piece of content-type-specific info, e.g. {"label": "Pros", "value": "..."}."""
    label: str
    value: str


class KnowledgeEntry(BaseModel):
    """The full structured output for one processed video/post."""

    id: Optional[int] = None
    title: str = Field(description="3-5 word punchy title")
    source_url: str
    field: str = Field(description="One-word category, e.g. 'Productivity'")
    tags: List[str] = Field(default_factory=list)

    content_type: ContentType = Field(
        description="The kind of content this is, used to pick the note structure"
    )
    type_specific_fields: List[TypeSpecificField] = Field(
        default_factory=list,
        description="Structured fields specific to this content_type (e.g. Pros/Cons for a review)",
    )

    summary: Summary
    key_points: str = Field(description="Short, scannable breakdown — punchy lines, one idea per line")

    action_items: List[ActionItem] = Field(default_factory=list)
    claims: List[Claim] = Field(default_factory=list)
    explore_further: List[str] = Field(default_factory=list, description="Follow-up questions/topics")
    topic_map: TopicMap
    referenced_artifacts: List[ReferencedArtifact] = Field(default_factory=list)

    next_step: str = Field(description="1-2 sentence directive: what to actually do with this")

    concepts: List[Concept] = Field(
        default_factory=list,
        description="Reusable concepts/frameworks/tools/books/people/methodologies/websites worth remembering",
    )

    created_at: str = Field(default_factory=lambda: datetime.now().isoformat())

    # Populated after storage, not by the LLM
    connections: List[Connection] = Field(default_factory=list)

    @field_validator("content_type")
    @classmethod
    def _validate_content_type(cls, value: str) -> str:
        """Falls back to 'general' if the model returns an unrecognized type,
        so a new/unexpected label from Gemini never breaks storage."""
        return value if value in all_content_types() else "general"


# JSON schema dict used for Gemini's response_schema (connections excluded —
# the model never produces these)
GEMINI_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "source_url": {"type": "string"},
        "field": {"type": "string"},
        "tags": {"type": "array", "items": {"type": "string"}},
        "content_type": {
            "type": "string",
            "enum": all_content_types(),
        },
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
        "summary": {
            "type": "object",
            "properties": {
                "headline": {"type": "string"},
                "body": {"type": "string"},
            },
            "required": ["headline", "body"],
        },
        "key_points": {"type": "string"},
        "action_items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "text": {"type": "string"},
                    "done": {"type": "boolean"},
                },
                "required": ["text"],
            },
        },
        "claims": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "claim": {"type": "string"},
                    "verifiability": {
                        "type": "string",
                        "enum": ["fact", "opinion", "unverified"],
                    },
                    "note": {"type": "string", "nullable": True},
                },
                "required": ["claim", "verifiability"],
            },
        },
        "explore_further": {"type": "array", "items": {"type": "string"}},
        "topic_map": {
            "type": "object",
            "properties": {
                "main_topic": {"type": "string"},
                "subtopics": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["main_topic", "subtopics"],
        },
        "referenced_artifacts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "type": {
                        "type": "string",
                        "enum": ["tool", "book", "link", "template", "other"],
                    },
                    "url": {"type": "string", "nullable": True},
                    "snippet": {"type": "string", "nullable": True},
                },
                "required": ["name", "type"],
            },
        },
        "next_step": {"type": "string"},
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
    },
    "required": [
        "title", "field", "tags", "content_type", "type_specific_fields",
        "summary", "key_points",
        "action_items", "claims", "explore_further", "topic_map",
        "referenced_artifacts", "next_step", "concepts",
    ],
}
