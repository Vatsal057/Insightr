from fastapi import FastAPI, Request, Form, BackgroundTasks
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse
import uvicorn
import os
import socket
import asyncio
from zeroconf.asyncio import AsyncServiceInfo, AsyncZeroconf

from main import load_config, run_process
import db
import feed
from markdown_export import entry_to_markdown, export_collection

app = FastAPI(title="Vault API")
templates = Jinja2Templates(directory="templates")

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

# Async Zeroconf setup
async_zc: AsyncZeroconf = None

async def register_service():
    global async_zc
    ip = get_ip()
    async_zc = AsyncZeroconf()
    info = AsyncServiceInfo(
        "_insightr._tcp.local.",
        "Insightr Backend._insightr._tcp.local.",
        addresses=[socket.inet_aton(ip)],
        port=8000,
        properties={"version": "1.0"},
        server="insightr.local.",
    )
    await async_zc.async_register_service(info)
    print(f"[*] Registered Zeroconf service at {ip}:8000")
    return info

@app.on_event("startup")
async def startup_event():
    app.state.zc_info = await register_service()

@app.on_event("shutdown")
async def shutdown_event():
    if async_zc:
        await async_zc.async_unregister_service(app.state.zc_info)
        await async_zc.close()

# Simple in-memory store for task status (for MVP purposes)
tasks = {}

def process_video_task(task_id: str, url: str):
    """Background task to run the video processing pipeline."""
    try:
        config = load_config()
        db.init_db(config["db_path"])
        # run_process blocks, which is fine for a background thread
        entry_id = run_process(url, config)
        tasks[task_id] = {"status": "completed", "entry_id": entry_id}
    except Exception as e:
        tasks[task_id] = {"status": "failed", "error": str(e)}

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/api/process")
async def process_video(background_tasks: BackgroundTasks, url: str = Form(...)):
    import uuid
    task_id = str(uuid.uuid4())
    tasks[task_id] = {"status": "processing", "url": url}

    background_tasks.add_task(process_video_task, task_id, url)

    return {"message": "Processing started", "task_id": task_id}

@app.get("/api/status/{task_id}")
async def get_status(task_id: str):
    task = tasks.get(task_id)
    if not task:
        return {"error": "Task not found"}
    return task

@app.get("/api/feed")
async def get_feed(limit: int = 50):
    """Returns the vault feed: a list of compact insight cards, newest first."""
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_entries(config["db_path"], limit=limit)
    cards = []
    for row in rows:
        entry = db.get_entry(config["db_path"], row["id"])
        if entry:
            cards.append(feed.entry_to_summary_card(entry))
    return cards

@app.get("/api/entries/{entry_id}")
async def get_entry(entry_id: int):
    """Returns the full insight card for one entry."""
    config = load_config()
    db.init_db(config["db_path"])
    entry = db.get_entry(config["db_path"], entry_id)
    if not entry:
        return JSONResponse({"error": "Entry not found"}, status_code=404)
    return feed.entry_to_card(entry)

@app.get("/api/concepts")
async def list_concepts(concept_type: str = None, query: str = None):
    """Returns the vault's concept index — recurring ideas across entries."""
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_concepts(config["db_path"], concept_type=concept_type, query=query)
    return [dict(row) for row in rows]

@app.get("/api/concepts/{concept_id}/entries")
async def get_concept_entries(concept_id: int):
    """Returns the entries linked to a given concept."""
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.get_entries_for_concept(config["db_path"], concept_id)
    return [dict(row) for row in rows]

@app.get("/api/search")
async def search(q: str = "", tag: str = None, field: str = None, content_type: str = None):
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.search_entries(config["db_path"], q, tag=tag, field=field, content_type=content_type)
    return [dict(row) for row in rows]


# ---------------------------------------------------------------------------
# Action items / "Todo" — mirrors `main.py todo` / `check`
# ---------------------------------------------------------------------------

@app.get("/api/todo")
async def list_todo(done: bool = None):
    """
    Returns action items across all entries.
    - omit `done` -> all items
    - done=true   -> only completed items
    - done=false  -> only pending items
    """
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_action_items(config["db_path"], done=done)
    return [dict(row) for row in rows]

@app.post("/api/todo/{item_id}/check")
async def check_todo(item_id: int, done: bool = True):
    """Marks an action item done (default) or not done (?done=false)."""
    config = load_config()
    db.init_db(config["db_path"])
    ok = db.set_action_item_done(config["db_path"], item_id, done)
    if not ok:
        return JSONResponse({"error": f"No action item with id #{item_id}"}, status_code=404)
    return {"item_id": item_id, "done": done}


# ---------------------------------------------------------------------------
# Collections — mirrors `main.py collection list` / `collection add`
# ---------------------------------------------------------------------------

@app.get("/api/collections")
async def list_collections():
    """Returns all collections with their entry counts."""
    config = load_config()
    db.init_db(config["db_path"])
    rows = db.list_collections(config["db_path"])
    return [dict(row) for row in rows]

@app.post("/api/collections")
async def add_to_collection(name: str = Form(...), entry_id: int = Form(...)):
    """Adds an entry to a collection (creating the collection if needed)."""
    config = load_config()
    db.init_db(config["db_path"])
    db.add_to_collection(config["db_path"], name, entry_id)
    return {"name": name, "entry_id": entry_id}

@app.get("/api/collections/{name}")
async def get_collection(name: str):
    """Returns the summary cards for every entry in a collection."""
    config = load_config()
    db.init_db(config["db_path"])
    entries = db.get_collection_entries(config["db_path"], name)
    if entries is None:
        return JSONResponse({"error": f"Collection '{name}' not found"}, status_code=404)
    return [feed.entry_to_summary_card(e) for e in entries]


# ---------------------------------------------------------------------------
# Markdown export — mirrors `main.py export`
# ---------------------------------------------------------------------------

@app.get("/api/export/{entry_id}", response_class=PlainTextResponse)
async def export_entry_markdown(entry_id: int):
    """Returns the Markdown rendering of a single entry (Obsidian-flavoured)."""
    config = load_config()
    db.init_db(config["db_path"])
    entry = db.get_entry(config["db_path"], entry_id)
    if not entry:
        return JSONResponse({"error": "Entry not found"}, status_code=404)
    return entry_to_markdown(entry)

@app.get("/api/export/collection/{name}", response_class=PlainTextResponse)
async def export_collection_markdown(name: str):
    """Returns the combined Markdown rendering of a whole collection."""
    config = load_config()
    db.init_db(config["db_path"])
    entries = db.get_collection_entries(config["db_path"], name)
    if entries is None:
        return JSONResponse({"error": f"Collection '{name}' not found"}, status_code=404)
    # Re-use entry_to_markdown via export_collection's logic, but return text directly
    parts = [f"# Collection: {name}", ""]
    for entry in entries:
        parts.append(entry_to_markdown(entry))
        parts.append("\n---\n")
    return "\n".join(parts)


if __name__ == "__main__":
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)
