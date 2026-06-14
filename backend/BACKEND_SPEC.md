# Insightr Backend Specification
> For frontend agents and developers. Read this file to understand what the backend produces and how to consume it.

---

## Architecture Overview

```
URL (Instagram Reel / Post / TikTok / YouTube Short)
    │
    ▼
downloader.py       yt-dlp + Instaloader → video .mp4 OR image list
    │
    ├──▶ transcriber.py     faster-whisper (local, no API) → timestamped transcript
    ├──▶ extractor.py       OpenCV frame differencing → up to 12 keyframes (base64 JPEG)
    └──▶ ocr.py             Tesseract → on-screen text timeline
    │
    ▼
llm.py              Gemini 2.5 Flash (multimodal) → structured JSON (all 12 features)
    │
    ▼
schema.py           Pydantic validation → KnowledgeEntry
    │
    ├──▶ db.py              SQLite storage (vault.db)
    ├──▶ connections.py     keyword/tag/topic similarity scoring → related entries
    └──▶ feed.py            serialisation → API response
    │
    ▼
api.py              FastAPI on :8000 — consumed by mobile/web frontend
```

---

## The 12 Insight Features

Every processed entry contains all of these. Field names below are the exact JSON keys returned by `GET /api/entries/{id}`.

| # | Feature | JSON Key | Notes |
|---|---------|----------|-------|
| 1 | Core Takeaway | `core_takeaway` | `{ headline, body }` |
| 2 | Action Items | `action_items` | `[{ text, done }]` — checkable |
| 3 | Implementation Plan | `implementation_plan` | `[{ step_number, title, description, time_estimate }]` — may be empty for non-tutorial content |
| 4 | Claims Made | `claims` | `[{ claim, verifiability, note }]` — verifiability: `fact\|opinion\|unverified` |
| 5 | Tools & Resources | `tools_resources` | `[{ name, type, description, url }]` — type: `tool\|website\|course\|platform\|software\|service\|other` |
| 6 | Into the Rabbit Hole | `rabbit_hole` | `{ follow_up_questions[], knowledge_gaps[], adjacent_topics[], advanced_concepts[] }` |
| 6b | Deep Research Prompt | separate endpoint | Fetch via `GET /api/entries/{id}/deep-research-prompt` when user presses the button |
| 7 | Knowledge Cards | `knowledge_cards` | `[{ concept_type, name, summary }]` — these are saved to the vault's concept index |
| 8 | Referenced Artifacts | `referenced_artifacts` | `[{ name, type, description, url, snippet }]` — type: `book\|research_paper\|course\|movie\|podcast\|tool\|link\|template\|other` |
| 10 | Topic Map | `topic_map` | `{ main_topic, subtopics[] }` — render as a node graph |
| 11 | Time & Effort | `effort_estimation` | `{ time_to_learn, time_to_implement, difficulty (1-5), effort (1-5), difficulty_rationale }` — may be null |
| 12 | What's Missing | `missing_context` | `[{ category, text }]` — category: `risk\|limitation\|trade_off\|assumption\|alternative\|additional_context` |

---

## REST API Reference

**Base URL:** `http://localhost:8000`  
**Content-Type:** `application/json` (GET), `application/x-www-form-urlencoded` (POST forms)

### Processing

#### `POST /api/process`
Start processing a URL.  
**Body (form):** `url=<string>`  
**Response:**
```json
{ "task_id": "uuid", "status": "processing", "url": "..." }
```

#### `GET /api/status/{task_id}`
Poll until status changes.  
**Response:**
```json
// In progress:
{ "status": "processing", "url": "..." }
// Done:
{ "status": "completed", "entry_id": 42 }
// Failed:
{ "status": "failed", "error": "..." }
```

---

### Feed & Entries

#### `GET /api/feed?limit=50`
Summary cards for the feed list, newest first.
```json
[
  {
    "id": 42,
    "title": "AI SaaS in 90 Days",
    "headline": "Distribution, not code, is the real bottleneck.",
    "field": "Startup",
    "content_type": "career_advice",
    "tags": ["saas", "ai", "founder"],
    "created_at": "2025-01-15T10:30:00",
    "action_item_count": 5,
    "implementation_step_count": 5,
    "tool_count": 4,
    "effort_estimation": { "difficulty": 4, "effort": 5, "time_to_learn": "8–12 hours", "time_to_implement": "60–90 days" }
  }
]
```

#### `GET /api/entries/{id}`
Full insight card — all 12 features. See **Full Entry Response** section below.

#### `GET /api/entries/{id}/deep-research-prompt`
Returns the on-demand deep research prompt (Feature 6b). Call this when the user presses "Generate Deep Research Prompt".
```json
{ "entry_id": 42, "deep_research_prompt": "You are a research assistant. I recently watched..." }
```

---

### Action Items

#### `GET /api/todo?done=false`
All action items. `done` param: `true` = completed only, `false` = pending only, omit = all.
```json
[{ "id": 1, "text": "...", "done": false, "entry_id": 42, "title": "..." }]
```

#### `POST /api/todo/{item_id}/check?done=true`
Toggle action item. `done=false` to uncheck.

---

### Search

#### `GET /api/search?q=&tag=&field=&content_type=`
FTS5 search across title, summary, key points, claims, tags, tool names.

---

### Knowledge Cards (Concepts)

#### `GET /api/concepts?concept_type=framework&query=pomodoro`
The vault's deduplicated concept index.
```json
[{ "id": 1, "concept_type": "framework", "name": "AIDA", "summary": "..." }]
```

#### `GET /api/concepts/{id}/entries`
All entries where this concept appears.

---

### Collections

#### `GET /api/collections`
#### `POST /api/collections` — body: `name=<string>&entry_id=<int>`
#### `GET /api/collections/{name}` — returns summary cards

---

### Markdown Export

#### `GET /api/export/{entry_id}` → `text/plain`
#### `GET /api/export/collection/{name}` → `text/plain`
Obsidian-flavoured Markdown with all 12 features. Useful for "Save to Obsidian" feature.

---

## Full Entry Response

```jsonc
{
  // Meta
  "id": 42,
  "title": "AI SaaS in 90 Days",
  "source_url": "https://www.instagram.com/reel/...",
  "field": "Startup",
  "tags": ["saas", "ai", "solo-founder"],
  "content_type": "career_advice",
  "type_specific_fields": [{ "label": "Advice", "value": "..." }],
  "created_at": "2025-01-15T10:30:00",

  // Feature 1: Core Takeaway
  "core_takeaway": {
    "headline": "Distribution, not code, is the real bottleneck for solo SaaS founders.",
    "body": "Using AI tools like Cursor compresses build time dramatically..."
  },

  // Feature 2: Action Items
  "key_points": "**Distribution** beats product quality at the early stage\n**AI tools** cut dev time by ~10x\n...",
  "action_items": [
    { "text": "Identify one painful workflow in your current job", "done": false }
  ],
  "next_step": "Pick one painful workflow you encounter weekly and spend 2 hours this weekend prototyping a solution.",

  // Feature 3: Implementation Plan
  "implementation_plan": [
    { "step_number": 1, "title": "Validate the idea", "description": "Talk to 10 potential users...", "time_estimate": "Week 1–2" }
  ],

  // Feature 4: Claims Made
  "claims": [
    { "claim": "AI tools can cut development time by 10x", "verifiability": "unverified", "note": null },
    { "claim": "Distribution matters more than product", "verifiability": "opinion", "note": null }
  ],

  // Feature 5: Tools & Resources
  "tools_resources": [
    { "name": "Cursor", "type": "tool", "description": "AI-first IDE used to ship the MVP", "url": "https://cursor.sh" },
    { "name": "Stripe", "type": "platform", "description": "Subscription billing", "url": "https://stripe.com" }
  ],

  // Feature 6: Into the Rabbit Hole
  "rabbit_hole": {
    "follow_up_questions": ["What does the actual revenue breakdown look like?"],
    "knowledge_gaps": ["No mention of churn rate or retention"],
    "adjacent_topics": ["Micro-SaaS vs traditional SaaS", "Pricing psychology"],
    "advanced_concepts": ["LTV/CAC ratio optimisation", "Product-led growth"]
    // deep_research_prompt NOT included here — use dedicated endpoint
  },

  // Feature 7: Knowledge Cards
  "knowledge_cards": [
    { "id": 1, "concept_type": "framework", "name": "Build in Public", "summary": "Sharing your development process openly on social media..." }
  ],

  // Feature 8: Referenced Artifacts
  "referenced_artifacts": [
    { "name": "The Mom Test", "type": "book", "description": "How to talk to customers...", "url": "https://www.momtestbook.com", "snippet": null }
  ],

  // Feature 10: Topic Map
  "topic_map": {
    "main_topic": "AI-Assisted SaaS",
    "subtopics": ["Solo Founder Strategy", "AI Build Tools", "Distribution Channels", "Pricing", "Community Launch"]
  },

  // Feature 11: Time & Effort Estimation
  "effort_estimation": {
    "time_to_learn": "8–12 hours",
    "time_to_implement": "60–90 days",
    "difficulty": 4,
    "effort": 5,
    "difficulty_rationale": "Requires business sense, technical skills, and marketing ability simultaneously."
  },

  // Feature 12: What the Creator Did Not Mention
  "missing_context": [
    { "category": "risk", "text": "No mention of churn rate — early SaaS products often lose 10–20% of users monthly." },
    { "category": "assumption", "text": "Assumes you already have an audience or can quickly build one." },
    { "category": "limitation", "text": "$50K/mo is gross revenue — operating costs not mentioned." }
  ],

  // Vault Connections (computed, not LLM-generated)
  "connections": [
    { "entry_id": 7, "title": "Notion SaaS Template Review", "reason": "tags: saas, tools; both mention: stripe" }
  ]
}
```

---

## Database Schema (SQLite — vault.db)

```
entries              id, title, source_url, field, content_type, type_specific_fields,
                     summary (JSON), key_points, implementation_plan (JSON),
                     tools_resources (JSON), rabbit_hole (JSON),
                     referenced_artifacts (JSON), topic_map (JSON),
                     effort_estimation (JSON, nullable), missing_context (JSON),
                     explore_further (JSON), next_step, keywords (JSON), created_at

tags / entry_tags    many-to-many tag index
action_items         id, entry_id, text, done
claims               id, entry_id, claim, verifiability, note
connections          entry_id, related_entry_id, reason
concepts             id, concept_type, name, summary, created_at   [UNIQUE(type,name)]
entry_concepts       many-to-many link between entries and concepts
collections          id, name
collection_entries   collection_id, entry_id
entries_fts          FTS5 virtual table: title, summary_text, key_points, claims_text, tags_text, tools_text
```

---

## Content Types (for `content_type` field)

`coding_tutorial` | `workout_routine` | `fitness_nutrition` | `movie_tv_recommendation` |
`music_recommendation` | `book_recommendation` | `recipe` | `tool_app_recommendation` |
`tool_review` | `travel_guide` | `finance_tip` | `career_advice` | `life_hack` |
`fashion_outfit` | `home_diy` | `language_learning` | `comparison` | `listicle` |
`opinion` | `story` | `news` | `research_breakdown` | `motivational` | `qna` | `general`

---

## Environment Variables (.env)

```
GEMINI_API_KEY=...              # Required. Get from https://aistudio.google.com
VAULT_DB_PATH=vault.db          # Optional. Defaults to ./vault.db
VAULT_EXPORT_PATH=exports       # Optional. Markdown export directory
INSTAGRAM_COOKIES_PATH=...      # Optional. Cookies file for private Instagram content
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

Swagger UI available at: `http://localhost:8000/docs`
