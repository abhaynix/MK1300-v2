# Ant Esports MK1300 V2 - Linux Desktop Application

A high-performance, native Linux desktop application for the **Ant Esports MK1300 V2 Mechanical Gaming Keyboard** (ANSI 60%, 61-key, ARGB, Vision 9520 MCU).

Re-engineered from the ground up using Flutter, native Linux HIDAPI via Dart FFI, and the **ChaiUI** design system, replacing the legacy 150MB+ Windows Electron application with a lean, standalone Linux AppImage (~13 MB).

---

## Features

- **Accurate 61-Key Keyboard Visualizer**: Built directly from the recovered hardware layout matrix (`assets/data/36ae_fe12.json`) with per-key selection, hover feedback, secondary legends, and real-time RGB preview.
- **Lighting Studio & HSV Engine**: Complete support for all 22 recovered hardware lighting modes, speed and brightness controls (levels 0–4), direction switching (L/R, U/D), custom per-key ARGB canvas, and pure Dart HSV color conversion.
- **Key Remapping & Layer Controller**: Full Layer 0 (Main) and Layer 1 (Fn) customization with a 6-category action catalog (Basic, Media, Mouse, Shortcut, Hardware, Macro) and transactional pending-state safety (Amber indicator dots with explicit Apply/Revert).
- **Macro Studio & 4KB EEPROM Compiler**: 16 macro slots backed by a byte-exact 4096-byte binary compiler and decompiler, millisecond delay tuning, loop playback modes, and JSON import/export.
- **Hardware Safety Gate**: Strict safety enforcement (`isHardwareWriteGated = true`) preventing unverified physical writes from transmitting to hardware until confirmed in the field.
- **Offline Hardware Simulator**: Built-in `MockHidDevice` simulating register configuration, chunked keymaps, lighting responses, and 4KB EEPROM memory for 100% offline development and testing.
- **ChaiUI Design System**: Clean, restrained aesthetic following the chaicode.com look (near-black warm `#0a0a0a` background, warm hairline borders, quiet cream accents, and asymmetric button corners).

---

## Distribution & Quick Start

### 1. Download & Run AppImage

A standalone, pre-packaged x86_64 AppImage bundled with `libhidapi` and Flutter Impeller OpenGL backend is available in `dist/`:

```bash
chmod +x dist/MK1300-V2-x86_64.AppImage
./dist/MK1300-V2-x86_64.AppImage
```

Checksums are maintained in `dist/SHA256SUMS`.

### 2. Configure USB Permissions (udev Rules)

To communicate with the physical MK1300 V2 keyboard over USB HID without root privileges, install the included udev rule:

```bash
sudo cp dist/99-ant-esports-mk1300.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

The rule assigns dynamic console access to the active desktop user via `systemd-logind` ACLs (`TAG+="uaccess"`).

---

## Hardware Identification & Protocol

- **Vendor ID (VID)**: `0x36AE` (13998)
- **Product ID (PID)**: `0xFE12` (65042)
- **Microcontroller**: Vision 9520 USB HID Controller
- **Interface**: USB HID Interface 1, Usage Page `0xFF00`, Usage `0x0002`
- **Report Size**: 64 bytes fixed interrupt reports (Little-Endian byte order)

### Supported Protocol Commands

| Opcode | Sub / Action | Description |
| :--- | :--- | :--- |
| `0x06` | `0x05` | Query device configuration, firmware version, and battery |
| `0x06` | `0x0A` / `0x0B` | Read and write active lighting effect configuration |
| `0x06` | `0x16` | Query lighting effect default presets |
| `0x06` | `0x08` / `0x09` | Read and write keymap chunks (56-byte payload) |
| `0x06` | `0x10` | Atomic single-key remap |
| `0x06` | `0x13` / `0x12` | Read and write per-key custom RGB chunks |
| `0x06` | `0x14` | Atomic single-key RGB color set |
| `0x06` | `0x0C` / `0x0D` | Read and write 4096-byte Macro EEPROM |
| `0x06` | `0x0F, 0x04` | Reset macro storage |
| `0x06` | `0xFB` | Switch hardware profile (P1, P2, P3) |
| `0x06` | `0xFC` | Configure auto-sleep timer (0s, 120s, 300s, 600s, 1800s) |
| `0x06` | `0x0F, 0xFF` | Factory reset (safety gated) |
| `0xAA` | `0xFA` | Unsolicited live hardware event notification listener |

---

## Building from Source

### Prerequisites
- Linux x86_64 (Ubuntu 22.04+, Debian 12+, Fedora 39+, Arch Linux)
- Flutter SDK (stable >= 3.19.0)
- Build tools: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libhidapi-dev`

```bash
# Clone the repository
git clone https://github.com/abhaynix/MK1300-v2.git
cd MK1300-v2

# Fetch dependencies
flutter pub get

# Run test suite
flutter test

# Compile native Linux release
flutter build linux --release

# Package standalone AppImage
./linux/packaging/build_appimage.sh
```

---

## Testing & Quality Assurance

The codebase includes 91 automated unit, widget, and integration tests with 100% pass rate:

- `test/hsv_color_test.dart` (20 tests): HSV/RGB conversions, rounding, and byte mapping.
- `test/lighting_protocol_test.dart` (12 tests): Packet serialization, safety gating, and event listeners.
- `test/lighting_studio_test.dart` (9 tests): 22 lighting modes and widget lifecycle disposal.
- `test/dashboard_and_visualizer_test.dart` (4 tests): Dynamic layout JSON parsing and 61-key rendering.
- `test/key_remapping_test.dart` (18 tests): Layer switching, catalog filtering, and transactions.
- `test/macro_studio_test.dart` (10 tests): 4KB EEPROM binary compiler/decompiler and timeline editor.
- `test/mock_hid_device_test.dart` (8 tests): HID provider state machine and command queues.
- `test/packet_serialization_test.dart` (10 tests): Low-level packet builder formatting.

Static analysis:
```bash
flutter analyze
# No issues found!
```

---

## License

MIT License. Reverse-engineered and built for Linux interoperability.
