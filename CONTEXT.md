# Insightr — Development Session Context

This file serves as the definitive source of truth and context for the Insightr codebase. It contains the active development state, architectural modifications, UI/UX changes, and instructions for future coding sessions.

> [!IMPORTANT]
> **INSTRUCTION FOR SUBSEQUENT AGENTS:**
> Read this file first before making any changes. As you complete new tasks or make edits to the codebase, **you MUST update this file** to keep the context current and accurate.

---

## 1. Project Overview & Tech Stack
* **Purpose**: Insightr extracts and compiles highly actionable roadmaps, templates, and guides from short-form videos (reels).
* **Backend**: FastAPI (`backend/api.py`), SQLite database (`backend/db.py`), Gemini API client (`backend/llm.py`).
* **Frontend**: Flutter / Dart mobile application (`frontend/insightr_app`).
* **Active Branches**:
  * `main`: Stable release branch with Hugging Face Space Docker configurations.
  * `refactor-note-structure`: Legacy migration branch for dynamic notes.
  * `ui-and-prompt-improvements` **(Active/Current Branch)**: Contains the latest visual upgrades, parser fixes, and prompt hardening.

---

## 2. Architectural Migration: Dynamic Note Blocks
We successfully migrated the codebase from a rigid, legacy 12-feature structure to a dynamic, LLM-driven block layout.
* **Database & Schema**:
  * Legacy columns (Topic Map, What's Missing, Rabbit Hole, estimations) were dropped from `db.py` and `schema.py`.
  * The notes are stored as a serialized JSON list of adaptive `note_blocks` (`block_type`, `title`, `content`).
* **Prompt Instructions (`llm.py`)**:
  * The LLM determines the note structure using 14 standard components (`key_insight`, `text`, `bullets`, `steps`, `checklist`, `stat_row`, `comparison`, `label_values`, `timeline`, `quote`, `code_snippet`, `warning`, `tip`, `divider`).
* **Frontend rendering (`note_block_renderer.dart`)**:
  * Adapts dynamically based on the list of blocks returned. Casing is preserved, and double asterisks (`**`) are parsed into inline bold text spans.

---

## 3. UI/UX Design System: Premium iOS Frosted Glass Theme
We applied a liquid frosted glass aesthetic with physical light refraction throughout the app:
* **frosted cards (`glass_card.dart`)**: 
  * `GlassCard` and `GoldGlassCard` containers wrap their child elements in a `BackdropFilter` with `ImageFilter.blur(sigmaX: 12, sigmaY: 12)`.
  * Solid colors were replaced with a **`LinearGradient` (from `topLeft` to `bottomRight`)** representing light refraction (1.6x alpha highlight at the top-left, 0.4x alpha falloff at the bottom-right).
  * Borders are scaled to a crisp, refractive **`0.8` width** with a boosted highlight opacity.
* **liquid bottom navigation (`bottom_nav.dart`)**:
  * Set `extendBody: true` on the primary `HomeScreen` Scaffold so that all feeds scroll *underneath* the floating navigation bar.
  * Wrapped the nav bar with `BackdropFilter(sigmaX: 16, sigmaY: 16)` and lowered its background container opacity to **60%** (via `.withAlpha(153)`) so scrolling elements blur beautifully beneath it.

---

## 4. Note Blocks Styling Upgrades (`note_block_renderer.dart`)
We structured blocks into a visual hierarchy matching their value:
* **Callouts / Highlights (Left-Border Gold Cards)**:
  * `_KeyInsightBlock`, `_QuoteBlock`, and `_CodeBlock` (copy-pasteable code/prompts) are wrapped in `GoldGlassCard(leftBorderOnly: true)` to command attention.
* **Structured Data Tables (Full-Border Gold Cards)**:
  * `_LabelValuesBlock` (Metadata catalogs) and `_ComparisonBlock` (Two-column tables) use `GoldGlassCard(leftBorderOnly: false)` with golden property labels (`InsightrColors.goldPrimary`) and thin, crisp golden dividers (`InsightrColors.borderGold`) separating rows.
* **Sequential Highlights**:
  * `_TimelineBlock` labels (phases/steps) are colored in `InsightrColors.goldPrimary`.
  * `_StatBox` containers inside grids use `GoldGlassCard(leftBorderOnly: false)`.

---

## 5. Robust Parser Healing (`note_block_renderer.dart` -> `_lines`)
To protect notes from LLM layout errors (e.g. putting list items all on one line), the frontend has a multi-stage parser:
1. **Exclusion Guard**: Code snippets, text, quotes, insights, warnings, and tips are returned raw to protect code syntax (bitwise OR `|`, bash pipes, comments) and formatting.
2. **Pipes Split**: Splits collapsed list structures (like comparisons or stat rows) on pipes (`|`).
3. **Bullet Split**: Splits collapsed list strings containing U+2022 bullet points (`•`) dynamically into clean, individual items (e.g., converting a collapsed single checklist line into separate checkboxes).

---

## 6. Global Artifacts UI Redesign (`deep_insight_screen.dart`)
The "Referenced Artifacts" section at the bottom of the detailed analysis has been transformed into a **collapsible, stateful accordion catalog**:
* All referenced books, papers, courses, datasets, and media are listed inside a single, clean `GlassCard` row.
* Each row displays a custom category icon mapped to its type (e.g. Book icon for books, school hat for courses) and a chevron indicator.
* Tapping a row rotates the chevron and expands via `AnimatedCrossFade` to display a detailed gold catalog containing the **Type**, **Overview (description)**, **Source Link** (underlined), and **Quote** (italicized) separated by golden dividers.

---

## 7. Model Upgrades
* The extraction model in `backend/llm.py` is configured to target **`gemini-3.1-flash-lite`** for high-speed, cost-effective multimodal extraction.
* **Extraction Prompt Sequencing Rules (`llm.py`)**:
  * **Artifact Review Rule**: Prepend a `label_values` metadata catalog block at the start of `note_blocks` if the content reviews any artifact.
  * **Takeaway Rule**: The catalog is only the starting point; subsequent blocks must expand and explain the artifact's actual contents as described in the video.
  * **Extrapolation Rule**: If the video layout is partial (e.g. shows Week 1 of an 8-week plan), the LLM must extrapolate the remaining plan so the user receives a complete end-to-end plan.

---

## 8. Local Testing Copy (`Insightr_local`)
A clean mirroring folder resides at [Insightr_local](file:///Users/vatsal/Downloads/INSIGHTERPROJECT/Insightr_local/).
* **Backend IP Broadcast**: On startup (`python api.py`), the backend automatically broadcasts its local IP address over the network using UDP/mDNS.
* **Android Release APK**: The release testing app is recompiled and stored at:
  `/Users/vatsal/Downloads/INSIGHTERPROJECT/Insightr_local/frontend/insightr_app/build/app/outputs/flutter-apk/app-release.apk`
  This APK allows physical Android devices connected to the same WiFi network to discover and link with the Mac backend instantly.
* **Synchronization**: Always remember to copy all modified files from the main `Insightr` directory to the `Insightr_local` directory and recompile the APK when making frontend updates!
  ```bash
  # Sync shortcut
  cp backend/schema.py ../Insightr_local/backend/schema.py
  cp backend/llm.py ../Insightr_local/backend/llm.py
  cp frontend/insightr_app/lib/core/widgets/note_block_renderer.dart ../Insightr_local/frontend/insightr_app/lib/core/widgets/note_block_renderer.dart
  cp frontend/insightr_app/lib/core/widgets/glass_card.dart ../Insightr_local/frontend/insightr_app/lib/core/widgets/glass_card.dart
  cp frontend/insightr_app/lib/core/widgets/bottom_nav.dart ../Insightr_local/frontend/insightr_app/lib/core/widgets/bottom_nav.dart
  cp frontend/insightr_app/lib/screens/insight_detail/deep_insight_screen.dart ../Insightr_local/frontend/insightr_app/lib/screens/insight_detail/deep_insight_screen.dart
  ```
