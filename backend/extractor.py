import base64
import os
import cv2


def extract_smart_keyframes(video_path: str, max_frames: int = 12) -> list[dict]:
    """
    Extracts up to max_frames keyframes from a video.
    Uses frame differencing: picks frames where content changes most,
    which captures text overlays, diagrams, and scene transitions.

    Parameters:
        video_path : path to the .mp4 video file
        max_frames : maximum number of frames to return (default 12)

    Returns:
        list of {"timestamp_seconds": float, "image_b64": str}, in
        chronological order. Returns [] if the video cannot be opened.

    Raises:
        RuntimeError if the video file does not exist
    """
    if not os.path.exists(video_path):
        raise RuntimeError(f"Video file not found: {video_path}")

    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        return []

    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0

    candidates = []
    prev_gray = None
    idx = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        if prev_gray is not None:
            diff = cv2.absdiff(gray, prev_gray).mean()
            if diff > 8.0:
                candidates.append((idx, diff, frame.copy()))

        prev_gray = gray
        idx += 1

    cap.release()

    if not candidates:
        return []

    # Sort by difference score descending, keep top N, then re-sort chronologically
    candidates.sort(key=lambda x: x[1], reverse=True)
    top = sorted(candidates[:max_frames], key=lambda x: x[0])

    result = []
    for frame_idx, _, frame in top:
        success, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
        if success:
            result.append({
                "timestamp_seconds": frame_idx / fps,
                "image_b64": base64.b64encode(buf).decode("utf-8"),
            })

    return result
