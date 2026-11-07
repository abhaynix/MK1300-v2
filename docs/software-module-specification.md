# Ant Esports MK1300 V2 - Software Module Specification

## 1. Architectural Principles

The software follows a clean, modular desktop architecture adhering strictly to **unidirectional data flow**, separation of concerns, and dependency inversion:

```
[Presentation Layer]
       │
       ▼
[Feature Models & Services]
       │
       ▼
[Hardware / Protocol Abstraction Layer]
       │
       ▼
[Native C-FFI / hidapi Bridge]
```

Dependencies always point inwards. No presentation widget communicates directly with FFI pointers or raw byte arrays.

---

## 2. Directory & Module Responsibilities

### 2.1 `lib/app/`
- **Purpose**: Global application setup, theme tokens, and routing.
- **Key Modules**:
  - `theme/theme.dart`: Defines exact hex color palette recovered from the original app (`#18181B` background, `#274A71` panel, `#6BC4FF` accent cyan, `#4ADE80` success green). Provides dark theme widgets, custom slider themes, button styling, and keycap geometry tokens.

### 2.2 `lib/core/`
- **Purpose**: Low-level foundational utilities, byte manipulations, and fixed constants.
- **Key Modules**:
  - `constants/usb_constants.dart`: USB VID (`0x36AE`), PID (`0xFE12`), Usage Page (`0xFF00`), Usage (`0x0002`), Interface (`1`), fixed payload lengths (64 bytes).
  - `constants/key_codes.dart`: Complete tables for Standard 104-key HID codes, Multimedia keycodes, Mouse button codes, and modifier bitmasks (`Ctrl`, `Shift`, `Alt`, `Win`).
  - `utils/byte_buffer.dart`: Little-endian integer conversion (`toUint16BytesLE`, `readUint16LE`), payload zero-padding, and slicing helpers.
  - `utils/color_utils.dart`: Bit-exact mathematical translation between Flutter `Color` and Vision 9520 firmware HSV byte triplets (`0–255`).

### 2.3 `lib/hardware/`
- **Purpose**: Physical USB HID communication, device discovery, packet queue serialization, and framing.
- **Key Modules**:
  - `hid/hid_device.dart`: Abstract interface defining `open()`, `close()`, `writeReport()`, `readReport()`, and `reportStream`.
  - `hid/hidapi_binding.dart`: Native Dart C-FFI wrapper loading `libhidapi-hidraw.so.0` / `libhidapi-libusb.so.0`. Handles enumeration, device path selection matching interface 1, and asynchronous report polling.
  - `hid/mock_hid_device.dart`: High-fidelity hardware simulation engine maintaining virtual EEPROM, simulated lighting states, and unsolicited event loops. Enables running the app on systems without the keyboard attached.
  - `protocol/command_queue.dart`: Async serialized queue ensuring thread-safe, single-flight USB packet dispatch with 1000ms timeouts and inter-chunk delays.
  - `protocol/packet_builder.dart`: Builder and parser for all 64-byte reports (`0x06` opcodes, lighting framing, keymap chunks, and live event decoders).
  - `services/keyboard_service.dart`: Central state orchestrator (`ChangeNotifier`). Manages connection lifecycle, profile switches, layer toggles, and exposes reactive models to the UI.

### 2.4 `lib/features/`
- **Purpose**: Modular business logic and UI presentation views for distinct feature domains.

#### `features/dashboard/`
- **Files**: `presentation/dashboard_page.dart`
- **Responsibilities**: Device connection status card, battery indicator, active layer/profile summary, and embedded interactive keyboard canvas for quick visual feedback.

#### `features/lighting/`
- **Files**: `models/lighting_mode.dart`, `models/lighting_config.dart`, `presentation/lighting_page.dart`
- **Responsibilities**: 
  - Manages all 22 lighting modes with parameter availability matrix (brightness, speed, direction, color mode).
  - Renders speed/brightness sliders, custom color picker dialog, 8 preset swatches, and per-key custom ARGB switch grid.

#### `features/key_remapping/`
- **Files**: `models/key_geometry.dart`, `models/key_mapping.dart`, `presentation/key_remapping_page.dart`, `presentation/keyboard_visualizer.dart`
- **Responsibilities**:
  - Implements the exact 61-key ANSI mechanical switch layout with matrix indices (0..73).
  - Handles Main Layer and Fn Layer switching.
  - Category selector tabs: Standard Keyboard, Multimedia, Mouse Actions, Short Cuts, and Macros.
  - Interactive key click selection and real-time remap packet dispatch.

#### `features/macros/`
- **Files**: `models/macro_action.dart`, `models/macro_model.dart`, `services/macro_compiler.dart`, `presentation/macro_page.dart`
- **Responsibilities**:
  - Manages 16 hardware macro slots.
  - Compiler packs macro sequences into 4096-byte binary EEPROM image with 16-bit offset pointer table.
  - Live keystroke recorder with fixed or variable delay insertion.
  - JSON import and export for local backup and sharing.

#### `features/settings/`
- **Files**: `presentation/settings_page.dart`
- **Responsibilities**:
  - Auto-sleep inactivity dropdown (Never, 2m, 5m, 10m, 30m).
  - Microcontroller and firmware diagnostics.
  - Interface diagnostics with bus rescan trigger.
  - Factory reset trigger with confirmation dialog.

### 2.5 `lib/shared/`
- **Files**: `widgets/app_shell.dart`
- **Responsibilities**: Responsive desktop shell featuring persistent top bar (connection badge, battery percentage, profile buttons P1/P2/P3, layer indicator) and left sidebar navigation.
