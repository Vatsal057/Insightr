from fastapi import FastAPI, Request, Form, BackgroundTasks
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, JSONResponse
import uvicorn
import asyncio
import os

from main import load_config, run_process
import db
import feed

app = FastAPI(title="Vault API")
templates = Jinja2Templates(directory="templates")

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

if __name__ == "__main__":
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)
