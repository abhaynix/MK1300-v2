# Ant Esports MK1300 V2 - Hardware Test Results Matrix

**Test Environment**: Ubuntu 26.04.1 LTS x86_64, Dart 3.13.7, Flutter 3.47.9  
**Target Hardware**: Ant Esports MK1300 V2 (VID `0x36AE`, PID `0xFE12`)  
**Evaluation Date**: 2026-11-07  

---

## 1. Test Results Summary

| Test Identifier | Category | Test Description | Result | Evidence / Notes |
| :--- | :--- | :--- | :--- | :--- |
| **TEST-LINUX-ENV** | Environment | Linux build environment audit | **PASS** | Linux 7.0 kernel, Ubuntu 26.04, Dart 3.13.7, Flutter 3.47.9 verified. Missing optional packages recorded. |
| **TEST-HIDAPI-INSTALL** | Dependency | System `hidapi` shared libraries check | **BLOCKED** | `libhidapi-hidraw0` is not installed on test host. Application falls back to `MockHidDevice`. |
| **TEST-USB-ENUM** | USB Discovery | USB device bus enumeration (`lsusb`) | **PASS** | Bus scanned; other USB devices identified (`1d6b`, `3151:3020`, etc.). |
| **TEST-DEV-IDENT** | Identification | MK1300 V2 device identification (`36ae:fe12`)| **BLOCKED** | Physical keyboard is not connected to USB bus. |
| **TEST-HID-DESC** | Descriptors | HID report descriptor inspection | **BLOCKED** | Requires physical device to read kernel report descriptor. |
| **TEST-NONROOT-ACC** | Permissions | Non-root access verification | **NOT TESTED** | Blocked by absence of physical hardware. Verified udev rule documented. |
| **TEST-FFI-LOAD** | Native FFI | Native `hidapi` dynamic library loading | **FAIL** (Host) | FFI open calls fail because `libhidapi-hidraw.so.0` is missing from system path. Gracefully handled in Dart. |
| **TEST-DEV-OPEN** | Connection | Open device handle without root | **BLOCKED** | Physical device not connected. |
| **TEST-READONLY-CMD**| Protocol | Dispatch read-only query `CMD 0x06, 0x05` | **BLOCKED** | Physical device not connected. |
| **TEST-RESP-PARSE** | Protocol | Parse 64-byte device config response | **PASS** (Sim) | Unit tests in `test/packet_serialization_test.dart` verified response parsing against simulated buffer. |
| **TEST-RESOURCE-CLEAN**| Lifecycle | Resource cleanup and memory freeing | **PASS** | `calloc.free` and `hid_close` audit verified; stream controllers closed cleanly. |

---

## 2. Command Details & Transmitted/Received Hex Data

### Read-Only Query (`CMD 0x06, 0x05`)

#### Wire Packet Specification (Validated)
- **Report ID**: `0x00`
- **Payload Length**: 64 bytes
- **Host Output Buffer (65 Bytes Hex)**:
```text
00 06 05 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00
```

#### Physical Hardware Transmission Status
- **Status**: **BLOCKED** (Physical keyboard not connected).
- **Simulated Hardware Response**: Successfully verified with `MockHidDevice` returning firmware v1.0, 92% battery, and 3 supported profiles.
