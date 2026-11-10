# Application Feature Inventory: MK1300 V2

## 1. Feature Matrix & Implementation Verification Status

| Feature Module | Feature Item | Original Implementation | Hardware Verified? | Status | Flutter Strategy |
|---|---|---|---|---|---|
| **Device Connection** | Auto-detection via VID/PID | WebHID `getDevices` / `select-hid-device` | ✅ Verified in code (`0x36AE:0xFE12`) | Supported | `hidapi` / Dart FFI background polling & arrival notifications |
| | Connection status bar | Top bar displaying device name | ✅ Static verification | Supported | Custom Header widget with status indicator |
| | Device battery / charging display | Queried in `getKeyboardConfig` (Bytes 8 & 9) | ✅ Static verification | Supported | Battery percentage icon in top bar |
| | Firmware version display | Queried in `getKeyboardConfig` | ✅ Static verification | Supported | Settings modal and top bar |
| **Key Remapping** | 61-Key Interactive Visualizer | SVG/CSS keyboard canvas | ✅ Layout recovered (`RS0-61K-ARGB`) | Supported | CustomPainter / Flutter Grid visualizer with physical key caps |
| | Main Layer (0) Remap | Writes 4-byte descriptor per key | ✅ Protocol verified | Supported | Key inspector drawer with category tabs |
| | Fn Layer (1) Remap | Layer selector toggle | ✅ Protocol verified | Supported | Toggle button between Main and Fn layer |
| | Key Categories | Basic, Media, Mouse, Shortcut, Custom, Macro, Stock | ✅ Complete JSON key database recovered | Supported | Tabbed selector with search and quick-pick |
| | Single Key Remap | Fast single-key command `0x10` | ✅ Protocol verified | Supported | Immediate write to hardware upon selection |
| | Batch Remap Save | Multi-packet chunked write `0x09` | ✅ Protocol verified | Supported | "Save to Keyboard" action button |
| **Lighting (RGB)** | 22 Preset Lighting Modes | Slider controls & preset dropdown | ✅ All 22 modes and params mapped | Supported | Visual effect picker with real-time preview animation |
| | Brightness Adjustment | 5 levels (0 - 4) | ✅ Protocol verified | Supported | Flutter Slider widget |
| | Speed Adjustment | 5 levels (0 - 4) | ✅ Protocol verified | Supported | Flutter Slider widget |
| | Direction Control | Horizontal / Vertical toggles | ✅ Protocol verified | Supported | ToggleButtons widget |
| | Color Palette & HSV Picker | Preset colors + Custom HSV wheel | ✅ Protocol verified | Supported | Color picker dialog with live preview |
| | Custom Per-Key RGB | Interactive key color painting | ✅ Protocol verified | Supported | Multi-select keys + color palette assignment |
| | Live Lighting Sync | Inbound `0xAA, 0xFA` listener | ✅ Protocol verified | Supported | StreamController listening to USB input reports |
| **Macro Engine** | Macro List Management | Up to 16 macros (`M0`..`M15`) | ✅ Protocol verified | Supported | Sidebar list with Add/Delete/Rename |
| | Live Keystroke Recorder | Browser keydown/keyup listener | ✅ Protocol verified | Supported | Windows Raw Input / Hardware keyboard hook |
| | Action Sequence Editor | Up/Down reordering, delay edits | ✅ Data model verified | Supported | ReorderableListView with inline delay input |
| | Mouse Event Insertion | Mouse click & scroll insertion | ✅ Protocol verified | Supported | Action dropdown menu in editor |
| | Macro Import / Export | Local `.json` files | ✅ File format verified | Supported | File picker import/export |
| | Save to Keyboard Memory | 4096-byte chunked upload (`0x0D`)| ✅ Binary encoder verified | Supported | One-click EEPROM write with progress bar |
| **Profiles** | Onboard Profile Switch | 3 profiles (`0xFB`) | ✅ Protocol verified | Supported | Profile dropdown selector (Profile 1, 2, 3) |
| | Factory Reset | Command `0x0F, 0xFF` | ✅ Protocol verified | Supported | Confirmation dialog and memory re-flash |
| **Settings** | Auto-sleep Timeout | 2m, 5m, 10m, 30m, custom | ✅ Protocol verified | Supported | Radio list / segmented control |
| | Theme Selection | Light theme / Dark theme | ✅ Tailwind CSS verified | Supported | Flutter ThemeMode (Dark gaming default) |
| | Multi-language (i18n) | EN, CN, AR, CZ, ES, FR, JA | ✅ Recovered `en/common.json` | Supported | Flutter `intl` localization |
| | User Documentation | Embedded `/doc` user guide | ✅ 32 images & text recovered | Supported | Native Markdown / RichText documentation viewer |
| | Firmware Upgrade (IAP) | Bootloader updater (`0x55`, `0x5A`)| ⚠️ Protocol recovered, unverified | Optional/Safe guard | Blocked in standard UI to prevent bricking without signed binary |
