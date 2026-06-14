import os
import sys
import argparse
import base64
from pathlib import Path
from dotenv import load_dotenv

from downloader import download_content
from transcriber import extract_audio, transcribe, timeline_to_text
from extractor import extract_smart_keyframes
from ocr import extract_ocr_timeline
from llm import extract_knowledge
import db
import connections
from markdown_export import export_entry, export_collection


TEMP_VIDEO = "vault_temp_video.mp4"
TEMP_AUDIO = "vault_temp_audio.mp3"


def cleanup():
    """Removes temporary files created during processing."""
    for path in [TEMP_VIDEO, TEMP_AUDIO]:
        if os.path.exists(path):
            os.remove(path)


def load_config():
    """
    Loads configuration from .env file.
    Returns a dict with keys: gemini_api_key, db_path, export_path, cookies_path.
    Exits with an error message if required values are missing.
    """
    load_dotenv()

    api_key = os.getenv("GEMINI_API_KEY", "").strip()
    db_path = os.getenv("VAULT_DB_PATH", "").strip() or "vault.db"
    export_path = os.getenv("VAULT_EXPORT_PATH", "").strip() or "exports"
    cookies_path = os.getenv("INSTAGRAM_COOKIES_PATH", "").strip()

    errors = []

    if not api_key or api_key == "your_gemini_api_key_here":
        errors.append(
            "  - GEMINI_API_KEY is not set.\n"
            "    Get a free key at https://aistudio.google.com\n"
            "    Then add it to your .env file."
        )

    if errors:
        error_msg = "\n".join(errors)
        raise ValueError(f"Setup required. Fix these issues in your .env file:\n{error_msg}")

    return {
        "gemini_api_key": api_key,
        "db_path": db_path,
        "export_path": export_path,
        "cookies_path": cookies_path if cookies_path else None,
    }


def run_process(url: str, config: dict, export_md: bool = False):
    """
    Main processing pipeline. Downloads, transcribes, extracts keyframes + OCR,
    builds timelines, extracts a structured insight card (entry + concepts),
    stores everything in the database, computes connections, and optionally
    exports a Markdown copy.
    """
    db.init_db(config["db_path"])

    try:
        print(f"\n[Vault] Processing: {url}\n")

        print("  [1/5] Downloading content...")
        content_type, data, caption = download_content(url, TEMP_VIDEO, config["cookies_path"])
        print(f"        Done ({content_type}).")

        frames = []
        transcript_timeline = []

        if content_type == "video":
            print("  [2/5] Extracting audio...")
            extract_audio(TEMP_VIDEO, TEMP_AUDIO)
            print("        Done.")

            print("  [2/5] Extracting keyframes...")
            frames = extract_smart_keyframes(TEMP_VIDEO, max_frames=12)
            print(f"        Found {len(frames)} keyframes.")

            print("  [3/5] Transcribing speech (this may take 30-60 seconds)...")
            transcript_timeline = transcribe(TEMP_AUDIO)
            word_count = len(timeline_to_text(transcript_timeline).split())
            print(f"        Transcribed {word_count} words across {len(transcript_timeline)} segments.")

        else:  # images
            print("  [2/5] Processing images...")
            for idx, img_path in enumerate(data[:15]):
                with open(img_path, "rb") as f:
                    frames.append({
                        "timestamp_seconds": float(idx),
                        "image_b64": base64.b64encode(f.read()).decode("utf-8"),
                    })
            print(f"        Encoded {len(frames)} images.")
            print("  [3/5] Skipping transcription (no audio).")

        print("  [4/5] Running OCR on frames...")
        ocr_timeline = extract_ocr_timeline(frames)
        print(f"        Found on-screen text in {len(ocr_timeline)} frame(s).")

        metadata = {
            "source_url": url,
            "content_type": content_type,
            "caption": caption if caption.strip() else "[No caption available]",
        }

        print(f"  [5/5] Extracting knowledge ({len(frames)} visual signals)...")
        entry = extract_knowledge(
            transcript_timeline=transcript_timeline,
            ocr_timeline=ocr_timeline,
            frames=frames,
            api_key=config["gemini_api_key"],
            source_url=url,
            metadata=metadata,
        )
        print("        Done.")

        # Save to database
        entry_id = db.save_entry(config["db_path"], entry)
        entry.id = entry_id

        # Save concepts (deduplicated against existing concepts)
        if entry.concepts:
            db.save_concepts(config["db_path"], entry_id, entry.concepts)

        # Compute and store connections to existing entries
        related = connections.find_connections(config["db_path"], entry, entry_id)
        db.save_connections(config["db_path"], entry_id, related)
        entry.connections = related

        print(f"\n[Vault] Saved entry #{entry_id}: {entry.title}")
        print(f"            Field: {entry.field} | Type: {entry.content_type} | Tags: {', '.join(entry.tags)}")
        if entry.action_items:
            print(f"            Action items: {len(entry.action_items)}")
        if entry.concepts:
            concept_names = ", ".join(f"{c.name} ({c.concept_type})" for c in entry.concepts)
            print(f"            Concepts: {concept_names}")
        if related:
            print(f"            Related entries: {', '.join(c.title for c in related)}")

        if export_md:
            path = export_entry(entry, config["export_path"])
            print(f"\n[Vault] Exported Markdown to: {path}")

        print()
        return entry_id

    except RuntimeError as e:
        print(f"\n[Vault] Error: {e}\n")
        raise

    finally:
        cleanup()


def cmd_search(args, config):
    rows = db.search_entries(config["db_path"], args.query or "", tag=args.tag, field=args.field, content_type=args.type)
    if not rows:
        print("No matching entries found.")
        return
    for row in rows:
        print(f"#{row['id']:<4} [{row['field']}/{row['content_type']}] {row['title']}  ({row['created_at'][:10]})")


def cmd_todo(args, config):
    done = None
    if args.done:
        done = True
    elif args.pending:
        done = False

    rows = db.list_action_items(config["db_path"], done=done)
    if not rows:
        print("No action items found.")
        return
    for row in rows:
        checkbox = "x" if row["done"] else " "
        print(f"[{checkbox}] (#{row['id']}) {row['text']}   — from #{row['entry_id']} {row['title']}")


def cmd_check(args, config):
    ok = db.set_action_item_done(config["db_path"], args.item_id, not args.uncheck)
    if ok:
        state = "unchecked" if args.uncheck else "checked"
        print(f"Action item #{args.item_id} {state}.")
    else:
        print(f"No action item with id #{args.item_id}.")


def cmd_collection(args, config):
    if args.collection_command == "list":
        rows = db.list_collections(config["db_path"])
        if not rows:
            print("No collections yet.")
            return
        for row in rows:
            print(f"{row['name']}  ({row['entry_count']} entries)")

    elif args.collection_command == "add":
        db.add_to_collection(config["db_path"], args.name, args.entry_id)
        print(f"Added entry #{args.entry_id} to collection '{args.name}'.")


def cmd_concepts(args, config):
    if args.entry_id is not None:
        concepts = db.get_concepts_for_entry(config["db_path"], args.entry_id)
        if not concepts:
            print(f"No concepts linked to entry #{args.entry_id}.")
            return
        for c in concepts:
            print(f"[{c.concept_type}] {c.name}  (#{c.id})")
            print(f"    {c.summary}")
        return

    rows = db.list_concepts(config["db_path"], concept_type=args.type, query=args.query)
    if not rows:
        print("No concepts found.")
        return
    for row in rows:
        print(f"#{row['id']:<4} [{row['concept_type']}] {row['name']}")
        print(f"      {row['summary']}")


def cmd_export(args, config):
    if args.collection:
        entries = db.get_collection_entries(config["db_path"], args.collection)
        if not entries:
            print(f"Collection '{args.collection}' not found or empty.")
            return
        path = export_collection(entries, args.collection, config["export_path"])
        print(f"Exported collection '{args.collection}' to: {path}")
    elif args.entry_id is not None:
        entry = db.get_entry(config["db_path"], args.entry_id)
        if not entry:
            print(f"No entry with id #{args.entry_id}.")
            return
        path = export_entry(entry, config["export_path"])
        print(f"Exported entry #{args.entry_id} to: {path}")
    else:
        print("Specify either an entry id or --collection <name>.")


def main():
    parser = argparse.ArgumentParser(
        prog="vault",
        description="Transform short-form videos into structured knowledge.",
    )
    sub = parser.add_subparsers(dest="command")

    p_process = sub.add_parser("process", help="Process a video/post URL")
    p_process.add_argument("url", type=str, help="The video/post URL")
    p_process.add_argument("--export-md", action="store_true", help="Also export a Markdown copy")

    p_search = sub.add_parser("search", help="Search stored entries")
    p_search.add_argument("query", type=str, nargs="?", default="", help="Full-text search query")
    p_search.add_argument("--tag", type=str, help="Filter by tag")
    p_search.add_argument("--field", type=str, help="Filter by field/category")
    p_search.add_argument("--type", type=str, help="Filter by content type (tutorial/tool_review/...)")

    p_todo = sub.add_parser("todo", help="List action items")
    p_todo.add_argument("--done", action="store_true", help="Show only completed items")
    p_todo.add_argument("--pending", action="store_true", help="Show only pending items")

    p_check = sub.add_parser("check", help="Mark an action item done/undone")
    p_check.add_argument("item_id", type=int, help="Action item id")
    p_check.add_argument("--uncheck", action="store_true", help="Mark as not done")

    p_collection = sub.add_parser("collection", help="Manage collections")
    coll_sub = p_collection.add_subparsers(dest="collection_command")
    coll_sub.add_parser("list", help="List collections")
    p_coll_add = coll_sub.add_parser("add", help="Add an entry to a collection")
    p_coll_add.add_argument("name", type=str, help="Collection name")
    p_coll_add.add_argument("entry_id", type=int, help="Entry id to add")

    p_concepts = sub.add_parser("concepts", help="Browse concepts")
    p_concepts.add_argument("entry_id", type=int, nargs="?", default=None, help="Show concepts linked to this entry")
    p_concepts.add_argument("--type", type=str, help="Filter by concept type (concept/framework/tool/book/person/methodology/website)")
    p_concepts.add_argument("--query", type=str, help="Search concepts by name")

    p_export = sub.add_parser("export", help="Export entry/collection as Markdown")
    p_export.add_argument("entry_id", type=int, nargs="?", default=None, help="Entry id to export")
    p_export.add_argument("--collection", type=str, help="Export an entire collection")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    try:
        config = load_config()
        db.init_db(config["db_path"])

        if args.command == "process":
            run_process(args.url, config, export_md=args.export_md)
        elif args.command == "search":
            cmd_search(args, config)
        elif args.command == "todo":
            cmd_todo(args, config)
        elif args.command == "check":
            cmd_check(args, config)
        elif args.command == "collection":
            cmd_collection(args, config)
        elif args.command == "concepts":
            cmd_concepts(args, config)
        elif args.command == "export":
            cmd_export(args, config)
    except (ValueError, RuntimeError) as e:
        print(f"\n{e}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
