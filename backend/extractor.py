import base64
import os
import cv2


def extract_smart_keyframes(video_path: str, max_frames: int = 12) -> list[dict]:
    """
    Extracts up to max_frames keyframes from a video using a robust two-pass approach.
    Pass 1: Identifies indices of local maxima in frame differencing (scene changes).
    Pass 2: Re-reads the video sequentially to reliably capture the identified frames.
    
    Includes temporal spacing (min 0.75s) to avoid clustering frames.
    """
    if not os.path.exists(video_path):
        raise RuntimeError(f"Video file not found: {video_path}")

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return []

    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    
    # --- Pass 1: Global Motion Analysis ---
    diffs = []
    prev_gray = None
    idx = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Standardize size for comparison to ignore resolution artifacts
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.resize(gray, (320, 180)) # Slightly higher res for better sensitivity

        if prev_gray is not None:
            diff = cv2.absdiff(gray, prev_gray).mean()
            diffs.append((idx, diff))

        prev_gray = gray
        idx += 1

    if not diffs:
        cap.release()
        return []

    # --- Pass 2: Selection Logic (Local Maxima + Temporal Spacing) ---
    # We want local peaks in the 'diff' curve. 
    # A peak indicates the moment of highest change (usually a cut or text pop).
    peaks = []
    for i in range(1, len(diffs) - 1):
        prev_d = diffs[i-1][1]
        curr_d = diffs[i][1]
        next_d = diffs[i+1][1]
        
        if curr_d > prev_d and curr_d > next_d and curr_d > 2.0:
            peaks.append(diffs[i])

    # Sort peaks by intensity (highest change first)
    peaks.sort(key=lambda x: x[1], reverse=True)

    selected_indices = []
    min_frame_dist = int(fps * 0.75) # At least 0.75 seconds apart

    for idx, score in peaks:
        if len(selected_indices) >= max_frames:
            break
            
        # Ensure this frame isn't too close to already selected ones
        if all(abs(idx - s) > min_frame_dist for s in selected_indices):
            selected_indices.append(idx)

    # If we don't have enough peaks, add a few static fallback frames
    if len(selected_indices) < 3:
        total_frames = idx
        for p in [0.2, 0.5, 0.8]:
            f = int(total_frames * p)
            if all(abs(f - s) > min_frame_dist for s in selected_indices):
                selected_indices.append(f)

    selected_indices.sort()

    # --- Pass 3: High-Quality Extraction ---
    # We reset and read sequentially again. Seeking (cap.set) is notoriously 
    # unreliable in many OpenCV/FFmpeg builds for certain MP4 encodings.
    cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
    result = []
    current_idx = 0
    
    for target_idx in selected_indices:
        # Fast-forward to the target
        while current_idx < target_idx:
            cap.grab() # grab() is faster than read() as it skips decoding
            current_idx += 1
        
        ret, frame = cap.read()
        if ret:
            # Encode at high quality
            success, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 90])
            if success:
                result.append({
                    "timestamp_seconds": target_idx / fps,
                    "image_b64": base64.b64encode(buf).decode("utf-8"),
                })
        current_idx += 1

    cap.release()
    return result
