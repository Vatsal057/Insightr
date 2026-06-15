"""
Structured knowledge schema for Insightr.

Gemini returns JSON matching KnowledgeEntry, which is validated here before
being written to the database. Every entry is a self-contained "insight
card" covering all 12 insight features defined in the product spec.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional, Literal, Any
from pydantic import BaseModel, Field, field_validator

from content_types import all_content_types


class Summary(BaseModel):
    headline: str = Field(description="One sentence capturing why this matters.")
    body: str = Field(description="A short paragraph expanding on the headline.")


class ActionItem(BaseModel):
    id: Optional[int] = None
    entry_id: Optional[int] = None
    text: str
    done: bool = False
    priority: Literal["now", "soon", "someday"] = "soon"
    time_estimate: Optional[str] = None  # e.g. "5 min", "1 hour", "ongoing"


class ImplementationStep(BaseModel):
    """One step in an implementation plan — Feature #3."""
    step_number: int
    title: str
    description: str
    time_estimate: Optional[str] = None  # e.g. "2–3 hours", "Day 1"


class Claim(BaseModel):
    claim: str
    verifiability: Literal["fact", "opinion", "unverified"] = "unverified"
    note: Optional[str] = None


class ToolResource(BaseModel):
    """Feature #5 — Tools & Resources. Broader than ReferencedArtifact."""
    name: str
    type: Literal["tool", "website", "course", "platform", "software", "service", "other"] = "other"
    description: Optional[str] = None
    url: Optional[str] = None


class RabbitHole(BaseModel):
    """Feature #6 — Into the Rabbit Hole."""
    follow_up_questions: List[str] = Field(default_factory=list)
    knowledge_gaps: List[str] = Field(default_factory=list)
    adjacent_topics: List[str] = Field(default_factory=list)
    advanced_concepts: List[str] = Field(default_factory=list)
    deep_research_prompt: str = Field(
        default="",
        description="A reusable LLM prompt the user can paste into any AI to do deeper research."
    )


class TopicMap(BaseModel):
    main_topic: str
    subtopics: List[str] = Field(default_factory=list)


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


class EffortEstimation(BaseModel):
    """Feature #11 — Time & Effort Estimation."""
    time_to_learn: str = Field(description="Estimated time to understand the topic, e.g. '3–5 hours'")
    time_to_implement: str = Field(description="Estimated time to apply the ideas, e.g. '2–4 weeks'")
    difficulty: Literal[1, 2, 3, 4, 5] = Field(description="1 = trivial, 5 = expert-level")
    effort: Literal[1, 2, 3, 4, 5] = Field(description="1 = minimal effort, 5 = high sustained effort")
    difficulty_rationale: Optional[str] = None


class MissingContextItem(BaseModel):
    """Feature #12 — What the Creator Did Not Mention."""
    category: Literal["risk", "limitation", "trade_off", "assumption", "alternative", "additional_context"]
    text: str


class Connection(BaseModel):
    """Computed after the fact, not produced by the LLM."""
    entry_id: int
    title: str
    reason: str


class NoteBlock(BaseModel):
    """
    One adaptive UI block in the note — decided by the AI, rendered natively
    by the Android app. The AI picks which components to show and in what order
    based on what the reel actually contains. No two notes need the same layout.

    COMPONENT TYPES:

      key_insight   → A highlighted cream card. The single most important idea
                      from this reel — the thing worth remembering a year from now.
                      One per note, usually first. title = the insight headline,
                      content = 1–3 sentences expanding on it.

      text          → Plain body text on the dark background. Use for context,
                      explanation, "why this matters", nuance, or anything that
                      needs prose rather than a list. title optional.

      bullets       → A list of items where order doesn't matter — tips, features,
                      ingredients, options, observations. Each item on its own line
                      in content. title required (make it specific).

      steps         → A numbered sequence where order matters — a recipe, a setup
                      process, a ranked list, how to do something. Each step on its
                      own line in content (no numbers, the app adds them).
                      title required.

      checklist     → Interactive toggle items the user will actually check off —
                      things to DO, not just read. Use for action plans, prep lists,
                      launch checklists. Each item on its own line. title required.

      stat_row      → A horizontal row of 2–4 numbers or facts that are more
                      powerful seen side by side. Format each item as
                      "value|label" on its own line, e.g. "12 weeks|prep time".
                      Use for workout stats, macro targets, financial figures,
                      study schedules, ratings. No title needed.

      comparison    → A two-column layout for contrasting things — A vs B,
                      before vs after, pros vs cons, Option 1 vs Option 2.
                      Format: first line = "left_label|right_label" (the column
                      headers), then each row as "left_item|right_item".
                      title required (e.g. "Freelance vs Full-Time").

      label_values  → A vertical list of label + value pairs — structured info
                      that doesn't fit a comparison or stat row. Good for recipe
                      details, product specs, movie info, workout parameters.
                      Format each as "Label: value" on its own line. title optional.

      timeline      → A sequence of phases, days, or stages with descriptions.
                      Format each as "Label: description" on its own line,
                      e.g. "Week 1: Focus only on form, no added weight".
                      Use for programs, plans, sprints, schedules. title required.

      quote         → A single memorable or provocative line from the creator,
                      shown large and highlighted. Use sparingly — only if it's
                      genuinely worth preserving verbatim. No title. content = the
                      quote only, no quotation marks.

      code_snippet  → Verbatim text the user might copy — a script, prompt
                      template, formula, code block, or outreach message.
                      title = what it is (e.g. "Referral Ask Template").
                      content = the raw text, no fences.

    `title` — make it specific to THIS note's content. Ask: would this title
    make sense without reading the note? If not, make it more specific.
      Good: "Why Candidates Get Rejected Before the Coding Round"
      Good: "The 5:2 Macros Split That Actually Works"
      Bad:  "Key Points", "Overview", "Details", "Info"

    `content` — one coherent piece of information per block. Do not cram
    multiple ideas into one block. Split them if they are genuinely different.
    """
    block_type: Literal[
        "key_insight", "text", "bullets", "steps", "checklist",
        "stat_row", "comparison", "label_values", "timeline",
        "quote", "code_snippet"
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


ContentType = str


class TypeSpecificField(BaseModel):
    label: str
    value: str


class KnowledgeEntry(BaseModel):
    """The full structured output for one processed video/post — all 12 insight features."""

    id: Optional[int] = None
    title: str = Field(description="3-5 word punchy title")
    source_url: str
    field: str = Field(description="One-word category, e.g. 'Productivity'")
    tags: List[str] = Field(default_factory=list)

    content_type: ContentType
    type_specific_fields: List[TypeSpecificField] = Field(default_factory=list)

    # Hook — single punchy sentence for the feed card. Different from headline:
    # headline = why it matters; hook = what you're going to do about it.
    # Example: "Stop doing X. Do Y instead. Here's the exact method."
    hook: str = Field(default="", description="One punchy sentence that makes someone want to act. Not a summary — a reason to care right now.")

    # Feature 1: Core Takeaway
    summary: Summary

    # Feature 2: Action Items
    key_points: str
    action_items: List[ActionItem] = Field(default_factory=list)

    # Feature 3: Implementation Plan
    implementation_plan: List[ImplementationStep] = Field(
        default_factory=list,
        description="Step-by-step plan for applying the content's ideas. Empty if not applicable."
    )

    # Feature 4: Claims Made
    claims: List[Claim] = Field(default_factory=list)

    # Feature 5: Tools & Resources
    tools_resources: List[ToolResource] = Field(
        default_factory=list,
        description="Tools, websites, courses, platforms, services mentioned in the content."
    )

    # Feature 6: Into the Rabbit Hole
    rabbit_hole: RabbitHole = Field(default_factory=RabbitHole)

    # Feature 7: Knowledge Cards — stored as `concepts` in DB
    concepts: List[Concept] = Field(default_factory=list)

    # Feature 8: Referenced Artifacts
    referenced_artifacts: List[ReferencedArtifact] = Field(default_factory=list)

    # Feature 10: Topic Map
    topic_map: TopicMap

    # Feature 11: Time & Effort Estimation
    effort_estimation: Optional[EffortEstimation] = None

    # Feature 12: What the Creator Did Not Mention
    missing_context: List[MissingContextItem] = Field(
        default_factory=list,
        description="Important limitations, risks, trade-offs, and assumptions not covered."
    )

    next_step: str = Field(description="1-2 sentence directive: what to actually do with this")

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

    @field_validator("effort_estimation", mode="before")
    @classmethod
    def _validate_effort(cls, v):
        if v is None:
            return None
        if isinstance(v, dict):
            # Clamp difficulty/effort to 1–5
            for key in ("difficulty", "effort"):
                if key in v:
                    try:
                        v[key] = max(1, min(5, int(v[key])))
                    except (TypeError, ValueError):
                        v[key] = 3
        return v


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
                    "priority": {"type": "string", "enum": ["now", "soon", "someday"]},
                    "time_estimate": {"type": "string", "nullable": True},
                },
                "required": ["text", "priority"],
            },
        },
        "implementation_plan": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "step_number": {"type": "integer"},
                    "title": {"type": "string"},
                    "description": {"type": "string"},
                    "time_estimate": {"type": "string", "nullable": True},
                },
                "required": ["step_number", "title", "description"],
            },
        },
        "claims": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "claim": {"type": "string"},
                    "verifiability": {"type": "string", "enum": ["fact", "opinion", "unverified"]},
                    "note": {"type": "string", "nullable": True},
                },
                "required": ["claim", "verifiability"],
            },
        },
        "tools_resources": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "type": {
                        "type": "string",
                        "enum": ["tool", "website", "course", "platform", "software", "service", "other"],
                    },
                    "description": {"type": "string", "nullable": True},
                    "url": {"type": "string", "nullable": True},
                },
                "required": ["name", "type"],
            },
        },
        "rabbit_hole": {
            "type": "object",
            "properties": {
                "follow_up_questions": {"type": "array", "items": {"type": "string"}},
                "knowledge_gaps": {"type": "array", "items": {"type": "string"}},
                "adjacent_topics": {"type": "array", "items": {"type": "string"}},
                "advanced_concepts": {"type": "array", "items": {"type": "string"}},
                "deep_research_prompt": {"type": "string"},
            },
            "required": ["follow_up_questions", "knowledge_gaps", "adjacent_topics", "advanced_concepts", "deep_research_prompt"],
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
        "topic_map": {
            "type": "object",
            "properties": {
                "main_topic": {"type": "string"},
                "subtopics": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["main_topic", "subtopics"],
        },
        "effort_estimation": {
            "type": "object",
            "nullable": True,
            "properties": {
                "time_to_learn": {"type": "string"},
                "time_to_implement": {"type": "string"},
                "difficulty": {"type": "integer"},
                "effort": {"type": "integer"},
                "difficulty_rationale": {"type": "string", "nullable": True},
            },
            "required": ["time_to_learn", "time_to_implement", "difficulty", "effort"],
        },
        "missing_context": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "enum": ["risk", "limitation", "trade_off", "assumption", "alternative", "additional_context"],
                    },
                    "text": {"type": "string"},
                },
                "required": ["category", "text"],
            },
        },
        "next_step": {"type": "string"},
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
                            "quote", "code_snippet"
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
        "summary", "key_points", "action_items", "implementation_plan",
        "claims", "tools_resources", "rabbit_hole", "concepts",
        "referenced_artifacts", "topic_map", "effort_estimation",
        "missing_context", "next_step", "note_blocks",
    ],
}
