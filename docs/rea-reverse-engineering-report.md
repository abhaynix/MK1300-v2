# MK1300 V2 - REA Reverse Engineering Report

## 1. Executive Summary & Methodology

This report details the technical findings obtained through static analysis, bundle disassembly, AST traversal, and decompilation of the original Windows application installer (`MK1300-V21-0-0.exe`) and its extracted Electron bundle (`extracted/unpacked/`).

Reverse engineering was conducted using:
* **Binary & ASAR Extraction**: Decompression of the NSIS installer payload and extraction of `app.asar`.
* **Renderer & Main Process Disassembly**: Inspection of `main/index.js`, `main/utils/comm.js`, `main/assets/vid_pid_offline.js`, and Webpack Next.js bundles (`build/_next/static/chunks/app/page-1d7c89b2cab3983d.js`, `8494-*.js`).
* **Protocol Reconstruction**: Extraction of exact byte serialization routines, command-response state machines, and hardware EEPROM compilation tables.

---

## 2. Original Application Architecture

### 2.1 Technology Stack
* **Framework**: Electron (v28+) hosting a Next.js / React single-page application.
* **Component Framework**: Chakra UI with Tailwind CSS.
* **Hardware Interfacing**: Chromium WebHID API (`navigator.hid`) directly accessed from the renderer process via WebHID permissions configured in the Electron main process (`main/index.js`).
* **Bypass Policy**: Electron switches include `--disable-hid-blocklist` to enable raw report exchange with top-level keyboard collections (`Usage Page: 0xFF00`).

### 2.2 USB HID Device Identification
From `main/assets/vid_pid_offline.js`:
* **Vendor ID (VID)**: `0x36AE` (13998 decimal)
* **Product ID (PID)**: `0xFE12` (65042 decimal)
* **Usage Page**: `0xFF00` (Vendor-defined 65280)
* **Usage**: `0x0002` (Vendor Usage 2)
* **Hardware Label**: `XH-XJ-RS6/Q6 有华Z61-ARGB` (Xinhengwei / Youhua Z61 ARGB 60% mechanical keyboard, powered by Vision 9520 MCU).
* **Interface**: Interface 1 (Raw Vendor Control Interface). Interface 0 is reserved for standard OS boot keyboard input reports.

---

## 3. Protocol Command & Packet Framing

All commands use fixed 64-byte interrupt reports transmitted over USB HID. In Linux `hidraw` and standard HIDAPI, a leading Report ID byte `0x00` is prepended (total 65 bytes).

### 3.1 Command Hierarchy
Every packet starts with root opcode `0x06`, followed by a subcommand identifier.

| Subcommand | Name | Direction | Packet Structure | Evidence Classification |
|---|---|---|---|---|
| `0x05` | Get Device Config | Request / Response | `[0x06, 0x05, 0x00...]` -> 64-byte response | **Source-verified** |
| `0x08` | Read Keymap Chunk | Request / Response | `[0x06, 0x08, 0x3A, offL, offH, 0, layer, 0...]` -> 64-byte response (56B payload at byte 8) | **Source-verified** |
| `0x09` | Write Keymap Chunk | Request only | `[0x06, 0x09, len, offL, offH, 0, layer, 0, ...56B data]` | **Source-verified** |
| `0x0A` | Get Lighting Config | Request / Response | `[0x06, 0x0A, 0x00...]` -> response with parameters at bytes 5..15 | **Source-verified** |
| `0x0B` | Set Lighting Config | Request only | `[0x06, 0x0B, 11, 0, 0, type, 0, mode, brt, spd, dir, clrMode, 0, H, S, V]` | **Source-verified** |
| `0x0C` | Read Macro Chunk | Request / Response | `[0x06, 0x0C, len, offL, offH, 0...]` -> 56B payload at byte 8 | **Source-verified** |
| `0x0D` | Write Macro Chunk | Request only | `[0x06, 0x0D, len, offL, offH, ...59B data]` | **Source-verified** |
| `0x0F, 0x04` | Reset Macro Data | Request only | `[0x06, 0x0F, 0x04, 0...]` | **Source-verified** |
| `0x0F, 0xFF` | Restore Factory Defaults | Request only | `[0x06, 0x0F, 0xFF, 0...]` | **Source-verified** (Safety Gated) |
| `0x10` | Write Single Key | Request only | `[0x06, 0x10, 0x07, offL, offH, 0, layer, 0, type, c1, c2, c3]` | **Source-verified** |
| `0x12` | Write Per-Key RGB Chunk | Request only | `[0x06, 0x12, len, offL, offH, 0, 0, 0, ...56B data]` | **Source-verified** |
| `0x13` | Read Per-Key RGB Chunk | Request / Response | `[0x06, 0x13, 0x3A, offL, offH, 0...]` -> 56B payload at byte 8 | **Source-verified** |
| `0x14` | Write Single Key RGB | Request only | `[0x06, 0x14, 0x03, offL, offH, 0, 0, 0, R, G, B]` (off = 3*keyIndex) | **Source-verified** |
| `0x16` | Query Lighting Effect Preset | Request / Response | `[0x06, 0x16, 0, 0, 0, 1, 0, mode]` -> returns default params | **Source-verified** |
| `0xFB` | Set Active Profile | Request only | `[0x06, 0xFB, profileIndex, 0...]` | **Source-verified** |
| `0xFC` | Set Sleep Timeout | Request only | `[0x06, 0xFC, 0x02, 0x00, 0x00, sleepL, sleepH, 0...]` | **Source-verified** |
| `0xAA, 0xFA` | Live Event Broadcast | Inbound Report | `[0xAA, 0xFA, 0x02, ..., mode, brt, spd, dir, clr, H, S, V]` | **Source-verified** |

---

## 4. Reverse Engineering Findings by Feature

### 4.1 Lighting Engine & 22 Effects
* **Modes**: Exactly 22 hardware lighting presets (indices `0` to `21`).
* **Parameter Ranges**:
  * Brightness: 5 levels (`0` = Off, `1` to `4` = Max).
  * Speed: 5 levels (`0` = Slowest, `4` = Fastest).
  * Direction: Mode dependent:
    * `1` = Left-to-Right / Inward.
    * `2` = Bottom-to-Top / Outward.
  * Color Mode: `0` = Dynamic Rainbow spectrum, `1` = Single static color.
* **Color Encoding**:
  * On-wire HSV format: Hue scaled to `[0, 255]` (`H * 255 / 360`), Saturation scaled to `[0, 255]` (`S * 255 / 100`), Value scaled to `[0, 255]` (`V * 255 / 100`).

### 4.2 Key Remapping & Layout Architecture
* **Physical Layout**: 61 active physical keys matching `assets/data/36ae_fe12.json` with indices ranging from 0 to 73 (13 matrix gaps).
* **Multi-Layer Support**:
  * Layer 0: Main default typing layer.
  * Layer 1: Secondary Fn layer.
* **Wire Tuple Format**: 4 bytes per key: `[new_type, new_code1, new_code2, new_code3]`.
  * Type 32 (`0x20`): Standard HID key (`code2` = HID usage ID, `code1` = modifier mask).
  * Type 48 (`0x30`): Consumer media control (`code1` = consumer usage code).
  * Type 16 (`0x10`): Mouse action (`code1` = button bitmask, `code3` = wheel).
  * Type 31 (`0x1F`): Keyboard hardware control (lighting, brightness, lock).
  * Type 96 (`0x60`): Macro trigger (`code1` = macro index `0..15`, `code2 = 1`).
  * Type 255 (`0xFF`): Custom modifier combination.

### 4.3 Macro Studio & 4KB EEPROM Layout
* **Capacity**: Up to 16 macro slots (`M0` to `M15`) stored in a 4096-byte non-volatile memory block.
* **Header Structure (Bytes 0 to 63)**: 16-bit little-endian pointers to the action arena for each of the 16 macro slots. Unused slots contain `0xFF, 0xFF`.
* **Action Arena (Byte 64 to 4095)**: Sequential list of 4-byte action elements:
  * `Bytes 0..1`: 16-bit Little-Endian delay in milliseconds (`0` to `10000`).
  * `Byte 2`: Action flags:
    * `Bit 6` (`0x40`): Key Press / Down (1 = Press, 0 = Release).
    * `Bit 7` (`0x80`): End of macro terminator flag (1 = Last action).
    * `Bits 0..5`: Action type (`2` = Keyboard, `3` = Mouse Button, `4` = Vertical Scroll, `5` = Horizontal Scroll).
  * `Byte 3`: Target keycode or button bitmask.

### 4.4 Profiles & Settings
* **Profiles**: 3 hardware profiles (`0`, `1`, `2`). Switched via `CMD 0x06, 0xFB`.
* **Sleep Timeout**: Supported intervals: `0` (Always on), `120s` (2 min), `300s` (5 min), `600s` (10 min), `1800s` (30 min). Configured via `CMD 0x06, 0xFC`.

---

## 5. REA Evidence Classification Matrix

| Finding | REA Evidence Source | Location | Classification |
|---|---|---|---|
| Vendor ID (`0x36AE`) & Product ID (`0xFE12`) | Extracted JS source | `main/assets/vid_pid_offline.js` | **Source-verified** |
| Raw HID Usage Page (`0xFF00`), Usage (`0x0002`) | Extracted JS source | `main/assets/vid_pid_offline.js` | **Source-verified** |
| 64-Byte Report Framing with byte 0 Report ID | Extracted JS source | `page-*.js` `webhid_send_command` | **Source-verified** |
| Config Query (`0x06, 0x05`) Response Layout | Extracted JS source | `page-*.js` `getKeyboardConfig` | **Source-verified** |
| 22 Lighting Modes & Direction Values | Extracted JSON & JS | `assets/data/36ae_fe12.json`, `page-*.js` | **Source-verified** |
| Single Key Remap (`0x06, 0x10`) Tuple Encoding | Extracted JS source | `page-*.js` `setKeyInfo` | **Source-verified** |
| Keymap Chunk Read/Write (`0x08`, `0x09`) Offsets | Extracted JS source | `page-*.js` `getCurKeyInfosData` | **Source-verified** |
| 4KB Macro Arena & 4-Byte Action Structure | Extracted JS source | `page-*.js` functions `A` & `D` | **Source-verified** |
| Profile Switching (`0x06, 0xFB`) | Extracted JS source | `page-*.js` `setCurrentProfile` | **Source-verified** |
| Auto Sleep Setting (`0x06, 0xFC`) | Extracted JS source | `page-*.js` `setAutoSleepTime` | **Source-verified** |
| Unsolicited Event (`0xAA, 0xFA`) Broadcast | Extracted JS source | `page-*.js` `addListeners` | **Source-verified** |
| Fn Layer 1 Factory Key Defaults | Industry 60% Conventions | `docs/key-remapping.md` | **Inferred** |
| MCU PWM & Physical LED Optics | Hardware Measurement | Physical Keyboard Required | **Hardware-unverified (Pending)** |
| Physical Non-Root Access & Udev Rules | OS Kernel Semantics | Linux `hidraw` Subsystem | **Runtime-verified (Linux Mock)** |
