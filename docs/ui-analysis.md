# UI/UX Analysis & Design System: Ant Esports MK1300 V2

## 1. Visual Identity & Theme

* **Design Aesthetic**: Modern Gaming Dark Glassmorphism.
* **Window Specifications**:
  * Default Window Resolution: `1800 × 1000 px`
  * Minimum Window Resolution: `1800 × 1000 px`
  * Aspect Ratio: ~16:9 widescreen desktop application.
* **Color Palette**:
  * Background Main: `#18181B` (Zinc 900) / Gradient `#0F172A` to `#1E293B`.
  * Glass Panels: `rgba(39, 74, 113, 0.4)` to `rgba(25, 54, 93, 0.7)` with subtle border `rgba(255, 255, 255, 0.1)`.
  * Brand Accent: Electric Cyan `#6BC4FF` / Indigo `#4338CA`.
  * Keycaps (Normal): Dark Charcoal `#27272A` with `#FFFFFF` legends.
  * Keycaps (Active / Selected): Bright Cyan `#0284C7` border and glow.
  * Success / Save: Neon Green `#4ADE80`.
  * Danger / Delete: Coral Red `#EF4444`.

---

## 2. Screen Hierarchy & Navigation Layout

The application has a persistent master layout divided into 3 zones:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP BAR: [Device Name / Status]   [Profile: 1|2|3]   [Layer: Main|Fn]   [Lang] [Min|Close]│
├───────────────┬────────────────────────────────────────────────────────────────────────┤
│ SIDEBAR       │ MAIN CONTENT AREA                                                      │
│               │                                                                        │
│ [⌨] Key       │  ┌──────────────────────────────────────────────────────────────────┐  │
│ [💡] Light    │  │                   INTERACTIVE 61-KEY KEYBOARD                    │  │
│ [⚙] Macro     │  │                           VISUALIZER                             │  │
│ [⚡] Perform   │  └──────────────────────────────────────────────────────────────────┘  │
│ [🔧] Settings  │                                                                        │
│               │  ┌──────────────────────────────────────────────────────────────────┐  │
│               │  │                CONTEXTUAL CONFIGURATION PANEL                    │  │
│               │  │      (Key Remap Picker / RGB Sliders / Macro Action Table)       │  │
│               │  └──────────────────────────────────────────────────────────────────┘  │
└───────────────┴────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Screen-by-Screen Breakdown

### 3.1 Tab 1: Key Remap Page (`key`)
* Displays the interactive 61-key keyboard layout with accurate keycap proportions (e.g., Space = 6.25u, Backspace = 2.0u, Tab = 1.5u, Enter = 2.25u, Shift = 2.25u/2.75u).
* Hovering or clicking a key highlights it and displays its current assigned function.
* Bottom drawer displays the **Key Mapping Category Selector**:
  * Category Tabs: Basic Keys, Media Keys, Mouse Keys, Shortcuts, Custom Combos, Macros, Stock.
  * Selecting a key in the category immediately maps it to the selected keycap.
  * Layer toggle button: Switch between **Main Layer** and **Fn Layer**.
  * Action button: "Save to Keyboard".

### 3.2 Tab 2: Lighting Configuration Page (`light`)
* Center visualizer displays live RGB color previews for each keycap.
* Bottom panel includes:
  * **Effect Selector Dropdown**: 22 effects (Off, Static, Breathing, Neon, Spectrum, Streamer, etc.).
  * **Brightness Slider**: 5 discrete levels.
  * **Speed Slider**: 5 discrete levels.
  * **Direction Control**: Left/Right or Up/Down buttons (enabled only for directional modes).
  * **Color Picker**: 8 quick-palette swatches + Full 360° HSV / RGB color wheel.
  * **"Custom Light" Toggle**: Allows clicking individual keys on the visualizer to paint them specific colors.

### 3.3 Tab 3: Macro Management Page (`macro`)
* Left Column (320px): **Macro List** (`M0`..`M15`), with Add, Delete, Import (`.json`), Export (`.json`), and "Save to Keyboard" buttons.
* Right Column (Expanded):
  * **Action Sequence Table**: Displays keystrokes with columns:
    * Key Name (e.g. `A`, `Ctrl`, `Mouse L-Button`)
    * Action Type (`Press` / `Release`)
    * Delay in Milliseconds (Inline editable input box)
  * Controls Bar:
    * `Start Recording` / `Stop Recording` button
    * `Fixed Delay` checkbox and millisecond input
    * Order manipulation buttons: `Top`, `Up`, `Down`, `Bottom`, `Delete`, `Clear`
    * Macro Execution Mode radio options (Loop until release, Toggle, Loop N times).

### 3.4 Tab 4: Settings Page (`config`)
* Auto-sleep timeout selection: `2min`, `5min`, `10min`, `30min`.
* Language selector: English, Chinese, etc.
* Software & Firmware version information.
* Factory Reset button with warning confirmation dialog.

### 3.5 Tab 5: User Guide Page (`download` / `doc`)
* In-app visual user documentation guide explaining keyboard shortcuts (`Fn + Backspace`, `Fn + \`, etc.).
