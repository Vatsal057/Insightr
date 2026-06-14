"""
OCR pipeline.

Runs Tesseract (via pytesseract) on extracted keyframes and produces a
timestamped timeline of on-screen text, e.g.:

    [{"timestamp": "00:04", "text": "Most people fail because..."}, ...]

This is intentionally simple: one OCR pass per keyframe, light cleanup,
and de-duplication of repeated/empty text. No cloud OCR, no GPU models.

Requires the `tesseract-ocr` system package to be installed
(e.g. `sudo apt install tesseract-ocr` or `brew install tesseract`).
"""

from __future__ import annotations

import base64
import io
import re

from schema import TimelineEntry

try:
    import pytesseract
    from PIL import Image
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False


def _clean_text(text: str) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    return text


def format_timestamp(seconds: float) -> str:
    minutes = int(seconds) // 60
    secs = int(seconds) % 60
    return f"{minutes:02d}:{secs:02d}"


def extract_ocr_timeline(frames: list[dict]) -> list[TimelineEntry]:
    """
    Runs OCR over a list of frames and returns a timeline of on-screen text.

    Parameters:
        frames : list of {"timestamp_seconds": float, "image_b64": str}
                 (as produced by extractor.extract_smart_keyframes)

    Returns:
        list of TimelineEntry, one per frame with non-empty/non-duplicate text.
        Returns [] if pytesseract/Tesseract is not available.
    """
    if not OCR_AVAILABLE:
        return []

    timeline = []
    last_text = ""

    for frame in frames:
        try:
            img_bytes = base64.b64decode(frame["image_b64"])
            image = Image.open(io.BytesIO(img_bytes))
            raw_text = pytesseract.image_to_string(image)
        except Exception:
            continue

        text = _clean_text(raw_text)
        if not text or len(text) < 3:
            continue

        # Skip if essentially identical to the previous frame's text.
        # Uses a basic character-overlap check to handle minor OCR noise.
        if last_text:
            longer = max(len(text), len(last_text))
            shorter = min(len(text), len(last_text))
            
            # If the text is very similar to the last one, skip it.
            # (e.g. "Step 1: Python" vs "Step 1: Pyth0n")
            if text == last_text:
                continue
            
            # Simple fuzzy check: if strings are >80% similar, consider them duplicates
            # We don't import a full fuzzy library to keep dependencies low.
            shared = sum(1 for a, b in zip(text, last_text) if a == b)
            if shared / longer > 0.8:
                continue

        timeline.append(TimelineEntry(
            timestamp=format_timestamp(frame["timestamp_seconds"]),
            text=text,
        ))
        last_text = text

    return timeline
