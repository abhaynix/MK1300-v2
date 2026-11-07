# UI & Asset Inventory: Ant Esports MK1300 V2

## 1. Icon & Visual Assets Recovered

All graphic assets have been recovered and cataloged from `app.asar` (`build/images/`, `build/device/`, `build/doc/`):

| Relative Path | Asset Type | Description | Intended Role in Flutter |
|---|---|---|---|
| `main/assets/icon.ico` | Multi-res Windows Icon | Main executable & taskbar icon | Windows Runner `app_icon.ico` |
| `main/assets/favicon.ico` | ICO | Application header & tray icon | Window titlebar icon |
| `build/images/keyboard.svg` | SVG | Keyboard icon | Sidebar navigation item 1 |
| `build/images/light.svg` | SVG | Light bulb / RGB glow icon | Sidebar navigation item 2 |
| `build/images/macro.svg` | SVG | Mechanical switch / macro icon | Sidebar navigation item 3 |
| `build/images/performce.svg`| SVG | Lightning bolt / performance icon| Sidebar navigation item 4 |
| `build/images/config.svg` | SVG | Gear / settings icon | Sidebar navigation item 5 |
| `build/images/download.svg`| SVG | Download / user guide icon | Sidebar navigation item 6 |
| `build/images/bg.png` | PNG | Dark glassmorphism background | Background visual backdrop |
| `build/images/bg2.png` | PNG | Secondary gradient backdrop | Modal & card backgrounds |
| `build/images/wave.svg` | SVG | Audio / sound wave icon | Music reactive mode icon |
| `build/images/advanced.svg`| SVG | Keyboard layout symbol | Advanced key settings icon |
| `build/doc/*.png` (1..32) | PNG | 32 user manual screenshot images | In-app visual documentation |

---

## 2. Keyboard Physical Specifications

* **Dimensions**: 61-Key ANSI layout.
* **Aspect Ratio**: 15.02 units wide × 5.03 units high.
* **Standard Key Unit**: `1u` = 19.05 mm standard switch pitch (mapped to ~54 px in Flutter desktop at 1800×1000).
* **Key Unit Multipliers**:
  * Standard alphanumeric: `1.0u`
  * Tab: `1.5u`
  * Caps Lock: `1.75u`
  * Left Shift: `2.25u`
  * Right Shift: `2.75u`
  * Backspace: `2.0u`
  * Enter: `2.25u`
  * Spacebar: `6.25u`
  * Bottom Row Modifiers (Ctrl, Win, Alt, App): `1.25u` / `1.5u`

---

## 3. Typography & Text Tokens

* **Primary Font**: `Inter`, `Roboto`, `Segoe UI`, or native system sans-serif.
* **Monospace Font**: `JetBrains Mono` or `Consolas` for hex codes and macro delays.
* **Font Sizes**:
  * Window Title / Device Header: `16px` Semi-Bold (`w600`)
  * Tab Label: `14px` Medium (`w500`)
  * Section Card Header: `18px` Bold (`w700`)
  * Keycap Legend: `12px` - `14px` Bold (`w700`)
  * Macro Delay Values: `13px` Regular (`w400`)
