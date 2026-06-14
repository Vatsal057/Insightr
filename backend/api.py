"""
Insightr FastAPI backend — all 12 insight features exposed as clean REST endpoints.

Endpoint map (for frontend agents):
  POST /api/process                    → start processing a URL (async)
  GET  /api/status/{task_id}           → poll processing status
  GET  /api/feed                       → list of summary cards (newest first)
  GET  /api/entries/{id}               → full insight card (all 12 features)
  GET  /api/entries/{id}/deep-research-prompt → on-demand deep research prompt
  POST /api/todo/{id}/check            → mark action item done/undone
  GET  /api/todo                       → all action items (filterable)
  GET  /api/search                     → full-text search
  GET  /api/concepts                   → knowledge card vault index
  GET  /api/concepts/{id}/entries      → entries linked to a concept
  GET  /api/collections                → list all collections
  POST /api/collections                → create/add to collection
  GET  /api/collections/{name}         → entries in a collection
  GET  /api/export/{id}                → Markdown export (single entry)
  GET  /api/export/collection/{name}   → Markdown export (full collection)
"""

from fastapi import FastAPI, Request, Form, BackgroundTasks
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse
import uvicorn
import os
import socket
import asyncio

try:
    from zeroconf.asyncio import AsyncServiceInfo, AsyncZeroconf
    ZEROCONF_AVAILABLE = True
except ImportError:
    ZEROCONF_AVAILABLE = False

from main import load_config, run_process
import db
import feed
from markdown_export import entry_to_markdown

app = FastAPI(
    title="Insightr API",
    description="Transform short-form content into structured knowledge — 12 insight features.",
    version="2.0.0",
)

templates = Jinja2Templates(directory="templates")


def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


async_zc = None


async def register_zeroconf():
    global async_zc
    if not ZEROCONF_AVAILABLE:
        return None
    ip = get_ip()
    async_zc = AsyncZeroconf()
    info = AsyncServiceInfo(
        "_insightr._tcp.local.",
        "Insightr Backend._insightr._tcp.local.",
        addresses=[socket.inet_aton(ip)],
        port=8000,
        properties={"version": "2.0"},
        server="insightr.local.",
    )
    await async_zc.async_register_service(info)
    print(f"[*] Registered Zeroconf service at {ip}:8000")
    return info


@app.on_event("startup")
async def startup_event():
    app.state.zc_info = await register_zeroconf()


@app.on_event("shutdown")
async def shutdown_event():
    if async_zc and hasattr(app.state, "zc_info") and app.state.zc_info:
        await async_zc.async_unregister_service(app.state.zc_info)
        await async_zc.close()


# Simple in-memory task store (fine for MVP; swap for Redis/Celery later)
tasks: dict = {}


def _process_task(task_id: str, url: str):
    try:
        config = load_config()
        db.init_db(config["db_path"])
        entry_id = run_process(url, config)
        tasks[task_id] = {"status": "completed", "entry_id": entry_id}
    except Exception as e:
        tasks[task_id] = {"status": "failed", "error": str(e)}


# ── Processing ──────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/api/process", summary="Start processing a URL")
async def process_url(background_tasks: BackgroundTasks, url: str = Form(...)):
    """
    Starts the full pipeline (download → transcribe → OCR → LLM extraction)
    for a reel or post URL. Returns a task_id to poll.
    """
    import uuid
    task_id = str(uuid.uuid4())
    tasks[task_id] = {"status": "processing", "url": url}
    background_tasks.add_task(_process_task, task_id, url)
    return {"task_id": task_id, "status": "processing", "url": url}


@app.get("/api/status/{task_id}", summary="Poll processing status")
async def get_status(task_id: str):
    """
    Returns current status of a processing task.
    status: "processing" | "completed" | "failed"
    On completion, entry_id is included.
    """
    task = tasks.get(task_id)
    if not task:
        return JSONResponse({"error": "Task not found"}, status_code=404)
    return task


# ── Feed & Entry Detail ─────────────────────────────────────────────────────

@app.get("/api/feed", summary="Get feed of processed insights")
async def get_feed(limit: int = 50):
    """
    Returns compact summary cards for the feed/list view, newest first.
    Each card includes action_item_count, implementation_step_count,
    tool_count, and effort_estimation for the feed UI chips.
    """
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_entries(config["db_path"], limit=limit)
    cards = []
    for row in rows:
        entry = db.get_entry(config["db_path"], row["id"])
        if entry:
            cards.append(feed.entry_to_summary_card(entry))
    return cards


@app.get("/api/entries/{entry_id}", summary="Get full insight card")
async def get_entry(entry_id: int):
    """
    Returns the complete insight card for one entry — all 12 features:
      core_takeaway, action_items, implementation_plan, claims,
      tools_resources, rabbit_hole, knowledge_cards, referenced_artifacts,
      topic_map, effort_estimation, missing_context, connections.
    Note: deep_research_prompt is excluded here; use the dedicated endpoint.
    """
    config = load_config()
    db.init_db(config["db_path"])
    entry = db.get_entry(config["db_path"], entry_id)
    if not entry:
        return JSONResponse({"error": "Entry not found"}, status_code=404)
    return feed.entry_to_card(entry)


@app.get("/api/entries/{entry_id}/deep-research-prompt",
         summary="Get deep research prompt for an entry (Feature 6)")
async def get_deep_research_prompt(entry_id: int):
    """
    Returns the pre-generated deep research prompt for this entry.
    This is a reusable LLM prompt the user can paste into any AI assistant
    for deeper research. Delivered on-demand to keep the main card payload lean.
    """
    config = load_config()
    db.init_db(config["db_path"])
    prompt = db.get_deep_research_prompt(config["db_path"], entry_id)
    if prompt is None:
        return JSONResponse({"error": "No deep research prompt for this entry"}, status_code=404)
    return {"entry_id": entry_id, "deep_research_prompt": prompt}


# ── Action Items (Feature 2) ────────────────────────────────────────────────

@app.get("/api/todo", summary="List action items across all entries")
async def list_todo(done: bool = None):
    """
    Returns action items. Filter by done=true/false or omit for all.
    """
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_action_items(config["db_path"], done=done)
    return [dict(row) for row in rows]


@app.post("/api/todo/{item_id}/check", summary="Toggle action item completion")
async def check_todo(item_id: int, done: bool = True):
    """Marks an action item done (default) or pending (?done=false)."""
    config = load_config()
    db.init_db(config["db_path"])
    ok = db.set_action_item_done(config["db_path"], item_id, done)
    if not ok:
        return JSONResponse({"error": f"No action item #{item_id}"}, status_code=404)
    return {"item_id": item_id, "done": done}


# ── Search ──────────────────────────────────────────────────────────────────

@app.get("/api/search", summary="Full-text search across the vault")
async def search(q: str = "", tag: str = None, field: str = None, content_type: str = None):
    """
    FTS5 search across title, summary, key points, claims, tags, and tool names.
    Supports optional filters: tag, field, content_type.
    """
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.search_entries(config["db_path"], q, tag=tag, field=field, content_type=content_type)
    return [dict(row) for row in rows]


# ── Knowledge Cards / Concepts (Feature 7) ──────────────────────────────────

@app.get("/api/concepts", summary="Browse the knowledge card vault")
async def list_concepts(concept_type: str = None, query: str = None):
    """
    Returns the deduplicated concept index — recurring frameworks, tools,
    books, and ideas extracted across all entries.
    concept_type: concept | framework | tool | book | person | methodology | website
    """
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_concepts(config["db_path"], concept_type=concept_type, query=query)
    return [dict(row) for row in rows]


@app.get("/api/concepts/{concept_id}/entries", summary="Entries linked to a concept")
async def get_concept_entries(concept_id: int):
    """Returns all entries where this knowledge card appears."""
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.get_entries_for_concept(config["db_path"], concept_id)
    return [dict(row) for row in rows]


# ── Collections ─────────────────────────────────────────────────────────────

@app.get("/api/collections", summary="List all collections")
async def list_collections():
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_collections(config["db_path"])
    return [dict(row) for row in rows]


@app.post("/api/collections", summary="Add entry to a collection")
async def add_to_collection(name: str = Form(...), entry_id: int = Form(...)):
    """Creates the collection if it doesn't exist, then adds the entry."""
    config = load_config()
    db.init_db(config["db_path"])
    db.add_to_collection(config["db_path"], name, entry_id)
    return {"name": name, "entry_id": entry_id}


@app.get("/api/collections/{name}", summary="Get entries in a collection")
async def get_collection(name: str):
    config = load_config()
    db.init_db(config["db_path"])
    entries = db.get_collection_entries(config["db_path"], name)
    if not entries and entries is not None:
        return []
    if entries is None:
        return JSONResponse({"error": f"Collection '{name}' not found"}, status_code=404)
    return [feed.entry_to_summary_card(e) for e in entries]


# ── Markdown Export ─────────────────────────────────────────────────────────

@app.get("/api/export/{entry_id}", response_class=PlainTextResponse,
         summary="Export entry as Obsidian-flavoured Markdown")
async def export_entry_md(entry_id: int):
    config = load_config()
    db.init_db(config["db_path"])
    entry = db.get_entry(config["db_path"], entry_id)
    if not entry:
        return JSONResponse({"error": "Entry not found"}, status_code=404)
    return entry_to_markdown(entry)


@app.get("/api/export/collection/{name}", response_class=PlainTextResponse,
         summary="Export full collection as Markdown")
async def export_collection_md(name: str):
    config = load_config()
    db.init_db(config["db_path"])
    entries = db.get_collection_entries(config["db_path"], name)
    if not entries:
        return JSONResponse({"error": f"Collection '{name}' not found or empty"}, status_code=404)
    parts = [f"# Collection: {name}", ""]
    for entry in entries:
        parts.append(entry_to_markdown(entry))
        parts.append("\n---\n")
    return "\n".join(parts)


if __name__ == "__main__":
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)
