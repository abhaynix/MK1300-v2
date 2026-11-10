# Reconstructed Architecture: MK1300 V2 in Flutter

## 1. Architectural Principles

The Flutter recreation replaces the Electron/Node/Chromium stack with a high-performance, single-binary native desktop application built with Dart and Flutter desktop.

* **Pattern**: Feature-First Clean Architecture.
* **Separation of Concerns**: UI components never send raw USB packets. All operations pass through typed domain services.
* **State Management**: Reactive state management using Riverpod (or ChangeNotifier/StateNotifier).
* **Hardware Interop**: Native platform HID library via Dart FFI (`hidapi` / `win32`).

---

## 2. Directory Structure

```
lib/
├── main.dart                          # Application entry point and window initialization
├── app/
│   ├── app.dart                       # MaterialApp configuration & router
│   ├── theme.dart                     # Gaming dark glassmorphism theme & tokens
│   └── window_manager.dart            # Desktop window sizing & frame configuration
├── core/
│   ├── constants/
│   │   ├── usb_constants.dart         # VID 0x36AE, PID 0xFE12, Usage Page 0xFF00
│   │   └── key_codes.dart             # Standard HID & Consumer usage codes
│   ├── hid/
│   │   ├── hid_device.dart            # Abstract USB HID interface (Open, Read, Write, Close)
│   │   ├── hid_service.dart           # Device discovery, polling, and hotplug management
│   │   ├── hid_packet.dart            # 64-byte packet construction & checksum utilities
│   │   └── hidapi_binding.dart        # Dart FFI bindings for hidapi.dll / libhidapi.so
│   └── utils/
│       ├── color_utils.dart           # RGB <-> HSV converter matching firmware math
│       └── byte_buffer.dart           # Little-endian binary reader/writer
├── features/
│   ├── device/
│   │   ├── models/keyboard_config.dart # Firmware version, battery, profile, layer
│   │   └── services/device_service.dart# Hardware initialization & handshake
│   ├── lighting/
│   │   ├── models/lighting_config.dart # Mode, brightness, speed, direction, HSV
│   │   ├── models/lighting_mode.dart   # Enum of all 22 lighting effects
│   │   ├── services/lighting_service.dart # Packet generation for CMD 0x06 Sub 0x0B
│   │   └── presentation/lighting_page.dart # Sliders, palette, and live visualizer
│   ├── key_remapping/
│   │   ├── models/key_mapping.dart    # 4-byte descriptor [type, code1, code2, code3]
│   │   ├── models/keyboard_layout.dart # 61-key matrix, coordinates, and labels
│   │   ├── services/key_service.dart  # Read/write key tables (CMD 0x06 Sub 0x08/0x09)
│   │   └── presentation/
│   │       ├── keyboard_visualizer.dart # Interactive 61-key canvas widget
│   │       ├── key_drawer.dart         # Category tabs (Basic, Media, Mouse, etc.)
│   │       └── key_remapping_page.dart # Full screen layout
│   ├── macros/
│   │   ├── models/macro_action.dart   # Delay, flags (isLast, isPress, type), code
│   │   ├── models/macro_model.dart    # Macro name, list of actions, loop mode
│   │   ├── services/macro_compiler.dart # Compiles to/from 4096-byte EEPROM buffer
│   │   ├── services/macro_recorder.dart # Global keystroke listener during recording
│   │   └── presentation/macro_page.dart # Macro list, action table, and recorder bar
│   ├── profiles/
│   │   ├── models/profile_model.dart  # Combined keys, lighting, and macro snapshot
│   │   └── services/profile_service.dart # Profile switching & disk JSON serialization
│   └── settings/
│       └── presentation/settings_page.dart # Auto-sleep, language, factory reset
└── shared/
    ├── widgets/
    │   ├── glass_card.dart            # Glassmorphism container
    │   ├── neon_button.dart           # Glowing custom gaming button
    │   ├── labeled_slider.dart        # Discrete slider with ticks
    │   └── color_swatch_button.dart   # Hex palette button
    └── layout/
        └── app_shell.dart             # Top navigation bar, sidebar, and content area
```

---

## 3. Data Flow

```
┌────────────────┐     User Selects Color     ┌──────────────────────┐
│  LightingPage  │ ─────────────────────────> │   LightingService    │
└────────────────┘                            └──────────┬───────────┘
                                                         │
                                             Encodes CMD 0x06, Sub 0x0B
                                                         │
                                              ┌──────────▼───────────┐
                                              │      HIDService      │
                                              └──────────┬───────────┘
                                                         │
                                          Writes 64-byte Buffer to USB
                                                         │
                                              ┌──────────▼───────────┐
                                              │  MK1300 V2 Hardware  │
                                              └──────────────────────┘
```
