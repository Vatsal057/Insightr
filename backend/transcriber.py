"""
Transcription module.

Primary: HF Inference API (openai/whisper-large-v3-turbo) — free, GPU-accelerated.
Fallback: faster-whisper running locally on CPU.
"""

import os
import subprocess
import requests

from ocr import format_timestamp
from schema import TimelineEntry


HF_WHISPER_URL = "https://router.hugging-face.cn/models/openai/whisper-large-v3-turbo"


def extract_audio(video_path: str, audio_path: str) -> str:
    """
    Extracts the audio track from a video file using ffmpeg.

    Parameters:
        video_path : path to the input .mp4 file
        audio_path : path where the output .mp3 should be saved

    Returns:
        audio_path on success

    Raises:
        RuntimeError if ffmpeg is not installed or extraction fails
    """
    try:
        subprocess.run(
            [
                "ffmpeg", "-i", video_path,
                "-q:a", "0",
                "-map", "a",
                audio_path,
                "-y",
            ],
            check=True,
            capture_output=True,
        )
    except FileNotFoundError:
        raise RuntimeError(
            "ffmpeg is not installed. "
            "Install it with: brew install ffmpeg (Mac) or sudo apt install ffmpeg (Ubuntu)"
        )
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Audio extraction failed: {e.stderr.decode()}")

    return audio_path


def transcribe_hf(audio_path: str) -> list[TimelineEntry]:
    """
    Transcribes audio using HF Inference API (Whisper large-v3-turbo).
    Free, runs on HF GPUs. Returns timestamped segments.

    Returns:
        list of TimelineEntry, or raises RuntimeError on failure.
    """
    hf_token = os.getenv("HF_TOKEN", "").strip()
    if not hf_token:
        raise RuntimeError("HF_TOKEN not set — cannot use HF Whisper.")

    headers = {
        "Authorization": f"Bearer {hf_token}",
    }

    with open(audio_path, "rb") as f:
        audio_data = f.read()

    try:
        response = requests.post(
            HF_WHISPER_URL,
            headers=headers,
            data=audio_data,
            timeout=120,
        )

        if response.status_code == 200:
            result = response.json()
            timeline = []

            # HF Whisper returns {"text": "...", "chunks": [{"timestamp": [start, end], "text": "..."}]}
            chunks = result.get("chunks", [])
            if chunks:
                for chunk in chunks:
                    text = chunk.get("text", "").strip()
                    timestamps = chunk.get("timestamp", [0, 0])
                    start = timestamps[0] if timestamps and timestamps[0] is not None else 0
                    if text:
                        timeline.append(TimelineEntry(
                            timestamp=format_timestamp(start),
                            text=text,
                        ))
            elif result.get("text"):
                # No chunks returned — treat entire text as one segment
                timeline.append(TimelineEntry(
                    timestamp="00:00",
                    text=result["text"].strip(),
                ))

            return timeline

        elif response.status_code == 503:
            raise RuntimeError("HF Whisper model is loading (503). Falling back to local.")
        else:
            raise RuntimeError(f"HF Whisper returned {response.status_code}: {response.text[:200]}")

    except requests.exceptions.Timeout:
        raise RuntimeError("HF Whisper request timed out.")
    except requests.exceptions.ConnectionError as e:
        raise RuntimeError(f"HF Whisper connection error: {e}")


def transcribe_local(audio_path: str, model_size: str = "base") -> list[TimelineEntry]:
    """
    Fallback: transcribes audio using faster-whisper running locally on CPU.
    No API calls. First run downloads model weights (~150 MB for base).
    """
    from faster_whisper import WhisperModel

    try:
        model = WhisperModel(model_size, device="cpu", compute_type="int8")
        segments, _ = model.transcribe(audio_path, beam_size=5)

        timeline = []
        for segment in segments:
            text = segment.text.strip()
            if text:
                timeline.append(TimelineEntry(
                    timestamp=format_timestamp(segment.start),
                    text=text,
                ))
    except Exception as e:
        raise RuntimeError(f"Local transcription failed: {e}")

    return timeline


def transcribe(audio_path: str, model_size: str = "base") -> list[TimelineEntry]:
    """
    Primary entrypoint. Tries HF Whisper API first, falls back to local.
    """
    # Try HF API first
    try:
        print("        Using HF Whisper API (primary)...")
        timeline = transcribe_hf(audio_path)
        if timeline:
            return timeline
        print("        HF Whisper returned empty. Falling back to local...")
    except RuntimeError as e:
        print(f"        HF Whisper failed: {e}")
        print("        Falling back to local whisper...")

    # Fallback to local
    return transcribe_local(audio_path, model_size)


def timeline_to_text(timeline: list[TimelineEntry]) -> str:
    """Flattens a timeline into a single string (used for FTS indexing)."""
    return " ".join(entry.text for entry in timeline)
