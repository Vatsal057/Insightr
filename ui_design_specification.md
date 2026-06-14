# Insightr UI Visual & Design Specification

This document details the visual design system, styling tokens, UI layouts, and component aesthetics of the Insightr interface to allow for pixel-perfect visual reproduction.

---

## 1. Visual Design Tokens

The interface uses a premium dark-mode theme featuring organic charcoal backgrounds, warm cream cards, and bright amber accents.

### Color Palette

| Token Name | Hex Code | Visual Placement |
| :--- | :--- | :--- |
| `BackgroundDark` | `#2A2722` | Base screen background color |
| `BackgroundDarkAlt` | `#3A352D` | Navigation backgrounds, secondary surfaces |
| `Cream` | `#F6F1E7` | Primary card background, active chip background |
| `CreamMuted` | `#EDE6D8` | Secondary card background, inactive checklist circles |
| `Accent` | `#E6A95C` | Highlight text, progress indicators, active borders |
| `AccentSoft` | `#F1C998` | Soft highlights, card icon backgrounds |
| `TextOnDark` | `#F6F1E7` | Primary text on charcoal surfaces |
| `TextOnDarkMuted` | `#C9C3B7` | Subtitles, captions, and secondary text on charcoal |
| `TextOnCream` | `#2A2722` | Primary text on cream surfaces |
| `TextOnCreamMuted` | `#8A8377` | Captions and secondary text on cream surfaces |
| `PillDark` | `#4A453B` | Inactive buttons, secondary chip backgrounds |
| `Success` | `#8FAE7E` | Success badges, green indicator highlights |
| `Danger` | `#D98C7A` | Warning banners, red indicator highlights |

#### Screen Background Gradient
- **Style**: Vertical gradient starting with `BackgroundDarkAlt` (`#3A352D`) at the top, transitioning smoothly to `BackgroundDark` (`#2A2722`) at the bottom.

### Typography Hierarchy
- **Hero Headings**: `44sp` Bold, line height `50sp`.
- **Section Headings**: `26sp` Bold, line height `30sp`.
- **Card Headings**: `19sp` Bold, line height `26sp` / `15sp` Semi-Bold (List item headings).
- **Body Text**: `14sp` Regular, line height `20sp`.
- **Small Labels**: `11sp` to `12sp` Regular / Medium weight.

### Layout Geometry
- **Main Cards & Panels**: `20.dp` to `24.dp` rounded corners.
- **Form Fields & Bottom Bars**: `20.dp` rounded corners.
- **Large Action Buttons**: Pill-shaped (`32.dp` rounded corners).
- **Small Chips & Badges**: `12.dp` to `14.dp` rounded corners.

---

## 2. Component Design Specs

### A. Pill-Shaped Action Button
- **Layout**: Full-width or inline horizontal Row.
- **Visuals**:
  - Background: `PillDark` (or `PillDark` with `0.5` opacity when disabled).
  - Shape: Rounded corners (`32.dp`).
  - Content: Center-left aligned text (`TextOnDark`, `16sp`, Medium weight).
  - Trailing Bubble: A circle (`40.dp`) filled with `Cream` holding a centered right arrow (`ArrowForward`) icon in `TextOnCream`.

### B. Filter Chip
- **Layout**: Horizontal padding box (`18.dp` horizontal, `10.dp` vertical).
- **Visuals**:
  - Shape: Rounded corners (`20.dp`).
  - **Selected State**: Background `Cream`, Text `TextOnCream` (`14sp`, Semi-Bold).
  - **Unselected State**: Background `White` at `0.06` opacity, Text `TextOnDark` (`14sp`, Regular).

### C. Section Header
- **Layout**: Vertical stack (Column).
- **Visuals**:
  - Main Title: Text (`TextOnDark`, `26sp`, Bold).
  - Subtitle (Optional): Text (`TextOnDarkMuted`, `14sp`), placed `4.dp` directly below the title.

### D. Circle Icon Button
- **Layout**: Square circle box (`40.dp` x `40.dp`) with a centered icon.
- **Visuals**:
  - Shape: Circle (`CircleShape`).
  - **Filled Variant**: Background `Cream`, Icon tint `TextOnCream`.
  - **Flat Variant**: Background `PillDark` (`#4A453B`), Icon tint `TextOnDark`.

---

## 3. Screen Layout Specifications

### 1. Onboarding Screen
- **Top Header Bar**:
  - Left: Back button (Circle Icon Button, flat variant).
  - Center: Horizontal row of 3 page indicators. The middle indicator is `8.dp` wide in `Cream`; the outer indicators are `6.dp` wide in `TextOnDarkMuted`.
  - Right: Forward button (Circle Icon Button, filled variant).
- **On-Screen Cards**:
  - Top Floating Card: Rounded corner box (`28.dp` radius) in `Cream` with double-line text (`TextOnCream`, `13sp` Semi-Bold).
  - Mid-Right Card: Rounded corner box (`28.dp` radius) in `PillDark` at `0.85` opacity with double-line right-aligned text (`TextOnDark`, `13sp` Medium).
- **Typography Section**:
  - Main Heading: `44sp` Bold, line height `50sp` text in `TextOnDark`.
  - Description: `14sp` Regular, line height `20sp` text in `TextOnDarkMuted`.
- **Footer**: Full-width Pill-Shaped Action Button.

### 2. Main Feed Screen
- **Top Bar**: Section Header on the left; flat variant Circle Icon Button on the right.
- **Warning Banner**: Rounded corner box (`16.dp` radius) in `Danger` at `0.15` opacity. Displays a warning icon and `12sp` Medium `TextOnDark` text.
- **Search Bar**: Full-width input row (Background `Cream`, `20.dp` rounded corners). Houses a search icon, a placeholder label in `TextOnCreamMuted` (`14sp`), and a close icon.
- **Filter Row**: Horizontal scrollable list (LazyRow) of Filter Chips.
- **Stats Strip**: Row of 3 equal-width boxes:
  - Background: `White` at `0.06` opacity, `16.dp` rounded corners.
  - Content: Center-aligned stack of large value text (`TextOnDark`, `18sp` Bold) and small label text (`TextOnDarkMuted`, `11sp`).
- **Feed List**: Vertical scrollable list (LazyColumn) of item cards:
  - Card: Background `Cream`, `20.dp` rounded corners.
  - Content Layout: Horizontal Row containing:
    - An icon container (`52.dp` square, `14.dp` rounded corners, background `AccentSoft`) with a centered icon in `TextOnCream`.
    - A middle column with title text (`TextOnCream`, `15sp` Semi-Bold) and sub-headline text (`TextOnCreamMuted`, `12sp`).
    - A right-aligned pill (Background `White` at `0.5` opacity) containing uppercase bold text in `TextOnCream` (`10sp`).

### 3. Detail View Screen
- **Top Bar**: Flat variant Circle Icon Buttons on the far left and far right of a horizontal Row.
- **Header Section**:
  - Row: Uppercase field text in `Accent` (`12sp` Bold), a dot, and standard category text in `TextOnDarkMuted` (`12sp`).
  - Title: Large header text (`TextOnDark`, `26sp` Bold, `32sp` line height).
  - Tag Row: Horizontal list of badges (Background `White` at `0.06` opacity, `12.dp` rounded corners) containing hashtag text in `TextOnDarkMuted` (`11sp`).
- **Summary Panel**:
  - Card: Background `Cream`, `24.dp` rounded corners.
  - Content: A label row with an icon in `Accent` and text in `TextOnCreamMuted` (`12sp` Semi-Bold). Below it, bold heading text (`TextOnCream`, `19sp` Bold) and body text (`TextOnCreamMuted`, `14sp`).
- **Type-Specific Grid**:
  - Background: `White` at `0.06` opacity, `20.dp` rounded corners.
  - Content: Vertical list of labels (in `Accent`, `11sp` Semi-Bold) and values (in `TextOnDarkMuted`, `13sp`).
- **Key Points Section**:
  - Visuals: Bulleted lines utilizing custom `**bold**` styling in `Accent` text and regular text in `TextOnDark` (`14sp`).
- **Action Items list**:
  - Card: Background `Cream`, `16.dp` rounded corners.
  - Layout: Horizontal Row with text on the left (`TextOnCream`, `14sp`) and a Switch on the right. Completed rows use `TextOnCreamMuted` for the text.
- **Claims list**:
  - Card: Background `White` at `0.06` opacity, `16.dp` rounded corners.
  - Layout: Left-aligned verification badge (Background at `0.2` opacity, text in matching solid color) next to claim text in `TextOnDark` (`13sp`).
- **Topic Map Section**:
  - Card: Background `White` at `0.06` opacity, `20.dp` rounded corners. Contains bold title text (`15sp`) and a horizontal row of tags styled in `PillDark` background.
- **Concept Cards**:
  - Card: Background `PillDark`, width `170.dp`, `18.dp` rounded corners.
  - Content: Centered icon in `Accent`, type label in `Accent` (`11sp` Semi-Bold), and name text in `TextOnDark` (`14sp` Medium).
- **Next Step Banner**:
  - Card: Background `Accent` at `0.15` opacity, `20.dp` rounded corners. Contains a flag icon and a bold title in `Accent` followed by bold instruction text in `TextOnDark` (`14sp`).

### 4. Checklist Screen
- **Top Section**: Section Header.
- **Progress Card**:
  - Card: Background `Cream`, `20.dp` rounded corners.
  - Content Layout: Horizontal Row containing a circular progress indicator (with progress text inside) on the left, next to text columns in `TextOnCream` (`16sp` Bold) and `TextOnCreamMuted` (`12sp`).
- **Grouped List**: Vertical column of headers (icon and label in `TextOnDarkMuted`, `13sp`) and child item cards (rounded cream rows).

---

## 5. Navigation & Screen Flow Visuals

- **Bottom Navigation Bar**:
  - Background: `BackgroundDarkAlt` (`#3A352D`).
  - Active States: Navigation items use an indicator pill in `Accent` behind the icon. Active text/icons use `TextOnCream` or `Accent`.
  - Inactive States: Icons/text rendered in `TextOnDarkMuted`.
  - Visibility: Bottom navigation is hidden on the Onboarding, Detail View, and Settings screens to maximize available canvas.
