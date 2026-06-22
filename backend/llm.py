"""
LLM extraction module for Insightr.

Primary path:  Groq (Llama 3.3 70B) — text-only, uses frame descriptions from Florence-2.
Fallback path: Gemini 2.5-flash — multimodal, receives raw keyframe images directly.

The primary path never sends images to the LLM. Instead it receives pre-computed
text descriptions (from vision.py) alongside transcript and OCR timelines.
"""

import base64
import json
import os
import time
import random

from google import genai
from google.genai import types

from schema import KnowledgeEntry, GEMINI_RESPONSE_SCHEMA, TimelineEntry
from content_types import prompt_reference


# ─── Shared prompt template ─────────────────────────────────────────────────

EXTRACTION_PROMPT = """You are a knowledge extraction engine for Insightr — an app used by people
who save short-form videos because they want to DO something with them, not just read about them.

The person using this app has limited attention. They saved this reel in a moment of "I should do this."
Your job is to make sure they actually do it. Every field you write should serve that goal.

You have been given:
1. A timestamped TRANSCRIPT TIMELINE (what was said, and when)
2. A timestamped ON-SCREEN TEXT TIMELINE (what was shown as text/captions, from OCR)
3. A timestamped VISUAL DESCRIPTION TIMELINE (what was visually happening in each scene)
4. Video/post metadata (which includes the CAPTION)

CRITICAL: Treat the CAPTION (in the metadata) and ON-SCREEN TEXT as highly authoritative. Creators often
put their most detailed breakdowns, steps, and roadmaps directly in the caption rather than saying them out loud.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OUTPUT: A single JSON object. No prose, no markdown fences. Match the schema exactly.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GOLDEN RULE FOR CONTENT EXTRACTION:
- NEVER write high-level summaries *about* the video (e.g., do NOT write "This video explains a concept...").
- Instead, extract the EXACT content, roadmaps, systems, or instructions in full detail.
- If the video only shows a partial layout of a larger system or process, you MUST use your own deep domain expertise to logically fill in, extrapolate, and complete the remaining parts so that the user receives a fully built out, valuable end-to-end plan.
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

  CRITICAL RULE FOR ALL LIST/MULTI-ITEM BLOCKS (bullets, steps, checklist, stat_row, comparison, label_values, timeline):
  You MUST place each individual item on a NEW LINE (\\n). Do NOT combine multiple items on a single line.

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

  label_values   Vertical label + value pairs. Format: "Label: value" (one per line).

  timeline       Phases, days, or stages. Format: "Phase: what happens" (one per line).

  quote          A single memorable line from the creator.

  code_snippet   Verbatim copyable text (script, prompt, code).

  warning        Critical pitfall or risk. title required.

  tip            A small useful pro-tip. title required.

  divider        A visual separator between major sections. Leave title and content empty.

TITLE RULES:
  - Make block titles specific to THIS reel's content.
  - Good: "📅 Day 1 — Win Condition", "📞 Outreach CRM Template"
  - Bad: "Key Points", "Overview", "Info"

SEQUENCING:
- Start with what matters most (usually a `key_insight` with a custom title).
- ARTIFACT REVIEW RULE: If the video discusses, reviews, or is based on an artifact (e.g., a book, course, research paper, podcast, movie, TV show, guide, template, dataset, etc.), you MUST place a `label_values` block as the very first block in `note_blocks` (titled "📖 Book: [Name]" or similar). This catalog block must detail the key metadata (Author/Creator, Release Year, Genre, Rating, Scale).
- CATALOG IS NOT THE END: Prepending the metadata catalog block is only the starting point. The subsequent blocks (bullets, key_insight, timeline, steps, etc.) MUST explain the actual content, core thesis, and detailed takeaways of the artifact exactly as described in the video.
- Structure the rest organically based on what the content actually dictates.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VIDEO METADATA:
{metadata}

TRANSCRIPT TIMELINE:
{transcript_timeline}

ON-SCREEN TEXT TIMELINE (OCR):
{ocr_timeline}

VISUAL DESCRIPTION TIMELINE:
{visual_timeline}
"""


# ─── Gemini-specific prompt (for fallback — includes image instruction) ─────

GEMINI_EXTRACTION_PROMPT = """You are a knowledge extraction engine for Insightr — an app used by people
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
- NEVER write high-level summaries *about* the video (e.g., do NOT write "This video explains a concept...").
- Instead, extract the EXACT content, roadmaps, systems, or instructions in full detail.
- If the video only shows a partial layout of a larger system or process, you MUST use your own deep domain expertise to logically fill in, extrapolate, and complete the remaining parts so that the user receives a fully built out, valuable end-to-end plan.
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

  CRITICAL RULE FOR ALL LIST/MULTI-ITEM BLOCKS (bullets, steps, checklist, stat_row, comparison, label_values, timeline):
  You MUST place each individual item on a NEW LINE (\\n). Do NOT combine multiple items on a single line.

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

  label_values   Vertical label + value pairs. Format: "Label: value" (one per line).

  timeline       Phases, days, or stages. Format: "Phase: what happens" (one per line).

  quote          A single memorable line from the creator.

  code_snippet   Verbatim copyable text (script, prompt, code).

  warning        Critical pitfall or risk. title required.

  tip            A small useful pro-tip. title required.

  divider        A visual separator between major sections. Leave title and content empty.

TITLE RULES:
  - Make block titles specific to THIS reel's content.
  - Good: "📅 Day 1 — Win Condition", "📞 Outreach CRM Template"
  - Bad: "Key Points", "Overview", "Info"

SEQUENCING:
- Start with what matters most (usually a `key_insight` with a custom title).
- ARTIFACT REVIEW RULE: If the video discusses, reviews, or is based on an artifact (e.g., a book, course, research paper, podcast, movie, TV show, guide, template, dataset, etc.), you MUST place a `label_values` block as the very first block in `note_blocks` (titled "📖 Book: [Name]" or similar). This catalog block must detail the key metadata (Author/Creator, Release Year, Genre, Rating, Scale).
- CATALOG IS NOT THE END: Prepending the metadata catalog block is only the starting point. The subsequent blocks (bullets, key_insight, timeline, steps, etc.) MUST explain the actual content, core thesis, and detailed takeaways of the artifact exactly as described in the video.
- Structure the rest organically based on what the content actually dictates.

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


def _repair_groq_output(data: dict) -> dict:
    """
    Normalize Groq/Llama output to match the Pydantic schema.

    Llama ignores field-name constraints even with json_object mode and tends to:
      - use 'type' instead of 'block_type' in note_blocks
      - use 'item' instead of 'text' in action_items
      - return concepts as plain strings instead of {concept_type, name, summary}
      - use freeform strings for referenced_artifacts.type
    """
    VALID_ARTIFACT_TYPES = {
        "book", "research_paper", "course", "song", "album", "movie",
        "tv_show", "podcast", "video", "document", "presentation",
        "lecture", "interview", "tutorial", "guide", "framework",
        "template", "dataset", "tool", "link", "other"
    }
    VALID_CONCEPT_TYPES = {
        "concept", "framework", "tool", "book", "person", "methodology", "website"
    }
    VALID_BLOCK_TYPES = {
        "key_insight", "text", "bullets", "steps", "checklist",
        "stat_row", "comparison", "label_values", "timeline",
        "quote", "code_snippet", "warning", "tip", "divider"
    }

    # --- type_specific_fields: dict → list of {label, value} ---
    tsf = data.get("type_specific_fields", [])
    if isinstance(tsf, dict):
        # Llama often returns {"label1": "value1", ...} instead of [{label, value}, ...]
        data["type_specific_fields"] = [
            {"label": str(k), "value": str(v)} for k, v in tsf.items()
        ]
    elif isinstance(tsf, list):
        # Ensure each item is a dict with label/value keys
        fixed_tsf = []
        for item in tsf:
            if isinstance(item, dict) and "label" in item and "value" in item:
                fixed_tsf.append(item)
            elif isinstance(item, dict):
                # Try to salvage: take first key-value pair
                for k, v in item.items():
                    fixed_tsf.append({"label": str(k), "value": str(v)})
                    break
        data["type_specific_fields"] = fixed_tsf
    else:
        data["type_specific_fields"] = []

    # --- note_blocks: 'type' → 'block_type', ensure content is a string ---
    fixed_blocks = []
    for block in data.get("note_blocks", []):
        if not isinstance(block, dict):
            continue
        # rename 'type' → 'block_type' if needed
        if "block_type" not in block and "type" in block:
            block["block_type"] = block.pop("type")
        # ensure block_type is valid
        if block.get("block_type") not in VALID_BLOCK_TYPES:
            block["block_type"] = "text"
        # content must be a string — join lists
        if isinstance(block.get("content"), list):
            block["content"] = "\n".join(str(x) for x in block["content"])
        block.setdefault("title", "")
        block.setdefault("content", "")
        fixed_blocks.append(block)
    data["note_blocks"] = fixed_blocks

    # --- action_items: 'item' → 'text' ---
    fixed_actions = []
    for item in data.get("action_items", []):
        if not isinstance(item, dict):
            continue
        if "text" not in item and "item" in item:
            item["text"] = item.pop("item")
        if "text" not in item:
            continue  # unfixable — skip
        item.setdefault("priority", "soon")
        fixed_actions.append(item)
    data["action_items"] = fixed_actions

    # --- concepts: plain strings → {concept_type, name, summary} ---
    fixed_concepts = []
    for c in data.get("concepts", []):
        if isinstance(c, str):
            fixed_concepts.append({
                "concept_type": "concept",
                "name": c,
                "summary": "",
            })
        elif isinstance(c, dict):
            if "concept_type" not in c:
                c["concept_type"] = "concept"
            if c.get("concept_type") not in VALID_CONCEPT_TYPES:
                c["concept_type"] = "concept"
            c.setdefault("name", "")
            c.setdefault("summary", "")
            fixed_concepts.append(c)
    data["concepts"] = fixed_concepts

    # --- referenced_artifacts: normalise type to allowed literal ---
    for artifact in data.get("referenced_artifacts", []):
        if not isinstance(artifact, dict):
            continue
        if artifact.get("type") not in VALID_ARTIFACT_TYPES:
            artifact["type"] = "other"

    return data


# ─── PRIMARY: Groq (Llama 3.3 70B) ──────────────────────────────────────────

def _extract_via_groq(
    transcript_timeline: list[TimelineEntry],
    ocr_timeline: list[TimelineEntry],
    visual_timeline: list[TimelineEntry],
    source_url: str,
    metadata: dict,
) -> KnowledgeEntry:
    """
    Primary extraction using Groq's free API with Llama 3.3 70B.
    Text-only — no images sent. Uses frame descriptions from Florence-2.
    """
    from groq import Groq

    groq_key = os.getenv("GROQ_API_KEY", "").strip()
    if not groq_key:
        raise RuntimeError("GROQ_API_KEY not set.")

    client = Groq(api_key=groq_key)

    prompt = EXTRACTION_PROMPT.format(
        metadata=json.dumps(metadata, indent=2),
        transcript_timeline=_format_timeline(transcript_timeline),
        ocr_timeline=_format_timeline(ocr_timeline),
        visual_timeline=_format_timeline(visual_timeline),
        content_types=prompt_reference(),
    )

    max_retries = 2
    for attempt in range(max_retries + 1):
        try:
            response = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a JSON-only output engine. Respond with valid JSON matching the requested schema exactly. No markdown fences, no commentary."
                    },
                    {
                        "role": "user",
                        "content": prompt,
                    }
                ],
                temperature=0.3,
                max_tokens=8000,
                response_format={"type": "json_object"},
            )

            raw_text = response.choices[0].message.content
            data = json.loads(raw_text)
            data["source_url"] = source_url
            data = _repair_groq_output(data)

            return KnowledgeEntry(**data)

        except Exception as e:
            error_str = str(e)
            is_rate_limit = "429" in error_str or "rate_limit" in error_str.lower()

            if is_rate_limit and attempt < max_retries:
                delay = (10 * (2 ** attempt)) + random.uniform(0, 2)
                print(f"  [!] Groq rate limit hit. Backing off {delay:.1f}s... (Attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                continue

            raise RuntimeError(f"Groq API failed: {e}")


# ─── FALLBACK: Gemini (multimodal, raw frames) ──────────────────────────────

def _extract_via_gemini(
    transcript_timeline: list[TimelineEntry],
    ocr_timeline: list[TimelineEntry],
    frames: list,
    api_key: str,
    source_url: str,
    metadata: dict,
) -> KnowledgeEntry:
    """
    Fallback extraction using Gemini 2.5-flash with raw keyframe images.
    Full multimodal — sends images directly.
    """
    client = genai.Client(api_key=api_key)

    parts = []
    for frame in frames:
        frame_b64 = frame["image_b64"] if isinstance(frame, dict) else frame
        parts.append(types.Part.from_bytes(
            data=base64.b64decode(frame_b64),
            mime_type="image/jpeg",
        ))

    prompt = GEMINI_EXTRACTION_PROMPT.format(
        metadata=json.dumps(metadata, indent=2),
        transcript_timeline=_format_timeline(transcript_timeline),
        ocr_timeline=_format_timeline(ocr_timeline),
        content_types=prompt_reference(),
    )
    parts.append(types.Part.from_text(text=prompt))

    max_retries = 3
    base_delay_503 = 5
    base_delay_429 = 15

    for attempt in range(max_retries + 1):
        try:
            response = client.models.generate_content(
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
                print(f"  [!] Gemini quota hit (429). Backing off {delay:.1f}s... (Attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                continue

            if is_unavailable and attempt < max_retries:
                delay = (base_delay_503 * (2 ** attempt)) + random.uniform(0, 1)
                print(f"  [!] Gemini busy (503). Retrying in {delay:.1f}s... (Attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                continue

            raise RuntimeError(f"Gemini API call failed: {e}")


# ─── Public interface ────────────────────────────────────────────────────────

def extract_knowledge(
    transcript_timeline: list[TimelineEntry],
    ocr_timeline: list[TimelineEntry],
    frames: list,
    api_key: str,
    source_url: str,
    metadata: dict,
    visual_timeline: list[TimelineEntry] = None,
) -> KnowledgeEntry:
    """
    Main entrypoint. Tries Groq (primary) then falls back to Gemini.

    Parameters:
        transcript_timeline: timestamped speech segments
        ocr_timeline: timestamped on-screen text
        frames: raw keyframe dicts (used only by Gemini fallback)
        api_key: Gemini API key (for fallback)
        source_url: original reel/post URL
        metadata: dict with caption, content_type, source_url
        visual_timeline: timestamped frame descriptions from Florence-2
    """
    # Try primary path: Groq + Llama (text-only)
    groq_key = os.getenv("GROQ_API_KEY", "").strip()
    if groq_key and visual_timeline is not None:
        try:
            print("        Using Groq/Llama 3.3 70B (primary)...")
            return _extract_via_groq(
                transcript_timeline=transcript_timeline,
                ocr_timeline=ocr_timeline,
                visual_timeline=visual_timeline or [],
                source_url=source_url,
                metadata=metadata,
            )
        except RuntimeError as e:
            print(f"        Groq failed: {e}")
            print("        Falling back to Gemini...")

    # Fallback: Gemini with raw images
    print("        Using Gemini 2.5-flash (fallback)...")
    return _extract_via_gemini(
        transcript_timeline=transcript_timeline,
        ocr_timeline=ocr_timeline,
        frames=frames,
        api_key=api_key,
        source_url=source_url,
        metadata=metadata,
    )
