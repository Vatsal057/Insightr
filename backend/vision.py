"""
Vision module — describes keyframes using Groq's Llama 4 Scout (multimodal).

Converts visual frames into text descriptions so that text-only LLMs (like Llama 3.3)
can understand the visual context of a reel without receiving raw images during
the main extraction step.

Uses the free Groq API with GROQ_API_KEY.
"""

from __future__ import annotations

import base64
import os

from groq import Groq

from schema import TimelineEntry


def _get_groq_client() -> Groq:
    key = os.getenv("GROQ_API_KEY", "").strip()
    if not key:
        raise RuntimeError("GROQ_API_KEY is not set — needed for vision descriptions.")
    return Groq(api_key=key)


def describe_frame(image_b64: str, client: Groq) -> str:
    """
    Sends a single base64-encoded JPEG frame to Llama 4 Scout via Groq
    and returns a text description of what's visible in the frame.

    Returns an empty string on failure (non-fatal — we still have OCR + transcript).
    """
    try:
        response = client.chat.completions.create(
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"},
                    },
                    {
                        "type": "text",
                        "text": "Describe what you see in this video frame in 1-2 sentences. Focus on: people, text overlays, objects, actions, and setting. Be factual and concise.",
                    },
                ],
            }],
            max_tokens=150,
            temperature=0.2,
        )
        return response.choices[0].message.content.strip()

    except Exception as e:
        print(f"  [Vision] Groq vision request failed: {e}")
        return ""


def describe_frames(frames: list[dict]) -> list[TimelineEntry]:
    """
    Runs Llama 4 Scout on each keyframe and returns a timestamped timeline
    of visual descriptions (same format as OCR timeline for easy integration).

    Parameters:
        frames: list of {"timestamp_seconds": float, "image_b64": str}

    Returns:
        list of TimelineEntry with frame descriptions.
        Skips frames where vision returns empty/fails.
    """
    client = _get_groq_client()
    timeline = []

    for i, frame in enumerate(frames):
        description = describe_frame(frame["image_b64"], client)

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
