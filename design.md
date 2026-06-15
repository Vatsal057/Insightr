# Insightr v2 - Comprehensive Design Specification

This document serves as the primary design specification for building the Insightr Android App. It is derived directly from the `insightr_design.html` Liquid Glass design system.

## 1. Global Design System (Tokens)

### 1.1 Colors (Liquid Glass Theme)
- **Backgrounds**: 
  - Base: `#0e0e06`
  - Dark: `#0d0d06`
  - Card/Surface: `#1e1e10`, `#232314`, `#252514`
- **Primary Accent (Gold)**:
  - Primary: `#c9a84c`
  - Light (Gradients): `#e0bc60`
  - Muted: `#8a6f2e`
  - Glow effects: `rgba(201,168,76,0.18)`
- **Typography Colors**:
  - Primary text: `#f2edd8`
  - Secondary text: `#9a9070`
  - Muted text: `#5a5035`
- **Semantic Colors**:
  - Red (Errors/Now actions): `#e05c4a`
  - Green (Success/Done): `#5c9a6a`
- **Glass / Borders**: 
  - Borders: `rgba(255,255,255,0.06)`
  - Glass Backgrounds: `rgba(255,255,255,0.04)` to `0.07`

### 1.2 Typography
- **Font Family**: `Inter` (or native San Francisco / Roboto equivalent if strictly native, but Inter preferred).
- **Weights**: 
  - Body: 400, 500
  - Headers: 700, 800, 900 (Heavy, tight letter-spacing for large titles, e.g., `-1px` or `-1.5px`).

### 1.3 Shapes, Radii & Effects
- **Radii**: Extensive use of large rounded corners.
  - Buttons/Pills: Fully rounded (`999px`)
  - Cards: `16px` to `20px` (`--radius-lg`, `--radius-xl`)
- **Glassmorphism**: 
  - Background blurs (`backdrop-filter: blur(12px)`) on cards, floating navigation, and dialogs.
  - Subtle inset shadows and 1px semi-transparent white/gold borders to create a "glass edge" effect.

---

## 2. Core Components

### 2.1 Navigation (Liquid Glass Bottom Nav)
- **Style**: Floating pill at the bottom of the screen, not spanning edge-to-edge.
- **Background**: Translucent black with strong background blur.
- **Tabs**: 4 items (Home, Vault, Search, Profile).
- **Active State**: The active tab icon turns Gold (`#c9a84c`), and features a glowing gold line indicator above it and a glowing dot below it.

### 2.2 Buttons
- **Primary Button**: Full width, fully rounded, Gold linear gradient (`#e0bc60` to `#c9a84c`). Text is dark (`#1a1200`). Features a gold drop-shadow.
- **Pill Buttons (Filters)**: Fully rounded, translucent glass background. Active state turns solid Gold.
- **Icon Buttons**: Circular buttons (`40x40`) with a glass background, used for Back buttons and top-right actions.
- **Floating Action Button (FAB)**: Gold gradient, circular, positioned above the bottom nav on the right side.

### 2.3 Tags & Badges
- Small rounded pills used to categorize content.
- Standard format: Low opacity background of a specific color, with border and text of the solid color.
- Variants: Gold (Default), Grey, Green, Purple, Blue.

---

## 3. Screen Breakdown & User Flows

### 3.1 Onboarding Flow
- **01. Splash Screen**:
  - Content: Insightr Logo. Huge title: "Knowledge, Captured." (Captured is gold). Subtitle.
  - Actions: "Get Started" (Primary), "Sign In" (Text link).
- **02. Feature Highlight**:
  - Content: Large central icon. Title: "Every Reel, Structured."
  - Shows a mock "Feature Card" highlighting Key Insights, Actionable to-dos, and Instant search.
- **03. Knowledge Vault Onboard**:
  - Content: Title: "Your Personal Knowledge Vault."
  - Shows a mock preview of saved insights.

### 3.2 Main App Flow
- **04. Home Feed**:
  - Top Bar: User avatar, "Hi [Name]", Notification bell.
  - Title: "Your Vault".
  - Horizontal scrolling filter pills (All, Startup, Fitness, etc.).
  - Content: Vertical list of **Feed Cards** (Insight summaries, tags, effort/time badges, and a highlighted "Top Action").
  - Overlay: FAB to add new links, Bottom Nav.

- **05. Add URL Sheet**:
  - Appears as a modal bottom-sheet over the Home feed.
  - Content: Title "Add a Short". Input field with a paste icon.
  - Quick select platform tags (Instagram, TikTok, YouTube).
  - Action: "Process" button.

- **06. Processing State**:
  - Content: Large glowing animated circle. Title "Building your insight card...".
  - Shows a vertical stepper of states: Downloading -> Transcribing -> Extracting frames -> AI Analysis -> Saving. 
  - Active step has a glowing gold dot.
  - Progress bar at the bottom with a "Cancel" text button.

### 3.3 Details & Deep Dives
- **07. Insight Detail**:
  - Header: Back button, "Your Insights", options icon.
  - Content: Large title, Tags, Effort/Time row.
  - **Do Now Card**: Highlighted card suggesting an immediate action.
  - **Key Insight**: Blockquote styling with gold left-border.
  - **Quick Wins**: Checklist style list of actionable items.
  - Action: "Go Deeper" button.

- **08. Deep Insight (Advanced View)**:
  - Header: "Deep Dive" back button.
  - Content: Topic title, metadata (Read time, Depth, Sources).
  - **Claims Section**: Lists statements categorized by badges: `FACT` (Green), `OPINION` (Blue), `UNVERIFIED` (Orange).
  - **What's Missing**: Highlights `RISK`, `ASSUMPTION`, `TRADE-OFF` using red/purple/blue chips.
  - **Rabbit Hole**: Expandable accordion lists for Questions, Knowledge Gaps, Adjacent Topics.
  - **Knowledge Cards**: Horizontal scrollable list of related theoretical frameworks or models.

### 3.4 Auxiliary Screens
- **09. Search**: Large input field with glass styling. Lists results with timestamps and tags. Includes an "Empty/No Results" variant.
- **10. Knowledge Vault List**: Shows total stats (e.g., total notes, concepts). Grid of collection folders.
- **15. Settings**: Standard list of rows with a leading icon, title, value, and trailing chevron. Includes destructive "danger" rows in red.
- **17. Topic Map**: A visual node-based representation of connected concepts (implies a canvas/graph view).

---

## 4. Android Implementation Notes (Jetpack Compose)
1. **Theming**: Create a robust `Colors` class mapping these specific Hex codes. Avoid default Material themes; rely heavily on custom colors to maintain the dark premium feel.
2. **Modifiers**: Create a custom `Modifier.glassCard()` that handles:
   - `background(Color.White.copy(alpha = 0.04f), shape = RoundedCornerShape(16.dp))`
   - `border(1.dp, Color.White.copy(alpha = 0.06f), shape = RoundedCornerShape(16.dp))`
   - `blur(12.dp)` (Available in Android 12+, use fallbacks for older devices).
3. **Navigation**: Use a `Scaffold` with a custom `bottomBar`. Do not use the default `BottomNavigation`; build a custom `Row` inside a padded `Box` to achieve the floating pill effect.
4. **Typography**: Load the Inter font family. Use `letterSpacing` properties extensively on Headers to match the tight, premium look of the web design.
