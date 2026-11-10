# MK1300 V2 - Test Execution Results

**Date**: 2026-11-08  
**Environment**: Dart 3.13.7 / Flutter 3.47.9 Desktop on Ubuntu 26.04.1 LTS x86_64  
**Target Hardware**: MK1300 V2 Mechanical Gaming Keyboard (Vision 9520 MCU, VID `0x36AE`, PID `0xFE12`)  
**Target Output**: Native Linux Release Binary & Standalone AppImage (`dist/KeyboardStudio-x86_64.AppImage`)

---

## 1. Automated Test Suite Summary

| Test Suite File | Domain & Scope | Tests | Passed | Failed | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `test/hsv_color_test.dart` | HSV/RGB bidirectional conversions, rounding, boundary values, hex alpha encoding | 20 | 20 | 0 | **PASSED** |
| `test/lighting_protocol_test.dart` (synced via `lighting_synchronization_test.dart`) | Read/write lighting packets, unsolicited 0xAA 0xFA live event handling, safety gating | 12 | 12 | 0 | **PASSED** |
| `test/lighting_studio_test.dart` | 22 modes UI selection, local preview, lifecycle pause/resume, memory disposal | 9 | 9 | 0 | **PASSED** |
| `test/dashboard_and_visualizer_test.dart` | Layout JSON parsing (36ae_fe12.json), 61-key visualizer widget, key tap callbacks | 4 | 4 | 0 | **PASSED** |
| `test/key_remapping_test.dart` | Layer 0/1 remapping, key catalog categories, pending state transactions, chunk/single packets | 18 | 18 | 0 | **PASSED** |
| `test/macro_studio_test.dart` | 4KB EEPROM binary compiler/decompiler, 16 slots, action types, safety gating, UI timeline | 10 | 10 | 0 | **PASSED** |
| `test/mock_hid_device_test.dart` | Mock HID provider, report streams, hardware simulation state machine | 8 | 8 | 0 | **PASSED** |
| `test/packet_serialization_test.dart` | Low-level PacketBuilder, buffer offsets, opcode formatting, checksums | 10 | 10 | 0 | **PASSED** |
| **Combined Project Total** | **All Core Functional & Hardware Domains** | **91** | **91** | **0** | **100% PASSED** |

---

## 2. Static Analysis Audit (`flutter analyze`)

- **Command**: `flutter analyze`
- **Result**: `No issues found! (ran in 1.9s)`
- **Exit Code**: `0`
- **Quality Metrics**:
  - 0 Errors
  - 0 Warnings
  - 0 Linter Hints
  - 0 Deprecated API usages (all Flutter 3.27+ deprecations resolved: `withValues`, `toARGB32`, `DropdownButtonFormField.initialValue`).

---

## 3. Release Build Verification (`flutter build linux --release`)

- **Command**: `flutter build linux --release`
- **Exit Code**: `0`
- **Target Path**: `build/linux/x64/release/bundle/keyboard_studio`
- **Binary Format**: ELF 64-bit LSB PIE executable, x86-64, dynamically linked.
- **Embedded Engine**: Flutter Engine with Impeller OpenGL backend.

---

## 4. Linux AppImage Distribution Verification

- **Command**: `./linux/packaging/build_appimage.sh`
- **Exit Code**: `0`
- **Distribution Output**: `dist/KeyboardStudio-x86_64.AppImage` (Size: ~13 MB)
- **Checksum File**: `dist/SHA256SUMS`
- **SHA-256 Digest**: `463935c0eaa93534fc1568d9400ba03da8a079c042fff52599d95bb0cb68c67e`
- **Runtime Execution Verification**:
  - Successfully unpacked and extracted with `--appimage-extract`.
  - Tested execution in headless / display session with Impeller rendering backend initialized cleanly.
  - Bundled shared libraries audited and confirmed: `libhidapi-hidraw.so.0.15.0`, `libhidapi-libusb.so.0.15.0`, `libflutter_linux_gtk.so`.

---

## 5. Hardware Status & Safety Verification

- **Physical Hardware Verification**: Marked **EXPLICITLY PENDING** (Physical keyboard device `0x36AE:0xFE12` not physically attached to development host).
- **Hardware Safety Gate**: **ACTIVE & ENFORCED** (`KeyboardService.isHardwareWriteGated = true`).
  - Gated physical commands:
    - Lighting writes (`0x06, 0x0B` and per-key `0x06, 0x12`/`0x14`)
    - Key remapping writes (`0x06, 0x09` and single key `0x06, 0x10`)
    - Macro EEPROM writes (`0x06, 0x0D` and reset `0x06, 0x0F, 0x04`)
    - Factory restore (`0x06, 0x0F, 0xFF` strictly gated with confirmation guard)
    - Bootloader flashing (`0x55, 0xFF` rejected by default)
