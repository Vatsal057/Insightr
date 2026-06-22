"""
Vision module — describes keyframes using Florence-2 via the Hugging Face Inference API.

Converts visual frames into text descriptions so that text-only LLMs (like Llama)
can understand the visual context of a reel without receiving raw images.

Uses the free HF Serverless Inference API with your HF_TOKEN.
"""

from __future__ import annotations

import base64
import os
import requests

from schema import TimelineEntry


HF_API_URL = "https://router.hugging-face.cn/models/microsoft/Florence-2-large"


def _get_hf_token() -> str:
    token = os.getenv("HF_TOKEN", "").strip()
    if not token:
        raise RuntimeError("HF_TOKEN is not set in .env — needed for Florence-2 vision API.")
    return token


def describe_frame(image_b64: str, hf_token: str) -> str:
    """
    Sends a single base64-encoded JPEG frame to Florence-2 and returns
    a text description of what's visible in the frame.

    Returns an empty string on failure (non-fatal — we still have OCR + transcript).
    """
    headers = {
        "Authorization": f"Bearer {hf_token}",
        "Content-Type": "application/json",
    }

    # Florence-2 accepts base64 image + a task prompt
    payload = {
        "inputs": {
            "image": image_b64,
            "text": "<MORE_DETAILED_CAPTION>",
        },
    }

    try:
        response = requests.post(HF_API_URL, headers=headers, json=payload, timeout=30)

        if response.status_code == 200:
            result = response.json()
            # Florence-2 returns generated text in various formats
            if isinstance(result, list) and len(result) > 0:
                # Typical format: [{"generated_text": "..."}]
                if isinstance(result[0], dict):
                    return result[0].get("generated_text", "")
                return str(result[0])
            elif isinstance(result, dict):
                return result.get("generated_text", "") or result.get("<MORE_DETAILED_CAPTION>", "")
            return str(result) if result else ""

        elif response.status_code == 503:
            # Model is loading — could retry but we'll just skip this frame
            return ""
        else:
            print(f"  [Vision] Florence-2 returned {response.status_code} for a frame")
            return ""

    except Exception as e:
        print(f"  [Vision] Florence-2 request failed: {e}")
        return ""


def describe_frames(frames: list[dict]) -> list[TimelineEntry]:
    """
    Runs Florence-2 on each keyframe and returns a timestamped timeline
    of visual descriptions (same format as OCR timeline for easy integration).

    Parameters:
        frames: list of {"timestamp_seconds": float, "image_b64": str}

    Returns:
        list of TimelineEntry with frame descriptions.
        Skips frames where Florence-2 returns empty/fails.
    """
    hf_token = _get_hf_token()
    timeline = []

    for i, frame in enumerate(frames):
        description = describe_frame(frame["image_b64"], hf_token)

        if description and len(description.strip()) > 5:
            timestamp_seconds = frame.get("timestamp_seconds", float(i))
            minutes = int(timestamp_seconds) // 60
            secs = int(timestamp_seconds) % 60
            timestamp = f"{minutes:02d}:{secs:02d}"

            timeline.append(TimelineEntry(
                timestamp=timestamp,
                text=description.strip(),
            ))

    return timeline
