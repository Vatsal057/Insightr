# Phase 0 — Design Validation Prototype (THROWAWAY)

This folder is a self-contained, mock-data prototype that validates the
knowledge-network traversal **before** any production code is written. It has
**no backend, no Riverpod, no engines, no persistence** and is **not** part of
the production build (production still uses `lib/main.dart`).

## Run it

```bash
flutter run -t lib/prototype/main_prototype.dart
```

## What it contains

- A five-destination navigation shell (Home · Explore · Capture · Vault · Profile)
  with a distinct, larger gold **Capture** center node. Each destination keeps
  its own navigator so the traversal back-stack is preserved per tab.
- Four real surfaces wired with mock data: **Home**, **Entry Detail**,
  **Connection Detail (Knowledge Pathway)**, **Concept Page** (with a lightweight
  scoped neighborhood graph). Explore/Capture/Vault/Profile are intentional
  placeholders.
- A small interconnected mock graph (AI Agents, Tool Calling, MCP, Agent Memory,
  Agent Planning across 4 entries + 4 connections) in `mock_data.dart`.

## Task 0.2 — Traversal scenarios to walk through

Validate that moving through the network feels natural and that you rarely think
"which tab?". Try at least these:

1. Home → Recently Captured → **Entry** "How AI Agents Actually Work".
2. Entry → tap concept **Tool Calling** → **Concept Page**.
3. Concept Page → Related Entry "MCP in 5 Minutes" → **Entry**.
4. Entry → tap a **Connection** row → **Connection Detail**.
5. Connection Detail → tap a **shared concept** → Concept Page.
6. Connection Detail → tap **Suggested Next Exploration** → Concept Page.
7. Concept Page → Related Concept chip → another **Concept Page** (chain 2–3 deep).
8. Home → **New Connections Discovered** → Connection Detail → an endpoint Entry.
9. From deep in a traversal, use back repeatedly and confirm the path retraces.
10. Switch tabs mid-traversal and return; confirm the stack is preserved.

Record any friction: missing context, confusing hops, or terminology that feels
wrong.

## Task 0.3 — Design Freeze Review (gate)

Production implementation (Task 1 onward) does not start until these are
approved and frozen:

- [ ] Information architecture (the five destinations + four pillars)
- [ ] Navigation model (relationship-following, back-stack behavior)
- [ ] Visual hierarchy (what leads each screen)
- [ ] Terminology (e.g., is it "Concept" or "Topic"? "Connection" or "Pathway"?)

Once approved, this prototype folder is deleted — it is validation, not a base
to build on.
