"""
All Gemini-related logic lives here. This module is the only place that
talks to the google-genai SDK — the rest of the codebase only ever sees
KnowledgeEntry objects.
"""

import base64
import json

from google import genai
from google.genai import types

from schema import KnowledgeEntry, GEMINI_RESPONSE_SCHEMA, TimelineEntry
from content_types import prompt_reference


EXTRACTION_PROMPT = """You are a knowledge extraction engine for Insightr — an app used by people
who save short-form videos because they want to DO something with them, not just read about them.

The person using this app has limited attention. They saved this reel in a moment of "I should do this."
Your job is to make sure they actually do it. Every field you write should serve that goal.

You have been given:
1. A sequence of keyframes (chronological)
2. A timestamped TRANSCRIPT TIMELINE (what was said, and when)
3. A timestamped ON-SCREEN TEXT TIMELINE (what was shown as text/captions, from OCR)
4. Video/post metadata (which includes the CAPTION)

CRITICAL: Treat the CAPTION (in the metadata) and ON-SCREEN TEXT as highly authoritative. Creators often
put their most detailed breakdowns, steps, and roadmaps directly in the caption rather than saying them out loud.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OUTPUT: A single JSON object. No prose, no markdown fences. Match the schema exactly.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GOLDEN RULE FOR CONTENT EXTRACTION:
- NEVER write high-level summaries *about* the video (e.g., do NOT write "This video explains an 8-week roadmap...").
- Instead, extract the EXACT content, roadmaps, systems, or instructions in full detail.
- If the video only shows a partial layout of a larger system (e.g. only Week 1 of an 8-week roadmap, or Day 1 of a 12-day setup), you MUST use your own deep domain expertise to logically fill in, extrapolate, and complete the remaining weeks/days so that the user receives a fully built out, valuable end-to-end plan.
- Only actual templates, scripts, code, or Notion database schemas should go into `code_snippet` blocks (which will make them copy-pasteable in the app UI). Standard educational explanation and notes should stay in plain text, bullet, or checklist blocks.
- Talk directly to the user. Use active voice and second-person pronoun ("you", "your target", "your checklist").

VISUAL DECORATION & SCANNABILITY:
- **Bold the Important**: Use `**bold text**` for key terms, metrics, and impact phrases within ALL block types.
- **Punchy, Scannable Text**: NEVER use long paragraphs. Break information into short, punchy, single-sentence lines or bullet points. Use high-signal formatting designed for extremely short attention spans. Get straight to the point.
- **Emojis as Landmarks**: You may use relevant emojis at the start of block titles (e.g., "📅 Day 1 — Target Selection") to serve as visual cues.
- **Tone**: Professional, high-signal, personal, hands-on, and direct.

FIELD-BY-FIELD RULES:

▸ title           3–5 words, specific and descriptive.
▸ field           One-word category (e.g. "Productivity", "Fitness", "AI", "Finance").
▸ tags            3–6 lowercase keywords.
▸ content_type    Pick the ONE best type from the list.
▸ type_specific_fields  Use ONLY the labels for your chosen content_type. Empty list for "general".

CONTENT TYPES:
{content_types}

── METADATA & FEED HOOKS ──────────────────────────────────────────────
▸ hook  ONE sentence. This is what the user sees first on the feed card. It must make them
  want to open the insight RIGHT NOW. Not a summary. Not a headline. A reason to act.
  Max 15 words. Start with the outcome, tension, or stakes.
▸ next_step  The ONE thing to do right now. Not a list — a single directive sentence.
  Start with a verb. Be specific.

── GLOBAL INDEXING LAYERS ─────────────────────────────────────────────
These fields are used for global search and discovery tabs. They do NOT need to be
manually repeated in the note body if they don't fit organically.

▸ action_items  Things the user should actually DO. 
  priority: "now" | "soon" | "someday"
▸ concepts  Named things (frameworks, tools, methodologies) that were EXPLAINED.
▸ referenced_artifacts  Specific named things the user would look up: books, courses, papers, templates.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
── NOTE LAYOUT: note_blocks ─────────────────────────────────────────
Construct the entire note body using adaptive note blocks.
Choose the most appropriate block types based on the content rather than forcing
information into predefined sections.

AVAILABLE COMPONENTS:

  key_insight    Highlighted golden card for a high-impact opening. Use this for the most critical thesis, TL;DR, or core idea. 
                 title = A punchy, engaging heading defined by you based on what best hooks the user (e.g. "TL;DR", "The Catch", "Win Condition").

  text           Plain body text. Use for context, background, "why this works".

  bullets        Unordered list — tips, ingredients, features, observations.

  steps          Numbered sequence — recipe, tutorial, setup process.
                 !!! IMPORTANT: DO NOT include numbers (1., 2., etc.) in the content strings. 
                 The app and exporter will add them for you.

  checklist      Interactive toggles the user checks off. Use for action plans.

  stat_row       2–4 numbers or facts shown side by side in a row.
                 Format: "value|label" (e.g. "12 weeks|prep time")

  comparison     Two-column layout. First line = "Option A|Option B".
                 Subsequent lines = "left item|right item".

  label_values   Vertical label + value pairs. Format: "Label: value".

  timeline       Phases, days, or stages. Format: "Phase: what happens".

  quote          A single memorable line from the creator.

  code_snippet   Verbatim copyable text (script, prompt, code).

  warning        Critical pitfall or risk. title required.

  tip            A small useful pro-tip. title required.

  divider        A visual separator between major sections. Leave title and content empty.

TITLE RULES:
  - Make block titles specific to THIS reel's content.
  - Good: "📅 Day 1 — Win Condition", "📞 Outreach CRM Template"
  - Bad: "Key Points", "Overview", "Info"

SEQUENCING: Start with what matters most (usually a `key_insight` with a custom title). Then structure
the rest organically based on what the content actually dictates.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VIDEO METADATA:
{metadata}

TRANSCRIPT TIMELINE:
{transcript_timeline}

ON-SCREEN TEXT TIMELINE (OCR):
{ocr_timeline}
"""


def _format_timeline(timeline: list[TimelineEntry]) -> str:
    if not timeline:
        return "[none available]"
    return "\n".join(f"[{entry.timestamp}] {entry.text}" for entry in timeline)


import time
import random

def extract_knowledge(
    transcript_timeline: list[TimelineEntry],
    ocr_timeline: list[TimelineEntry],
    frames: list,
    api_key: str,
    source_url: str,
    metadata: dict,
) -> KnowledgeEntry:
    """
    Sends timelines, keyframes, and metadata to Gemini and returns a
    validated KnowledgeEntry with all 12 insight features populated.
    """
    client = genai.Client(api_key=api_key)

    parts = []
    for frame in frames:
        frame_b64 = frame["image_b64"] if isinstance(frame, dict) else frame
        parts.append(types.Part.from_bytes(
            data=base64.b64decode(frame_b64),
            mime_type="image/jpeg",
        ))

    prompt = EXTRACTION_PROMPT.format(
        metadata=json.dumps(metadata, indent=2),
        transcript_timeline=_format_timeline(transcript_timeline),
        ocr_timeline=_format_timeline(ocr_timeline),
        content_types=prompt_reference(),
    )
    parts.append(types.Part.from_text(text=prompt))

    max_retries = 3
    base_delay_503 = 5   # seconds — server overloaded
    base_delay_429 = 15  # seconds — quota/rate limit, needs longer pause

    for attempt in range(max_retries + 1):
        try:
            response = client.models.generate_content(
                # gemini-2.5-flash: higher free-tier RPM + TPD quota than 2.0-flash
                model="gemini-2.5-flash",
                contents=parts,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=GEMINI_RESPONSE_SCHEMA,
                ),
            )

            data = json.loads(response.text)
            data["source_url"] = source_url

            return KnowledgeEntry(**data)

        except Exception as e:
            error_str = str(e)
            is_unavailable = "503" in error_str or "UNAVAILABLE" in error_str.upper()
            is_quota = "429" in error_str or "RESOURCE_EXHAUSTED" in error_str.upper() or "quota" in error_str.lower()

            if is_quota and attempt < max_retries:
                delay = (base_delay_429 * (2 ** attempt)) + random.uniform(0, 2)
                print(f"  [!] Gemini quota/rate limit hit (429). Backing off {delay:.1f}s... (Attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                continue

            if is_unavailable and attempt < max_retries:
                delay = (base_delay_503 * (2 ** attempt)) + random.uniform(0, 1)
                print(f"  [!] Gemini is busy (503). Retrying in {delay:.1f}s... (Attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                continue

            raise RuntimeError(f"Gemini API call failed: {e}")
