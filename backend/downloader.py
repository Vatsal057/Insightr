import os
import time
import yt_dlp
import instaloader
from typing import List, Union, Tuple

import requests

def download_content(url: str, output_path: str, cookies_path: str = None) -> Tuple[str, Union[str, List[str]], str]:
    """
    Downloads content from the given URL. 
    First tries keyless public resolvers (vidssave, savethevideo, anyvidsave, igreelsdl).
    Then tries RapidAPI (if RAPIDAPI_KEY is configured).
    Then falls back to local yt-dlp and instaloader.

    Returns:
        (type, data, caption) 
        type: "video" or "images"
        data: path to .mp4 OR list of paths to images
        caption: text caption of the post
    """
    # 1. Try free keyless resolvers first
    print("  [Downloader] Attempting keyless download via vidssave.com...")
    res = _download_vidssave(url, output_path)
    if res:
        video_path, caption = res
        return "video", video_path, caption
    print("  [Downloader] Keyless vidssave download failed/rate-limited. Trying savethevideo.com...")

    print("  [Downloader] Attempting keyless download via savethevideo.com...")
    res = _download_savethevideo(url, output_path)
    if res:
        video_path, caption = res
        return "video", video_path, caption
    print("  [Downloader] Keyless savethevideo download failed/rate-limited. Trying saveig.in...")

    print("  [Downloader] Attempting keyless download via saveig.in...")
    res = _download_saveig(url, output_path)
    if res:
        video_path, caption = res
        return "video", video_path, caption
    print("  [Downloader] Keyless saveig download failed/rate-limited. Trying downloadgram.org...")

    print("  [Downloader] Attempting keyless download via downloadgram.org...")
    res = _download_downloadgram(url, output_path)
    if res:
        video_path, caption = res
        return "video", video_path, caption
    print("  [Downloader] Keyless downloadgram download failed/rate-limited. Trying anyvidsave.in...")

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

def _download_vidssave(url: str, output_path: str) -> Union[Tuple[str, str], None]:
    """Resolves URL using the public vidssave.com API."""
    api_url = "https://api.vidssave.com/api/contentsite_api/media/parse"
    headers = {
        "accept": "*/*",
        "accept-language": "en-US,en;q=0.9",
        "content-type": "application/x-www-form-urlencoded",
        "origin": "https://vidssave.com",
        "referer": "https://vidssave.com/",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    data = {
        "auth": "20250901majwlqo",
        "domain": "api-ak.vidssave.com",
        "origin": "source",
        "link": url
    }
    try:
        response = requests.post(api_url, headers=headers, data=data, timeout=20)
        if response.status_code == 200:
            res_json = response.json()
            media_data = res_json.get("data", {})
            caption = media_data.get("title", "")
            resources = media_data.get("resources", [])
            if resources:
                download_url = resources[0].get("download_url")
                if download_url:
                    print(f"  [Downloader] Got direct link from vidssave: {download_url[:60]}...")
                    video_response = requests.get(download_url, stream=True, headers={"user-agent": headers["user-agent"]}, timeout=60)
                    if video_response.status_code == 200:
                        with open(output_path, "wb") as f:
                            for chunk in video_response.iter_content(chunk_size=8192):
                                if chunk:
                                    f.write(chunk)
                        if os.path.exists(output_path):
                            return output_path, caption
                    else:
                        print(f"[Downloader] vidssave download failed with stream status: {video_response.status_code}")
            else:
                print(f"[Downloader] vidssave api did not return resources: {res_json}")
        else:
            print(f"[Downloader] vidssave api post failed with status: {response.status_code}, content: {response.text}")
    except Exception as e:
        print(f"[Downloader] vidssave helper failed with error: {e}")
    return None

def _download_savethevideo(url: str, output_path: str) -> Union[Tuple[str, str], None]:
    """Resolves URL using the public savethevideo.com API by polling task status."""
    api_url = "https://api.v02.savethevideo.com/tasks"
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "origin": "https://www.savethevideo.com",
        "referer": "https://www.savethevideo.com/",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
    }
    payload = {
        "type": "info",
        "url": url
    }
    
    def download_from_result(result_list: list) -> Union[Tuple[str, str], None]:
        if not result_list:
            print("[Downloader] savethevideo task result is empty.")
            return None
        video_url = result_list[0].get("url")
        caption = result_list[0].get("description") or result_list[0].get("title", "")
        if not video_url:
            print("[Downloader] savethevideo completed task has no video url in result.")
            return None
        print(f"  [Downloader] Got direct link from savethevideo: {video_url[:60]}...")
        video_response = requests.get(video_url, stream=True, timeout=60)
        if video_response.status_code == 200:
            with open(output_path, "wb") as f:
                for chunk in video_response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            if os.path.exists(output_path):
                return output_path, caption
        else:
            print(f"[Downloader] savethevideo download failed with stream status: {video_response.status_code}")
        return None

    try:
        response = requests.post(api_url, headers=headers, json=payload, timeout=20)
        if response.status_code == 200:
            # Task is already completed
            res_json = response.json()
            if res_json.get("state") == "completed":
                return download_from_result(res_json.get("result", []))
            else:
                print(f"[Downloader] savethevideo task creation returned 200 but state is {res_json.get('state')}")
        elif response.status_code == 202:
            res_json = response.json()
            task_id = res_json.get("id")
            if not task_id:
                print("[Downloader] savethevideo task created but no task ID was returned.")
                return None
                
            poll_url = f"https://api.v02.savethevideo.com/tasks/{task_id}"
            print(f"[Downloader] Polling savethevideo task: {poll_url}")
            for i in range(15):
                poll_resp = requests.get(poll_url, headers={"accept": "application/json", "referer": "https://www.savethevideo.com/"}, timeout=15)
                print(f"[Downloader] Poll attempt {i+1} status: {poll_resp.status_code}")
                if poll_resp.status_code == 200:
                    poll_json = poll_resp.json()
                    state = poll_json.get("state")
                    print(f"[Downloader] Task state: {state}")
                    if state == "completed":
                        return download_from_result(poll_json.get("result", []))
                    elif state == "failed":
                        print("[Downloader] savethevideo task failed on remote server.")
                        return None
                else:
                    print(f"[Downloader] savethevideo task polling failed with status: {poll_resp.status_code}")
                time.sleep(2)
        else:
            print(f"[Downloader] savethevideo task creation failed with status: {response.status_code}, content: {response.text}")
    except Exception as e:
        print(f"[Downloader] savethevideo helper failed with error: {e}")
    return None

def _download_saveig(url: str, output_path: str) -> Union[Tuple[str, str], None]:
    """
    Resolves URL using the public saveig.in API.

    Args:
        url: The Instagram Reel/Post URL to download.
        output_path: The file path where the video should be saved.

    Returns:
        A tuple of (output_path, caption) if successful, otherwise None.
    """
    import re
    api_url = "https://saveig.in/wp-json/visolix/api/download"
    headers = {
        "accept": "application/json, text/plain, */*",
        "content-type": "application/json",
        "origin": "https://saveig.in",
        "referer": "https://saveig.in/fastdl/",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
    }

    payload = {
        "url": url,
        "format": "",
        "captcha_response": None
    }

    try:
        response = requests.post(api_url, headers=headers, json=payload, timeout=20)
        if response.status_code != 200:
            print(f"[Downloader] saveig.in POST returned status code {response.status_code}: {response.text}")
            return None

        res_json = response.json()
        if not res_json.get("status"):
            print(f"[Downloader] saveig.in API returned failure status: {res_json}")
            return None

        html_content = res_json.get("data", "")
        match = re.search(r'href=["\']([^"\']*dl\.php\?id=[a-zA-Z0-9]+)["\']', html_content)
        if not match:
            print("[Downloader] saveig.in could not find download link in HTML response data.")
            return None

        dl_url = match.group(1)
        if dl_url.startswith("/"):
            dl_url = "https://saveig.in" + dl_url
        elif dl_url.startswith("../"):
            dl_url = "https://saveig.in/wp-content/plugins/visolix-video-downloader/" + dl_url
        elif not dl_url.startswith("http"):
            dl_url = "https://saveig.in/wp-content/plugins/visolix-video-downloader/includes/" + dl_url

        dl_url = dl_url.replace("/includes/../", "/")

        print(f"  [Downloader] Got proxy link from saveig: {dl_url[:60]}...")
        video_resp = requests.get(dl_url, stream=True, headers={"user-agent": headers["user-agent"]}, timeout=60)
        if video_resp.status_code != 200:
            print(f"[Downloader] saveig.in proxy stream returned status code {video_resp.status_code}")
            return None

        with open(output_path, "wb") as f:
            for chunk in video_resp.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)

        # Verify the file was written and is not empty
        if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
            return output_path, ""
        else:
            print(f"[Downloader] saveig.in downloaded file at {output_path} is empty or missing.")

    except requests.RequestException as e:
        print(f"[Downloader] saveig.in HTTP request failed: {e}")
    except ValueError as e:
        print(f"[Downloader] saveig.in response was not valid JSON: {e}")
    except Exception as e:
        print(f"[Downloader] saveig.in helper failed with unexpected error: {e}")

    return None

def _download_downloadgram(url: str, output_path: str) -> Union[Tuple[str, str], None]:
    """
    Resolves URL using the public downloadgram.org API.

    Args:
        url: The Instagram Reel/Post URL to download.
        output_path: The file path where the video should be saved.

    Returns:
        A tuple of (output_path, caption) if successful, otherwise None.
    """
    import re
    api_url = "https://api.downloadgram.org/media"
    headers = {
        "accept": "*/*",
        "content-type": "application/x-www-form-urlencoded",
        "origin": "https://downloadgram.org",
        "referer": "https://downloadgram.org/",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
    }

    payload = {
        "url": url,
        "v": "3",
        "lang": "en"
    }

    try:
        response = requests.post(api_url, headers=headers, data=payload, timeout=20)
        if response.status_code != 200:
            print(f"[Downloader] downloadgram.org POST returned status code {response.status_code}: {response.text}")
            return None

        # Search for CDN download URLs in the response
        matches = re.findall(r'https://cdn\.downloadgram\.org/\?token=[a-zA-Z0-9_\-\.]+', response.text)
        if not matches:
            print("[Downloader] downloadgram.org could not find CDN link in response.")
            return None

        # Usually, the last token is the video stream link.
        dl_url = matches[-1]
        print(f"  [Downloader] Got direct link from downloadgram: {dl_url[:60]}...")

        video_resp = requests.get(dl_url, headers={"user-agent": headers["user-agent"]}, stream=True, timeout=60)
        if video_resp.status_code != 200:
            print(f"[Downloader] downloadgram.org stream returned status code {video_resp.status_code}")
            return None

        with open(output_path, "wb") as f:
            for chunk in video_resp.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)

        # Verify the file was written and is not empty
        if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
            return output_path, ""
        else:
            print(f"[Downloader] downloadgram.org downloaded file at {output_path} is empty or missing.")

    except requests.RequestException as e:
        print(f"[Downloader] downloadgram.org HTTP request failed: {e}")
    except Exception as e:
        print(f"[Downloader] downloadgram.org helper failed with unexpected error: {e}")

    return None

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
