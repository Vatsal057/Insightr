# Project Session Context: Insightr

This file maintains the active context, goals, and technical decisions of the **Insightr** project so that any new session or agent knows exactly what is being done, what has been completed, and what to work on next.

---

## 🎯 Active Goal
Deploy the **Insightr** backend to a free cloud hosting service (Hugging Face Spaces) and configure the Flutter frontend release APK to communicate with it, bypassing all Instagram/meta datacenter IP blocks.

---

## 🔄 Deployment & Sync Workflow
Whenever any changes are made to the `backend/` directory in this project root:
1. **Sync changes** to the local Hugging Face deployment clone:
   ```bash
   rsync -av --exclude='.git' --exclude='.env' --exclude='vault.db' --exclude='__pycache__/' --exclude='.venv/' /Users/vatsal/Downloads/INSIGHTERPROJECT/Insightr/backend/ /Users/vatsal/Downloads/INSIGHTERPROJECT/deploy/insightr-backend/
   ```
2. **Commit and push** from the deployment clone to trigger a rebuild on HF:
   ```bash
   cd /Users/vatsal/Downloads/INSIGHTERPROJECT/deploy/insightr-backend
   git add .
   git commit -m "feat/fix: descriptive message"
   git push
   ```
3. **Verify build success** on the Hugging Face Spaces console.

---

## 🚀 Deployment Status
* **Hosting Platform:** Hugging Face Spaces (Docker-based space, free 16GB RAM instance).
* **Space URL:** [Vatxzz/insightr-backend](https://huggingface.co/spaces/Vatxzz/insightr-backend)
* **API Landing Page:** `https://vatxzz-insightr-backend.hf.space`
* **Release APK:** Built pointing to the production URL, located at:
  * [app-release.apk](file:///Users/vatsal/Downloads/INSIGHTERPROJECT/Insightr/frontend/insightr_app/build/app/outputs/flutter-apk/app-release.apk)

---

## 🛠️ Downloader & Resolver Pipeline
To bypass standard datacenter IP bans on Instagram/Meta, we integrated a multi-tiered resolver architecture in [downloader.py](file:///Users/vatsal/Downloads/INSIGHTERPROJECT/Insightr/backend/downloader.py):

1. **`anyvidsave.in` (Primary):** Keyless, free, very fast. Replicates the browser download requests programmatically.
2. **`igreelsdl.com` (Fallback 1):** Keyless, free. Resolves formats and streams the direct download via its own server proxy endpoint.
3. **`RapidAPI` (Fallback 2):** Uses the `RAPIDAPI_KEY` (SiputzX Downloader) if configured in environment secrets. Highly reliable backup.
4. **Local `yt-dlp` (Fallback 3):** Standard python downloader stream (requires cookies on datacenter IPs).
5. **Local `instaloader` (Fallback 4):** Fallback for Instagram image carousels.

---

## 🔍 Investigation Log & Decisions

| Target Site | Status | Notes / Decisions |
| :--- | :--- | :--- |
| **anyvidsave.in** | **ACTIVE** | Works perfectly without Cloudflare challenges or token encryption. |
| **igreelsdl.com** | **ACTIVE** | Resolved successfully. Works cleanly with direct streaming endpoints. |
| **indown.io** | **ABANDONED** | Protected by Cloudflare. Direct backend requests get blocked by the `cf_clearance` cookie challenge. |
| **snapinsta.to** | **ABANDONED** | Returns obfuscated/packed JS (`eval(function(h,u,n...`) inside the AJAX response. Brittle and heavy to evaluate. |
| **fastvideosave.net** | **ABANDONED** | Client-side JS encrypts the URL into a 96-char hex key sent in custom headers. Too fragile. |

---

## ⚠️ Critical Architecture Notes & Gotchas

* **Dynamic API URL (`--dart-define`):** The Flutter app does **not** use a hardcoded production backend URL. It is compiled dynamically by reading `--dart-define=API_BASE_URL=https://vatxzz-insightr-backend.hf.space` in `constants.dart`.
* **Hugging Face Port Bindings:** Hugging Face requires the container to bind to port `7860`. In [api.py](file:///Users/vatsal/Downloads/INSIGHTERPROJECT/Insightr/backend/api.py), we resolve `PORT` from environment variables, defaulting to `7860`.
* **Zeroconf / UDP Broadcast:** The backend has built-in Zeroconf and UDP broadcast discovery (for local dev environments). **Note:** This broadcast discovery is blocked in the Hugging Face cloud environment, which is why we must rely on the explicit `--dart-define` URL in production.
* **Non-Root Write Permissions:** Hugging Face runs containers under user ID `1000` (non-root). Any file read/write operations (SQLite DB, temp files, media downloads) must be written relative to the workspace directory (`/app`) or `/tmp` to avoid permissions errors.
* **Full Python Base Image:** The [Dockerfile](file:///Users/vatsal/Downloads/INSIGHTERPROJECT/Insightr/backend/Dockerfile) uses `python:3.11` instead of `python:3.11-slim` because compiling binary wheels for dependencies (like `faster-whisper`, `ctranslate2`, and `numpy`) requires `build-essential` compilation tools which are missing in slim.

---

## 📋 Next Action Items

- [ ] **Verify HF Space Logs:** Monitor Space building/runtime logs on Hugging Face to ensure no SQLite permissions errors or missing system binaries (like `ffmpeg` or `tesseract-ocr`) crash the worker.
- [ ] **Configure Secrets:** Make sure `GEMINI_API_KEY` and `RAPIDAPI_KEY` (if used) are added as Secrets in the Hugging Face Space settings console.
- [ ] **End-to-End Test:** Run the Flutter APK on a device, paste a reel URL, and verify the full media extraction pipeline (Download $\rightarrow$ OCR $\rightarrow$ Whisper Transcription $\rightarrow$ Gemini Ingestion).
