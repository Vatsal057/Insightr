import os
import yt_dlp
import instaloader
from typing import List, Union, Tuple

import requests

def download_content(url: str, output_path: str, cookies_path: str = None) -> Tuple[str, Union[str, List[str]], str]:
    """
    Downloads content from the given URL. 
    First tries keyless public resolver (anyvidsave).
    Then tries RapidAPI (if RAPIDAPI_KEY is configured).
    Then falls back to local yt-dlp and instaloader.

    Returns:
        (type, data, caption) 
        type: "video" or "images"
        data: path to .mp4 OR list of paths to images
        caption: text caption of the post
    """
    # 1. Try free keyless resolver (anyvidsave) first
    print("  [Downloader] Attempting keyless download via anyvidsave.in...")
    res = _download_anyvidsave(url, output_path)
    if res:
        video_path, caption = res
        return "video", video_path, caption
    print("  [Downloader] Keyless anyvidsave download failed/rate-limited. Trying keyless igreelsdl...")

    # 1b. Try fallback free keyless resolver (igreelsdl)
    print("  [Downloader] Attempting keyless download via igreelsdl.com...")
    res = _download_igreelsdl(url, output_path)
    if res:
        video_path, caption = res
        return "video", video_path, caption
    print("  [Downloader] Keyless download failed/rate-limited. Trying alternatives...")

    # 2. Try RapidAPI next if key is configured
    rapidapi_key = os.getenv("RAPIDAPI_KEY", "").strip()
    if rapidapi_key:
        print("  [Downloader] Attempting RapidAPI download to bypass cloud block...")
        res = _download_rapidapi(url, output_path, rapidapi_key)
        if res:
            video_path, caption = res
            return "video", video_path, caption
        print("  [Downloader] RapidAPI download failed or unsupported. Falling back to local tools...")

    # 3. Try yt-dlp (for videos/reels)
    video_res = _download_yt_dlp(url, output_path, cookies_path)
    if video_res:
        video_path, caption = video_res
        return "video", video_path, caption

    # 4. Try Instaloader (for carousels/images)
    if "instagram.com" in url:
        image_res = _download_instaloader(url)
        if image_res:
            image_paths, caption = image_res
            return "images", image_paths, caption

    raise RuntimeError(f"Could not download content from {url} using any available method.")

def _download_anyvidsave(url: str, output_path: str) -> Union[Tuple[str, str], None]:
    """Resolves URL using the public anyvidsave.in API."""
    api_url = "https://anyvidsave.in/download.php"
    headers = {
        "Content-Type": "application/json",
        "Origin": "https://anyvidsave.in",
        "Referer": "https://anyvidsave.in/",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    data = {"url": url}
    try:
        response = requests.post(api_url, headers=headers, json=data, timeout=15)
        if response.status_code == 200:
            res_json = response.json()
            if res_json.get("success") and not res_json.get("limit_reached"):
                media_data = res_json.get("data", {})
                caption = media_data.get("title", "")
                links = media_data.get("links", [])
                
                # Find direct MP4 link
                cdn_url = None
                for link in links:
                    if link.get("type") == "mp4" or "video" in link.get("type", ""):
                        cdn_url = link.get("url")
                        break
                
                if cdn_url:
                    print(f"  [Downloader] Got CDN link from anyvidsave: {cdn_url[:60]}...")
                    # Download direct video from CDN (unblocked)
                    video_response = requests.get(cdn_url, stream=True, timeout=30)
                    if video_response.status_code == 200:
                        with open(output_path, 'wb') as f:
                            for chunk in video_response.iter_content(chunk_size=8192):
                                if chunk:
                                    f.write(chunk)
                        if os.path.exists(output_path):
                            return output_path, caption
    except Exception as e:
        print(f"[Downloader] anyvidsave helper failed: {e}")
    return None

def _download_igreelsdl(url: str, output_path: str) -> Union[Tuple[str, str], None]:
    """Resolves URL using the public igreelsdl.com API."""
    resolve_url = f"https://igreelsdl.com/api/resolve?url={requests.utils.quote(url)}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Referer": "https://igreelsdl.com/"
    }
    try:
        response = requests.get(resolve_url, headers=headers, timeout=15)
        if response.status_code == 200:
            res_json = response.json()
            if res_json.get("success"):
                caption = res_json.get("title", "")
                source_url = res_json.get("sourceUrl", url)
                formats = res_json.get("formats", [])
                
                # Get the best format_id
                format_id = "best"
                if formats:
                    format_id = formats[0].get("formatId", "best")
                
                # Build the proxy download URL
                download_url = (
                    f"https://igreelsdl.com/api/download?"
                    f"url={requests.utils.quote(source_url)}&"
                    f"format_id={requests.utils.quote(format_id)}&"
                    f"filename=instagram-download.mp4&"
                    f"type=video"
                )
                
                print(f"  [Downloader] Got proxy link from igreelsdl: {download_url[:60]}...")
                # Download the proxy stream
                video_response = requests.get(download_url, headers=headers, stream=True, timeout=30)
                if video_response.status_code == 200:
                    with open(output_path, 'wb') as f:
                        for chunk in video_response.iter_content(chunk_size=8192):
                            if chunk:
                                f.write(chunk)
                    if os.path.exists(output_path):
                        return output_path, caption
    except Exception as e:
        print(f"[Downloader] igreelsdl helper failed: {e}")
    return None

def _download_rapidapi(url: str, output_path: str, api_key: str) -> Union[Tuple[str, str], None]:
    """Uses a RapidAPI social media downloader to get the direct unblocked CDN link."""
    endpoint = "https://instagram-downloader-download-instagram-videos-stories.p.rapidapi.com/index"
    headers = {
        "x-rapidapi-key": api_key,
        "x-rapidapi-host": "instagram-downloader-download-instagram-videos-stories.p.rapidapi.com"
    }
    params = {"url": url}
    try:
        response = requests.get(endpoint, headers=headers, params=params, timeout=15)
        if response.status_code == 200:
            data = response.json()
            # The API returns direct CDN link in "media" or "url"
            cdn_url = data.get("media") or data.get("url") or data.get("download_url")
            caption = data.get("caption") or data.get("title") or ""
            
            if cdn_url:
                print(f"  [Downloader] Got CDN link: {cdn_url[:60]}...")
                # Download the direct video stream from the CDN (not blocked by Instagram)
                video_response = requests.get(cdn_url, stream=True, timeout=30)
                if video_response.status_code == 200:
                    with open(output_path, 'wb') as f:
                        for chunk in video_response.iter_content(chunk_size=8192):
                            if chunk:
                                f.write(chunk)
                    if os.path.exists(output_path):
                        return output_path, caption
    except Exception as e:
        print(f"[Downloader] RapidAPI helper failed: {e}")
    return None

def _download_yt_dlp(url: str, output_path: str, cookies_path: str = None) -> Union[Tuple[str, str], None]:
    opts = {
        "format": "bestvideo[ext=mp4]+bestaudio/best",
        "outtmpl": output_path,
        "merge_output_format": "mp4",
        "quiet": True,
        "no_warnings": True,
    }

    if cookies_path and os.path.exists(cookies_path):
        opts["cookiefile"] = cookies_path

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            # Check if video formats exist before downloading
            info = ydl.extract_info(url, download=False)
            caption = info.get('description', '') or info.get('title', '')
            
            if not info.get('formats'):
                return None
            ydl.download([url])
            if os.path.exists(output_path):
                return output_path, caption
    except Exception:
        return None
    return None

def _download_instaloader(url: str) -> Union[Tuple[List[str], str], None]:
    import re
    # Extract shortcode
    match = re.search(r"/(?:p|reels|reel)/([^/?#&]+)", url)
    if not match:
        return None
    
    shortcode = match.group(1)
    loader = instaloader.Instaloader(
        download_pictures=True,
        download_videos=False, # We use yt-dlp for videos
        download_video_thumbnails=False,
        download_geotags=False,
        download_comments=False,
        save_metadata=False,
        compress_json=False,
        dirname_pattern="temp_images"
    )

    try:
        # Cleanup previous temp folder
        import shutil
        if os.path.exists("temp_images"):
            shutil.rmtree("temp_images")
            
        post = instaloader.Post.from_shortcode(loader.context, shortcode)
        caption = post.caption or ""
        loader.download_post(post, target="temp_images")
        
        # Collect image paths
        images = [
            os.path.join("temp_images", f) 
            for f in os.listdir("temp_images") 
            if f.endswith((".jpg", ".png", ".webp"))
        ]
        if images:
            return sorted(images), caption
        return None
    except Exception as e:
        print(f"[Downloader] Instaloader failed: {e}")
        return None

# Keep compatibility for existing calls if any
def download_video(url: str, output_path: str, cookies_path: str = None) -> str:
    res_type, res_data, _ = download_content(url, output_path, cookies_path)
    if res_type == "video":
        return res_data
    raise RuntimeError("Download found images instead of video.")
