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


EXTRACTION_PROMPT = """You are a knowledge extraction engine. Your job is to turn a short-form
video or post into a single structured "insight card" for someone's personal
vault — something they can scan in seconds now, and that will still make
sense when they rediscover it months later.

You have been given:
1. A sequence of keyframes (chronological order)
2. A timestamped TRANSCRIPT TIMELINE (what was said, and when)
3. A timestamped ON-SCREEN TEXT TIMELINE (what was shown as text/captions, and when — from OCR)
4. Video/post metadata

Some posts put the most important information ON SCREEN as text rather than
saying it out loud. Treat the on-screen text timeline as equally important
as the transcript — cross-reference both against the keyframes.

CORE GOAL: capture the useful substance, cut everything else. Every field
should be scannable in a few seconds.

RULES:
- Output ONLY a single JSON object matching the required schema. No prose, no markdown fences.
- "title": 3 to 5 words, specific and descriptive.
- "field": one-word category (e.g. "Productivity", "Fitness", "AI").
- "tags": 3-6 lowercase keywords.
- "content_type": pick the ONE type that best describes this content from the list below.
- "type_specific_fields": a list of {{"label": ..., "value": ...}} pairs. Use ONLY the labels
  listed for the content_type you picked (see CONTENT TYPES below). If content_type is "general",
  leave this as an empty list. Keep each "value" short and scannable — bullet-style text with
  newlines is fine within a single value (e.g. for "Steps" or "Pros").

CONTENT TYPES (pick exactly one for "content_type", and use its field labels for "type_specific_fields"):
{content_types}

- "summary.headline": one sentence capturing why this matters.
- "summary.body": a short paragraph expanding on the headline.
- "key_points": the main breakdown. Short, punchy lines separated by newlines, one idea per line. Use
  **bolding** (markdown bold syntax) on the most critical words. No long paragraphs.
- "action_items": concrete, actionable steps the viewer can take. Empty list if none.
- "claims": notable factual/statistical claims made in the content (spoken OR on-screen). Mark each as
  "fact" (verifiable, stated as established truth), "opinion" (the speaker's view),
  or "unverified" (a claim presented as fact but with no evidence given). Empty list if none.
- "explore_further": 2-4 follow-up questions or topics worth exploring further. Empty list if none.
- "topic_map": main_topic (one phrase) + subtopics (2-5 short phrases) covered.
- "referenced_artifacts": ONLY specific, named tools/products/books/templates that the viewer would
  want to look up later (e.g. "Notion", "Atomic Habits", "ChatGPT"). Do NOT include generic mentions
  ("a notes app", "YouTube", "a planner") or anything already covered by type_specific_fields.
  Extract all of them if the content lists multiple — no artificial limit. If a script/template/prompt
  is given verbatim, put it in "snippet" (plain text, no markdown fences). Empty list if none.
- "next_step": 1-2 sentence directive — what the viewer should actually DO with this.
- "concepts": reusable knowledge objects worth remembering beyond this single piece of content —
  named concepts, frameworks, tools, books, people, methodologies, or websites that were explained
  or referenced. For each: "concept_type" (concept/framework/tool/book/person/methodology/website),
  "name" (the proper name, e.g. "AIDA", "Pomodoro Technique", "Atomic Habits"), and "summary"
  (1-2 sentences explaining it in general terms — NOT specific to this video, so it's still useful
  if surfaced again later). Only include things with a real name; skip generic ideas. Empty list if none.

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
    validated KnowledgeEntry (structured JSON).

    Parameters:
        transcript_timeline : list of TimelineEntry from transcriber.transcribe
        ocr_timeline        : list of TimelineEntry from ocr.extract_ocr_timeline
        frames              : list of base64-encoded JPEG strings, OR list of
                              {"image_b64": ...} dicts (as from extractor)
        api_key             : Gemini API key
        source_url          : the original content URL
        metadata            : dict of extra context, e.g. {"caption": ..., "content_type": ...}
    """
    try:
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
        raise RuntimeError(f"Gemini API call failed: {e}")
