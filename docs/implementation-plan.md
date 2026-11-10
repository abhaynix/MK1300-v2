# Implementation Plan: Flutter Native Recreation

## 1. Overview & Strategy

The Flutter implementation reconstructs the original MK1300 V2 software as a high-performance native desktop application on Windows (with full architecture support for Linux).

---

## 2. Phased Development Roadmap

### Phase 4: Flutter Project Setup & Foundation
1. Initialize native desktop Flutter project targeting Windows and Linux.
2. Configure dependencies:
   * `ffi`: Low-level C library bindings for USB HID.
   * `flutter_riverpod`: Reactive UI state management.
   * `flutter_svg`: Rendering original vector menu icons.
   * `file_picker`: Macro and profile import/export.
   * `window_manager`: Window dimensions (1800×1000), minimum constraints, titlebar customization.
3. Implement theme system:
   * Dark glassmorphism color palette (`#18181B` base, `#274A71` gradients, `#6BC4FF` cyan accents).
   * Reusable UI widgets: `GlassCard`, `NeonButton`, `LabeledSlider`, `ColorPickerModal`.

### Phase 5: Hardware Layer Implementation (USB HID)
1. Implement `HidDevice` interface via Dart FFI calling `hidapi`:
   * Device enumeration and filtering (`VID: 0x36AE`, `PID: 0xFE12`, `UsagePage: 0xFF00`).
   * 64-byte Output Report transmission (`sendReport`).
   * Inbound Interrupt Report reader stream (`onInputReport`).
2. Implement Command Queue to prevent packet collision and enforce sequential execution.
3. Build Protocol Serializers:
   * Get/Set Configuration (`CMD 0x06, Sub 0x05`).
   * Get/Set Lighting (`CMD 0x06, Sub 0x0A` and `0x0B`).
   * Read/Write Key Remap chunks (`CMD 0x06, Sub 0x08` and `0x09`).
   * Read/Write Macro EEPROM arena (`CMD 0x06, Sub 0x0C` and `0x0D`).
   * Profile switch (`Sub 0xFB`) and Factory reset (`Sub 0x0F`).

### Phase 6: Feature Implementation (UI + Business Logic)
1. **Interactive Keyboard Visualizer**:
   * Custom-drawn 61-key layout widget matching real physical proportions.
   * Dynamic key rendering (active lighting colors, custom legends, selected highlights).
2. **Key Remapping System**:
   * Full 7-category drawer (Basic, Media, Mouse, Shortcut, Custom, Macro, Stock).
   * Main Layer vs Fn Layer toggle.
   * Single-key fast update + Full layout bulk save.
3. **RGB Lighting Engine**:
   * 22 lighting presets selector.
   * Brightness, speed, direction sliders, and HSV color wheel.
   * Per-key custom RGB painter mode.
4. **Macro Management Engine**:
   * 16-slot macro manager (`M0`..`M15`).
   * Action sequence table with inline delay editing.
   * 4096-byte compiler matching exact recovered hardware binary layout.
   * JSON import and export.
5. **Profile & Device Settings**:
   * Profile switcher (Profile 1, 2, 3).
   * Auto-sleep timer selector.
   * Factory reset modal.

### Phase 7: Verification & Testing
1. Unit testing of binary serializers, macro compiler, and HSV math.
2. Mock HID driver for CI testing without physical hardware connected.
3. Comparative visual audit against original screenshots.
