# MK1300 V2 - Project Gap Analysis

## 1. Overview & Audit Scope

This document details the gaps between the recovered source code / reverse engineering findings and the Flutter Linux codebase, tracking completed resolutions and maintaining strict distinction between software verification and physical hardware validation.

---

## 2. Module-by-Module Status & Resolution Summary

### 2.1 Hardware Layer & USB HID (Phases 5A, 5A.1)
* **Status**: **RESOLVED & VERIFIED**
* **Delivered**:
  * `LinuxHidDevice` using Dart FFI to bind `libhidapi-hidraw.so.0` with graceful fallback to `MockHidDevice`.
  * `CommandQueue` serializing asynchronous writes and responses without race conditions.
  * `PacketBuilder` encoding all verified commands with Little-Endian byte math and bounds clamping.
  * System udev permission rules (`99-keyboard-studio-mk1300.rules`) created and bundled for non-root desktop access.

### 2.2 Dashboard & Visualizer (Phase 5B)
* **Status**: **RESOLVED & VERIFIED**
* **Delivered**:
  * 61-key ANSI visualizer with dynamic key geometry matching `assets/data/36ae_fe12.json`.
  * Connection state indicators (searching, connecting, connected, disconnected, simulated).
  * Navigation bar to all primary features.

### 2.3 Lighting Studio & HSV Engine (Phases 6A, 6A.1, 6B)
* **Status**: **RESOLVED & VERIFIED**
* **Delivered**:
  * Complete 22 lighting modes recovered with parameter constraints.
  * Verified HSV-to-RGB and RGB-to-HSV conversion matching original JavaScript source math.
  * Hardware read synchronization (`CMD 0x06, 0x0A`) and write serialization (`CMD 0x06, 0x0B`).
  * Live event handling (`0xAA, 0xFA`) via `UnsolicitedEventDecoder`.
  * Desktop lifecycle management pausing animations when hidden or minimized.
  * Physical writes gated behind `isHardwareWriteGated = true`.

### 2.4 Key Remapping & Layer Controller (Phase 7)
* **Status**: **RESOLVED & VERIFIED**
* **Delivered**:
  * Layer 0 (Main) and Layer 1 (Fn) switching.
  * Complete 6-category action catalog (Basic, Media, Mouse, Shortcut, Hardware, Macro) with live text search.
  * Explicit transactional state machine: Local Pending modifications -> Visual Amber dot -> Explicit Apply / Revert buttons.
  * Single key write (`0x06, 0x10`) and batch chunk write (`0x06, 0x09`) / read (`0x06, 0x08`) implemented.
  * 18 unit and widget tests passing with 100% success.

### 2.5 Macro Studio & EEPROM Compiler (Phase 8)
* **Status**: **RESOLVED & VERIFIED**
* **Delivered**:
  * `MacroCompiler` implementing exact 4KB binary compilation (`compileToEeprom`) and decompilation (`decompileFromEeprom`).
  * `MacroPage` UI displaying 16 macro slots with action timeline, delay editing, loop mode selection, and action reordering.
  * JSON export and import capabilities.
  * Reset macro memory via `CMD 0x06, 0x0F, 0x04` implemented in `KeyboardService.clearAllMacros()`.
  * Dedicated test suite `test/macro_studio_test.dart` (10 tests) covering binary serialization, boundary checking, safety gating, and UI widget workflows.

### 2.6 Profiles, Device Settings & AppImage Packaging (Phase 9 & 10)
* **Status**: **RESOLVED & VERIFIED**
* **Delivered**:
  * `SettingsPage` with sleep timeout dropdown (0s, 120s, 300s, 600s, 1800s), device metadata card, and factory reset guard.
  * Profile switching (`CMD 0x06, 0xFB`) in `KeyboardService.switchProfile(int)`.
  * FreeDesktop desktop entry `linux/packaging/dev.exdevx.keyboard_studio.desktop`.
  * Hi-DPI application icon `linux/packaging/dev.exdevx.keyboard_studio.png` extracted at 256x256.
  * Automated AppImage packaging script `linux/packaging/build_appimage.sh` producing `dist/KeyboardStudio-x86_64.AppImage`.
  * Cryptographic checksum generation in `dist/SHA256SUMS`.
  * AppImage execution verified on Linux with Impeller rendering backend.

### 2.7 Physical Hardware Validation
* **Status**: **PENDING PHYSICAL DEVICE AVAILABILITY**
* **Status Policy**:
  * The physical MK1300 V2 keyboard is not attached to the host environment.
  * All protocol communication is fully verified against the original recovered JavaScript source and the `MockHidDevice` simulation state machine.
  * Physical verification is explicitly recorded as **PENDING** in all project documentation until tested on physical hardware.
