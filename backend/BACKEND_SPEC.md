# Insightr Backend Specification — Updated
> Accurate to the actual implementation. For Android developers.

---

## Architecture Overview

```
URL (Instagram Reel / Post / TikTok / YouTube Short)
    │
    ▼
downloader.py       yt-dlp + Instaloader → video .mp4 OR image list
    │
    ├──▶ transcriber.py     faster-whisper (local) → timestamped transcript
    ├──▶ extractor.py       OpenCV frame differencing → up to 12 keyframes
    └──▶ ocr.py             Tesseract → on-screen text timeline
    │
    ▼
llm.py              Gemini 2.5 Flash (multimodal) → structured JSON
    │
    ▼
schema.py           Pydantic validation → KnowledgeEntry
    │
    ├──▶ db.py              SQLite (vault.db)
    ├──▶ connections.py     tag/topic/keyword similarity → related entries
    └──▶ feed.py            serialisation → zone-structured API response
    │
    ▼
api.py              FastAPI on :8000
```

---

## The 12 Insight Features

Every processed entry contains all 12. Returned via `GET /api/entries/{id}` as a **zone-structured response**.

| # | Feature | Zone | Response Key | Shape |
|---|---------|------|--------------|-------|
| 1 | Core Takeaway | Zone 2 | `zone_substance.core_takeaway` | `{ headline, body }` |
| 2 | Action Items | Zone 2 | `zone_substance.action_items` | `[{ id, text, done, priority, time_estimate, entry_id }]` |
| 3 | Implementation Plan | Zone 2 | `zone_substance.implementation_plan` | `[{ step_number, title, description, time_estimate }]` |
| 4 | Claims Made | Zone 3 | `zone_deep.claims` | `[{ claim, verifiability, note }]` |
| 5 | Tools & Resources | Zone 2 | `zone_substance.tools_resources` | `[{ name, type, description, url }]` |
| 6 | Into the Rabbit Hole | Zone 3 | `zone_deep.rabbit_hole` | `{ follow_up_questions[], knowledge_gaps[], adjacent_topics[], advanced_concepts[] }` |
| 6b | Deep Research Prompt | Separate | `/api/entries/{id}/deep-research-prompt` | Plain endpoint response |
| 7 | Knowledge Cards | Zone 3 | `zone_deep.knowledge_cards` | `[{ id, concept_type, name, summary }]` |
| 8 | Referenced Artifacts | Zone 3 | `zone_deep.referenced_artifacts` | `[{ name, type, description, url, snippet }]` |
| 11 | Time & Effort | Zone 3 | `zone_deep.effort_estimation` | `{ time_to_learn, time_to_implement, difficulty (1-5), effort (1-5), difficulty_rationale }` |
| 12 | What's Missing | Zone 3 | `zone_deep.missing_context` | `[{ category, text }]` |

---

## Zone-Structured Entry Response

The entry response is optimized for **3-zone rendering** on mobile (ADHD-friendly):

- **Zone 1 — "The Grab"** (always visible, above-fold): immediate action prompts
- **Zone 2 — "The Substance"** (default expanded): main content + adaptive blocks
- **Zone 3 — "The Deep End"** (collapsed behind toggle): deep analysis + connections

---

## REST API Reference

**Base URL:** `http://localhost:8000`  
**Content-Type:** `application/json` (GET), `application/x-www-form-urlencoded` (POST)

### Processing

#### `POST /api/process`
Start processing a URL.  
**Body (form):** `url=<string>`  
**Response:**
```json
{ "task_id": "uuid", "status": "processing", "url": "..." }
```

#### `GET /api/status/{task_id}`
Poll processing status.  
**Response:**
```json
// In progress:
{ "status": "processing", "url": "..." }
// Completed:
{ "status": "completed", "entry_id": 42 }
// Failed:
{ "status": "failed", "error": "..." }
```

---

### Feed & Entries

#### `GET /api/feed?limit=50`
Summary cards for feed list, newest first.
```json
[
  {
    "id": 42,
    "title": "AI SaaS in 90 Days",
    "hook": "Distribution beats code every time.",
    "field": "Startup",
    "content_type": "career_advice",
    "tags": ["saas", "ai", "founder"],
    "created_at": "2025-01-15T10:30:00",
    "top_action": { "id": 1, "text": "Pick one painful workflow", "done": false, "priority": "now", "time_estimate": "2 hours", "entry_id": 42 },
    "action_item_count": 5,
    "now_action_count": 2,
    "implementation_step_count": 5,
    "tool_count": 4,
    "effort_pill": { "label": "60–90 days · Challenging", "difficulty": 4, "effort": 5, "time_to_implement": "60–90 days", "time_to_learn": "8–12 hours" }
  }
]
```

#### `GET /api/entries/{id}`
Full zone-structured insight card. See **Full Entry Response** below.

#### `GET /api/entries/{id}/deep-research-prompt`
On-demand deep research prompt.
```json
{ "entry_id": 42, "deep_research_prompt": "You are a research assistant..." }
```

---

### Action Items

#### `GET /api/todo?done=false`
All action items. `done`: `true` = completed only, `false` = pending only, omit = all.
```json
[
  {
    "id": 1,
    "text": "Pick one painful workflow",
    "done": false,
    "priority": "now",
    "time_estimate": "2 hours",
    "entry_id": 42,
    "title": "AI SaaS in 90 Days"
  }
]
```

#### `POST /api/todo/{item_id}/check?done=true`
Toggle action item. `done=false` to uncheck.
```json
{ "item_id": 1, "done": true }
```

---

### Search

#### `GET /api/search?q=&tag=&field=&content_type=`
Full-text search across title, summary, key points, claims, tags, tool names.

---

### Knowledge Cards / Concepts

#### `GET /api/concepts?concept_type=framework&query=pomodoro`
Deduplicated concept index.
```json
[{ "id": 1, "concept_type": "framework", "name": "AIDA", "summary": "..." }]
```

#### `GET /api/concepts/{id}/entries`
All entries where this concept appears.

---

### Collections

#### `GET /api/collections`
```json
[{ "name": "Research Notes", "entry_count": 12 }]
```

#### `POST /api/collections`
Body: `name=<string>&entry_id=<int>`

#### `GET /api/collections/{name}`
Returns summary cards filtered to this collection.

---

### Markdown Export

#### `GET /api/export/{id}` → `text/plain`
#### `GET /api/export/collection/{name}` → `text/plain`
Obsidian-flavoured Markdown.

---

## Full Entry Response (Zone-Structured)

```jsonc
{
  // ── Meta ──────────────────────────────────────────────────────
  "id": 42,
  "title": "AI SaaS in 90 Days",
  "source_url": "https://instagram.com/reel/...",
  "field": "Startup",
  "tags": ["saas", "ai", "founder"],
  "content_type": "career_advice",
  "type_specific_fields": [{ "label": "Advice", "value": "..." }],
  "created_at": "2025-01-15T10:30:00",

  // ── ZONE 1: The Grab (above-fold, always visible) ──────────────
  "zone_grab": {
    "hook": "Distribution beats code every time.",
    "next_step": "Pick one painful workflow you encounter weekly and spend 2 hours prototyping.",
    "top_action": {
      "id": 1,
      "text": "Identify one painful workflow in your current job",
      "done": false,
      "priority": "now",
      "time_estimate": "2 hours",
      "entry_id": 42
    },
    "effort_pill": {
      "label": "60–90 days · Challenging",
      "difficulty": 4,
      "effort": 5,
      "time_to_implement": "60–90 days",
      "time_to_learn": "8–12 hours"
    }
  },

  // ── ZONE 2: The Substance (expanded by default) ────────────────
  "zone_substance": {
    "core_takeaway": {
      "headline": "Distribution, not code, is the real bottleneck for solo SaaS founders.",
      "body": "Using AI tools like Cursor compresses build time dramatically..."
    },
    "note_blocks": [
      {
        "block_type": "key_insight",
        "title": "The Core Insight",
        "content": "Distribution matters more than product quality at the early stage."
      },
      {
        "block_type": "steps",
        "title": "How to Build It",
        "content": "Validate the idea\nBuild the MVP\nLaunch to the audience"
      },
      {
        "block_type": "checklist",
        "title": "Quick Wins",
        "content": "Identify one painful workflow\nSpend 2 hours this weekend prototyping\nShow 5 people your prototype"
      }
    ],
    "action_items": [
      {
        "id": 1,
        "text": "Identify one painful workflow in your current job",
        "done": false,
        "priority": "now",
        "time_estimate": "2 hours",
        "entry_id": 42
      },
      {
        "id": 2,
        "text": "Build a landing page",
        "done": false,
        "priority": "soon",
        "time_estimate": "4 hours",
        "entry_id": 42
      },
      {
        "id": 3,
        "text": "Talk to 10 potential users",
        "done": false,
        "priority": "someday",
        "time_estimate": "1 week",
        "entry_id": 42
      }
    ],
    "key_points": "**Distribution** beats product quality at the early stage\n**AI tools** cut dev time by ~10x\n**Validation** prevents building the wrong thing",
    "tools_resources": [
      {
        "name": "Cursor",
        "type": "tool",
        "description": "AI-first IDE used to ship the MVP",
        "url": "https://cursor.sh"
      },
      {
        "name": "Stripe",
        "type": "platform",
        "description": "Subscription billing",
        "url": "https://stripe.com"
      }
    ],
    "implementation_plan": [
      {
        "step_number": 1,
        "title": "Validate the idea",
        "description": "Talk to 10 potential users and understand their pain points.",
        "time_estimate": "Week 1–2"
      },
      {
        "step_number": 2,
        "title": "Build the MVP",
        "description": "Use AI tools to ship the minimal viable product.",
        "time_estimate": "Week 3–4"
      }
    ]
  },

  // ── ZONE 3: The Deep End (collapsed behind "Go Deeper" toggle) ─
  "zone_deep": {
    "claims": [
      {
        "claim": "AI tools can cut development time by 10x",
        "verifiability": "unverified",
        "note": null
      },
      {
        "claim": "Distribution matters more than product",
        "verifiability": "opinion",
        "note": null
      }
    ],
    "missing_context": [
      {
        "category": "risk",
        "text": "No mention of churn rate — early SaaS products often lose 10–20% of users monthly."
      },
      {
        "category": "assumption",
        "text": "Assumes you already have an audience or can quickly build one."
      }
    ],
    "rabbit_hole": {
      "follow_up_questions": [
        "What does the actual revenue breakdown look like?",
        "How much time does distribution actually take?"
      ],
      "knowledge_gaps": [
        "No mention of churn rate or retention",
        "No breakdown of time spent on code vs. marketing"
      ],
      "adjacent_topics": [
        "Micro-SaaS vs traditional SaaS",
        "Pricing psychology"
      ],
      "advanced_concepts": [
        "LTV/CAC ratio optimisation",
        "Product-led growth"
      ]
    },
    "knowledge_cards": [
      {
        "id": 5,
        "concept_type": "framework",
        "name": "Build in Public",
        "summary": "Sharing your development process openly on social media to build audience and credibility."
      },
      {
        "id": 12,
        "concept_type": "tool",
        "name": "Cursor",
        "summary": "AI-first code editor that accelerates development by 10x using AI completion."
      }
    ],
    "referenced_artifacts": [
      {
        "name": "The Mom Test",
        "type": "book",
        "description": "How to talk to customers and validate ideas without confirmation bias.",
        "url": "https://www.momtestbook.com",
        "snippet": null
      },
      {
        "name": "The Lean Startup",
        "type": "book",
        "description": "Methodology for validating product ideas with minimal resources.",
        "url": "https://www.leanstartup.com",
        "snippet": null
      }
    ],
    "effort_estimation": {
      "time_to_learn": "8–12 hours",
      "time_to_implement": "60–90 days",
      "difficulty": 4,
      "effort": 5,
      "difficulty_rationale": "Requires business sense, technical skills, and marketing ability simultaneously."
    },
    "connections": [
      {
        "entry_id": 7,
        "title": "Notion SaaS Template Review",
        "reason": "tags: saas, tools; both mention: stripe"
      },
      {
        "entry_id": 11,
        "title": "How to Validate Product Ideas",
        "reason": "same field: Startup; topics: validation, distribution"
      }
    ]
  }
}
```

---

## NoteBlock Types (Adaptive Blocks)

The `zone_substance.note_blocks` array contains adaptive blocks chosen by the LLM. Each has a `block_type`, optional `title`, and `content` (always a string).

| block_type | Renders As | Content Format |
|------------|-----------|----------------|
| `key_insight` | Highlighted card (warm cream bg) | Plain text prose |
| `text` | Body paragraph | Plain text |
| `bullets` | Unordered list | One item per line |
| `steps` | Numbered list | One step per line, no prefix |
| `checklist` | Checkbox list | One item per line |
| `stat_row` | 2–4 side-by-side stat bubbles | `"value\|label"` per line |
| `comparison` | Two-column table | First line: `"LeftHeader\|RightHeader"`, then rows |
| `label_values` | Vertical key–value pairs | `"Label: value"` per line |
| `timeline` | Vertical phase list | `"Label: description"` per line |
| `quote` | Large pull-quote | Plain text |
| `code_snippet` | Monospace code block | Raw text |

---

## Action Item Fields

Action items include a `priority` field for filtering:

```json
{
  "id": 1,
  "text": "Identify one painful workflow",
  "done": false,
  "priority": "now",           // "now" | "soon" | "someday"
  "time_estimate": "2 hours",  // optional human estimate
  "entry_id": 42,
  "title": "AI SaaS in 90 Days"
}
```

---

## Verifiability Badge Values

Claims use `verifiability` to categorize confidence:

- `fact` — Empirically verifiable claim
- `opinion` — Subjective statement
- `unverified` — Claim without source or evidence

---

## Concept Type Values

Knowledge cards use these concept types:

- `concept` — Abstract idea
- `framework` — Methodology or system
- `tool` — Software or service
- `book` — Written work
- `person` — Named individual
- `methodology` — Formal process
- `website` — Web resource

---

## Missing Context Categories

Items in `missing_context` use these category labels:

- `risk` — Potential downside or danger
- `limitation` — Known constraint
- `trade_off` — Choice between options
- `assumption` — Unstated precondition
- `alternative` — Different approach
- `additional_context` — Supplementary info

---

## Content Types

Entries are classified by `content_type`:

`coding_tutorial | workout_routine | fitness_nutrition | movie_tv_recommendation | music_recommendation | book_recommendation | recipe | tool_app_recommendation | tool_review | travel_guide | finance_tip | career_advice | life_hack | fashion_outfit | home_diy | language_learning | comparison | listicle | opinion | story | news | research_breakdown | motivational | qna | general`

---

## Error Responses

All endpoints return errors as:
```json
{ "error": "description of what went wrong" }
```

HTTP status codes:
- `404` — Entry/collection not found
- `400` — Invalid query parameters
- `500` — Server error

---

## Environment Variables

```
GEMINI_API_KEY=...              # Required. Get from https://aistudio.google.com
VAULT_DB_PATH=vault.db          # Optional. Defaults to ./vault.db
VAULT_EXPORT_PATH=exports       # Optional. Markdown export directory
INSTAGRAM_COOKIES_PATH=...      # Optional. For private Instagram content
```

---

## Running the Backend

```bash
pip install -r requirements.txt
cp .env.example .env            # Add your GEMINI_API_KEY
python api.py                   # Starts on http://0.0.0.0:8000
# or:
uvicorn api:app --reload --port 8000
```

Swagger UI: `http://localhost:8000/docs`

---

## Key Implementation Notes

1. **Processing is async** — `POST /api/process` returns immediately with a task_id. Poll `GET /api/status/{task_id}` every 2 seconds until `status` changes to `completed` or `failed`.

2. **Zone structure is mandatory** — All entry responses have `zone_grab`, `zone_substance`, `zone_deep`. The frontend should render Zone 1 always visible, Zone 2 expanded by default, Zone 3 collapsed behind a toggle.

3. **NoteBlocks are adaptive** — Don't assume a fixed layout. The LLM chooses which block types to use per entry. A component renderer must switch on `block_type` and render accordingly.

4. **Action items are prioritized** — The `priority` field (`now | soon | someday`) sorts action items. `now` items are urgent and should be highlighted.

5. **Connections are computed locally** — Related entries are found by comparing tags, topics, keywords, and artifacts. No external service or embedding model required.

6. **Deep research prompt is on-demand** — Fetch it only when the user taps the button to avoid bloating the main card response.

7. **All responses are JSON** — Only `/api/export/*` endpoints return plain text (Markdown).