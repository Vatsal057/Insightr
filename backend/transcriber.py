import subprocess
from faster_whisper import WhisperModel

from ocr import format_timestamp
from schema import TimelineEntry


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


def transcribe(audio_path: str, model_size: str = "base") -> list[TimelineEntry]:
    """
    Transcribes audio to a timestamped timeline using faster-whisper running
    locally. No API calls are made. All processing happens on this machine.

    Parameters:
        audio_path : path to the .mp3 audio file
        model_size : whisper model to use — "tiny", "base", "small", or "medium"
                     "base" is the default: good balance of speed and accuracy
                     First run will download model weights automatically (~150 MB for base)

    Returns:
        list of TimelineEntry, one per speech segment, in chronological order.
        Returns [] if no speech was detected.

    Raises:
        RuntimeError if transcription fails
    """
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
        raise RuntimeError(f"Transcription failed: {e}")

    return timeline


def timeline_to_text(timeline: list[TimelineEntry]) -> str:
    """Flattens a timeline into a single string (used for FTS indexing)."""
    return " ".join(entry.text for entry in timeline)
