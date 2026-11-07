# Ant Esports MK1300 V2 - Test Execution Results

**Date**: 2026-11-07  
**Environment**: Dart 3.13.7 / Flutter 3.47.9 Desktop on Ubuntu 26.04.1 LTS x86_64  
**Target Hardware**: Ant Esports MK1300 V2 Mechanical Gaming Keyboard (Vision 9520 MCU, VID 0x36AE, PID 0xFE12)  
**Test Suites**: 
- `test/mock_hid_device_test.dart`
- `test/packet_serialization_test.dart`
- `test/dashboard_and_visualizer_test.dart`
- `test/hsv_color_test.dart`
- `test/lighting_studio_test.dart`

---

## 1. Automated Test Summary

| Test Suite | Total Tests | Passed | Failed | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Mock HID Provider & Service State Tests** | 8 | 8 | 0 | **PASSED** |
| **PacketBuilder & ColorUtils Serialization Tests** | 10 | 10 | 0 | **PASSED** |
| **Dashboard & Keyboard Visualizer Tests** | 4 | 4 | 0 | **PASSED** |
| **HsvColor Pure Dart Engine Tests** | 17 | 17 | 0 | **PASSED** |
| **Lighting Studio Model & UI Tests** | 7 | 7 | 0 | **PASSED** |
| **Combined Suite Total** | **46** | **46** | **0** | **100% PASSED** |

---

## 2. Static Analysis Audit (`flutter analyze`)

- **Total Issues**: **0 issues found** (Exit Code: **0**).
- Zero warnings, zero errors, zero deprecated API usages.

---

## 3. Command Execution & Exit Codes Audit

| Command | Exit Code | Outcome |
| :--- | :--- | :--- |
| `flutter pub get` | **0** | Dependencies resolved cleanly. |
| `flutter analyze` | **0** | **Zero issues / zero warnings**. |
| `flutter test` | **0** | **46 / 46 unit & widget tests passed (100%)**. |
| `flutter build linux --release` | **1** | Halted: System build tools (`cmake`, `ninja`, `clang`, `libgtk-3-dev`) missing from test container. |

---

## 4. Release Executable Verification

- **Target Path**: `build/linux/x64/release/bundle/`
- **Result**: Not generated on host.
- **Root Cause**: `flutter build linux --release` requires CMake and GTK 3 development headers to be installed via `sudo apt install -y clang cmake ninja-build g++ pkg-config libgtk-3-dev`. In accordance with project instructions, unprompted root/sudo installation was not performed.
- **Physical Hardware Verification**: Remains **EXPLICITLY PENDING** as the physical Ant Esports MK1300 V2 keyboard is not attached to the host USB bus.

---

## 2. Static Analysis Audit (`flutter analyze`)

- **Total Issues**: **0 issues found** (Exit Code: **0**).
- All deprecations (`withOpacity` -> `withValues`, `color.value` -> `toARGB32`, `DropdownButtonFormField.value` -> `initialValue`) were completely resolved.
- All linter hints (flow control braces, unnecessary imports, and private mutable field declarations) were completely cleaned.

---

## 3. Command Execution & Exit Codes Audit

| Command | Exit Code | Outcome |
| :--- | :--- | :--- |
| `flutter pub get` | **0** | Dependencies resolved cleanly. |
| `flutter analyze` | **0** | **Zero issues / zero warnings**. |
| `flutter test` | **0** | **22 / 22 unit & widget tests passed (100%)**. |
| `flutter build linux --release` | **1** | Halted: System build tools (`cmake`, `ninja`, `clang`, `libgtk-3-dev`) missing from test container. |

---

## 4. Release Executable Verification

- **Target Path**: `build/linux/x64/release/bundle/`
- **Result**: Not generated on host.
- **Root Cause**: `flutter build linux --release` requires CMake and GTK 3 development headers to be installed via `sudo apt install -y clang cmake ninja-build g++ pkg-config libgtk-3-dev`. In accordance with project instructions, unprompted root/sudo installation was not performed.
- **Physical Hardware Verification**: Remains **EXPLICITLY PENDING** as the physical Ant Esports MK1300 V2 keyboard is not attached to the host USB bus.

---

## 2. Static Analysis Audit (`flutter analyze`)

- **Total Issues**: **0 issues found** (Exit Code: **0**).
- All deprecations (`withOpacity` -> `withValues`, `color.value` -> `toARGB32`, `DropdownButtonFormField.value` -> `initialValue`) were completely resolved.
- All linter hints (flow control braces, unnecessary imports, and private mutable field declarations) were completely cleaned.

---

## 3. Command Execution & Exit Codes Audit

| Command | Exit Code | Outcome |
| :--- | :--- | :--- |
| `flutter pub get` | **0** | Dependencies resolved cleanly. |
| `flutter analyze` | **0** | **Zero issues / zero warnings**. |
| `flutter test` | **0** | **18 / 18 unit tests passed (100%)**. |
| `flutter build linux --release` | **1** | Halted: System build tools (`cmake`, `ninja`, `clang`, `libgtk-3-dev`) missing from test container. |

---

## 4. Release Executable Verification

- **Target Path**: `build/linux/x64/release/bundle/`
- **Result**: Not generated on host.
- **Root Cause**: `flutter build linux --release` requires CMake and GTK 3 development headers to be installed via `sudo apt install -y clang cmake ninja-build g++ pkg-config libgtk-3-dev`. In accordance with project instructions, unprompted root/sudo installation was not performed.
- **Physical Hardware Verification**: Remains **EXPLICITLY PENDING** as the physical Ant Esports MK1300 V2 keyboard is not attached to the host USB bus.
