# Final Technical Specification: Ant Esports MK1300 V2 Linux Desktop Application

## 1. Document Overview & Scope

### 1.1 Purpose
This document constitutes the definitive, internally consistent technical implementation specification for the **Ant Esports MK1300 V2 Linux Desktop Application**. It synthesizes all reverse-engineering findings, protocol specifications, data structures, and user experience requirements into a comprehensive guide for Linux-first development.

### 1.2 Target Hardware
- **Hardware**: Ant Esports MK1300 V2 Mechanical Gaming Keyboard (61-Key ARGB, ANSI 60% Form Factor).
- **Controller**: Vision / YinHua 9520 USB HID Microcontroller.
- **Hardware Architecture**: USB wired and 2.4GHz/BT wireless dual-mode controller with onboard flash memory (EEPROM).

### 1.3 Target Operating System
- **Platform**: Linux Desktop Only.
- **Primary Distribution**: Ubuntu Linux (22.04 LTS, 24.04 LTS x86_64).
- **Secondary Compatibility**: Debian 12+, Fedora 39+, Arch Linux.
- **Explicit Exclusions**: Windows, macOS, iOS, Android, and Web platforms are strictly excluded.

### 1.4 Technology Stack
- **Application Framework**: Native Flutter Desktop (GTK 3.0 embedding).
- **Programming Language**: Dart 3.x (sound null safety).
- **Hardware Layer**: Native Linux USB HID via direct C-FFI binding to dynamic `libhidapi-hidraw.so` (with fallback to `libhidapi-libusb.so`).
- **State Management**: Reactive `ChangeNotifier` and unidirectional data streams.

### 1.5 Goals & Non-Goals
- **Functional Goals**:
  - Reproduce 100% of the original keyboard software's functionality without Electron or Chromium dependencies.
  - Native Linux USB HID device discovery, safe read/write operations, and real-time live event decoding without requiring `root` or `sudo`.
  - Comprehensive lighting control across all 22 preset animation modes, custom per-key ARGB matrix, and firmware HSV conversions.
  - Complete 61-key ANSI physical visualizer with Main and Fn layer remapping across standard, multimedia, mouse, and shortcut categories.
  - 16-slot Macro Studio with keystroke recording and 4096-byte EEPROM compilation/decompilation.
  - High-fidelity offline hardware simulation (`MockHidDevice`) allowing complete UI operation, previews, and testing without physical hardware attached.
- **Non-Goals**:
  - Firmware flashing / ISP bootloader execution is strictly excluded to prevent permanent bricking risks.
  - Cross-platform Windows or macOS packaging is explicitly excluded.

---

## 2. Hardware Specification & USB Parameters

| Parameter | Specification | Evidence Classification | Verification Reference |
|---|---|---|---|
| **Device Model** | Ant Esports MK1300 V2 | **Source-verified** | `main/assets/vid_pid_offline.js` |
| **Internal Designation** | `RS0-61K-ARGB` | **Source-verified** | `assets/data/36ae_fe12.json` |
| **Microcontroller (MCU)** | Vision 9520 (`mcu_type: "9520"`) | **Source-verified** | `assets/data/36ae_fe12.json` |
| **Vendor ID (VID)** | `0x36AE` (Decimal `13998`) | **Source-verified** | `main/assets/vid_pid_offline.js` |
| **Product ID (PID)** | `0xFE12` (Decimal `65042`) | **Source-verified** | `main/assets/vid_pid_offline.js` |
| **USB Interface** | Interface `1` (Vendor Control Collection) | **Source-verified** | WebHID filter in `main/index.js` |
| **HID Usage Page** | `0xFF00` (Decimal `65280`, Vendor-Defined) | **Source-verified** | `main/assets/vid_pid_offline.js` |
| **HID Usage** | `0x0002` (Decimal `2`, Vendor Device) | **Source-verified** | `main/assets/vid_pid_offline.js` |
| **Report ID** | `0x00` (Unnumbered reports) | **Source-verified** | `sendReport(0, l)` in `comm.js` |
| **Report Payload Size** | 64 bytes fixed length | **Source-verified** | `comm.js` packet buffers |
| **Host Write Buffer** | 65 bytes (Byte 0: `0x00`, Bytes 1..64: Payload)| **Source-verified** | Linux kernel `hidraw` write semantics |
| **Endianness** | Little-Endian (LSB first) | **Source-verified** | `buffer[0] \| (buffer[1] << 8)` |

---

## 3. USB HID Protocol Specification

### 3.1 Report Framing
All host-to-device requests and device-to-host responses are framed as fixed 64-byte payload reports. Root opcode `0x06` governs all standard configuration commands.

### 3.2 Master Protocol Command Reference

| Function | Command Code | Request Format | Response Format | Classification |
|---|---|---|---|---|
| **Get Device Configuration** | `0x06, 0x05` | `[0x06, 0x05, 0x00, ...]` | 64-byte config packet | **Source-verified** |
| **Get Active Lighting** | `0x06, 0x0A` | `[0x06, 0x0A, 0x00, ...]` | 64-byte lighting packet | **Source-verified** |
| **Set Active Lighting** | `0x06, 0x0B` | `[0x06, 0x0B, 0x0B, 0, 0, Type, 0, Mode, Brightness, Speed, Dir, Color, 0, H, S, V, ...]` | Echo / None | **Source-verified** |
| **Query Effect Preset** | `0x06, 0x16` | `[0x06, 0x16, 0, 0, 0, 1, 0, Mode, 0...]` | 64-byte preset packet | **Source-verified** |
| **Set Active Profile** | `0x06, 0xFB` | `[0x06, 0xFB, ProfileIndex, 0...]` | None | **Source-verified** |
| **Set Auto-Sleep Time** | `0x06, 0xFC` | `[0x06, 0xFC, 0x02, 0, 0, SecLow, SecHigh, 0...]` | None | **Source-verified** |
| **Restore Factory Defaults** | `0x06, 0x0F, 0xFF` | `[0x06, 0x0F, 0xFF, 0...]` | None | **Source-verified** |
| **Read Keymap Chunk** | `0x06, 0x08` | `[0x06, 0x08, 0x3A, OffL, OffH, 0, Layer, 0...]` | 64-byte keymap chunk | **Source-verified** |
| **Write Keymap Chunk** | `0x06, 0x09` | `[0x06, 0x09, Len, OffL, OffH, 0, Layer, 0, ...keys]` | None | **Source-verified** |
| **Write Single Key Remap** | `0x06, 0x10` | `[0x06, 0x10, 0x07, OffL, OffH, 0, Layer, 0, Type, C1, C2, C3, 0...]` | None | **Source-verified** |
| **Read Per-Key RGB** | `0x06, 0x13` | `[0x06, 0x13, 0x3A, OffL, OffH, 0...]` | 64-byte RGB chunk | **Source-verified** |
| **Write Per-Key RGB** | `0x06, 0x12` | `[0x06, 0x12, Len, OffL, OffH, 0, 0, 0, ...RGBs]` | None | **Source-verified** |
| **Write Single-Key RGB** | `0x06, 0x14` | `[0x06, 0x14, 0x03, OffL, OffH, 0, 0, 0, R, G, B, 0...]` | None | **Source-verified** |
| **Read Macro Storage (4KB)** | `0x06, 0x0C` | `[0x06, 0x0C, Len, OffL, OffH, 0...]` | 64-byte macro chunk | **Source-verified** |
| **Write Macro Storage (4KB)** | `0x06, 0x0D` | `[0x06, 0x0D, Len, OffL, OffH, ...chunkData]` | None | **Source-verified** |
| **Reset Macro Memory** | `0x06, 0x0F, 0x04` | `[0x06, 0x0F, 0x04, 0...]` | None | **Source-verified** |
| **Live Broadcast Event** | `0xAA, 0xFA` | *Inbound broadcast report from keyboard* | Hardware state notification | **Source-verified** |

### 3.3 Command Queue & Asynchronous Safety
- USB HID requests must be serialized through `CommandQueue`.
- Concurrent writes are blocked by an internal mutex lock.
- Fixed response read timeout of 1000ms prevents thread starvation.
- Inter-packet write delay of $\ge 10\text{ ms}$ must be enforced for bulk flash writes (macros and keymaps).

---

## 4. Lighting Specification & Vision HSV Model

### 4.1 Preset Modes (22 Modes)
All 22 modes recovered from `36ae_fe12.json` with parameter control flags:
- `0`: Off
- `1`: Static (常亮) — Brightness, Color
- `2`: Breathing (呼吸) — Brightness, Speed, Color
- `3`: Neon / Rotate (旋转) — Brightness, Speed, Color
- `4`: Spectrum Cycle (色谱循环) — Brightness, Speed, Color
- `5`: Horizontal Streamer (左右流光) — Brightness, Speed, Direction, Color
- `6`: Bloom / Ripple (绽放) — Brightness, Speed, Direction, Color
- `7`: Vertical Streamer (上下流光) — Brightness, Speed, Direction, Color
- `8`: Reactive (按亮) — Brightness, Speed, Color
- `9`: Sine Wave (正弦波) — Brightness, Speed, Color
- `10`: Tai Chi (太极) — Brightness, Speed, Color
- `11`: Gather (聚集) — Brightness, Speed, Color
- `12`: Shuttle (穿梭) — Brightness, Speed, Color
- `13`: Twin Flowers (一石二鸟) — Brightness, Speed, Color
- `14`: Meteor (流星) — Brightness, Speed, Direction, Color
- `15`: Grid / Sudoku (九宫格) — Brightness, Speed, Color
- `16`: Wheel (车轮) — Brightness, Speed, Color
- `17`: Tide (潮汐) — Brightness, Speed, Color
- `18`: Snake (贪吃蛇) — Brightness, Speed, Color
- `19`: Circles (画圈) — Brightness, Speed, Color
- `20`: Shooting Star (流星2) — Brightness, Speed, Color
- `21`: Laser / Cross (交叉点亮) — Brightness, Speed, Color

### 4.2 Firmware HSV Conversion Formula
The Vision 9520 MCU uses byte-scaled HSV values:
- **Hue**: $H_{\text{byte}} = \text{round}\left(\frac{\text{hue}^\circ \times 255}{360}\right)$
- **Saturation**: $S_{\text{byte}} = \text{round}\left(\text{sat} \times 255\right)$
- **Value**: $V_{\text{byte}} = \text{round}\left(\text{val} \times 255\right)$

Inverse conversion from hardware bytes:
- $\text{hue}^\circ = \frac{360.0 \times H_{\text{byte}}}{255.0}$
- $\text{sat} = \frac{S_{\text{byte}}}{255.0}$
- $\text{val} = \frac{V_{\text{byte}}}{255.0}$

---

## 5. Keyboard Geometry & Key Remapping

### 5.1 Physical Switch Matrix
- Form factor: Compact ANSI 60% (61 mechanical switches).
- Electrical switch matrix: 5 Rows × 15 Columns (Indices 0 to 73).
- Unused matrix gap positions: 14, 29, 44, 46, 57, 59, 63, 64, 65, 67, 68, 69.
- Layers: Layer 0 (Main Layer) and Layer 1 (Fn Layer).

### 5.2 Key Remap Record Structure
Each key assignment is represented as a 4-byte descriptor:
```
Byte 0: Action Type (32 = Standard Key, 33 = Media, 34 = Mouse, 35 = Shortcut, 36 = Macro, 0 = Disabled)
Byte 1: Code 1 (Modifier bitmask: 0x01=Ctrl, 0x02=Shift, 0x04=Alt, 0x08=Win)
Byte 2: Code 2 (HID Usage Keycode or Macro Index)
Byte 3: Code 3 (Auxiliary parameter or 0)
```

---

## 6. Macro Storage Specification (4096-Byte Arena)

### 6.1 Memory Layout
- **Total Capacity**: 4096 bytes onboard EEPROM.
- **Pointer Table**: Bytes 0 to 63 contain sixteen 16-bit Little-Endian offsets pointing to the start of each macro.
- **Unassigned Pointer**: Initialized to `0xFFFF`.
- **Action Records**: Sequentially packed starting at byte offset 64.

### 6.2 Action Record Format (4 Bytes)
```
Byte 0: Delay Low Byte (delay & 0xFF)
Byte 1: Delay High Byte ((delay >> 8) & 0xFF)
Byte 2: Flags:
        Bit 7: isLast (1 = final action of macro sequence, 0 = continues)
        Bit 6: isPress (1 = Key Down / Press, 0 = Key Up / Release)
        Bits 0..5: Action Type (1 = Keyboard Key, 2 = Mouse Button)
Byte 3: Keycode / Button Identifier
```

---

## 7. Linux Platform & udev Requirements

### 7.1 udev Non-Root Device Permissions
To allow non-root users access to `/dev/hidraw*` devices, install `/etc/udev/rules.d/99-antesports-mk1300.rules`:
```udev
KERNEL=="hidraw*", ATTRS{idVendor}=="36ae", ATTRS{idProduct}=="fe12", MODE="0660", TAG+="uaccess", GROUP="plugdev"
SUBSYSTEM=="usb", ATTRS{idVendor}=="36ae", ATTRS{idProduct}=="fe12", MODE="0660", TAG+="uaccess", GROUP="plugdev"
```

### 7.2 Native Library Loading
The Dart FFI binding links to `libhidapi-hidraw.so.0` on Linux, falling back gracefully to `MockHidDevice` if hardware or native libraries are missing.

---

## 8. UI/UX Specification

### 8.1 Design Tokens
- **Background**: `#18181B` (Deep Dark Gaming Slate)
- **Panel / Surface**: `#274A71` / `#181B24` (Subtle Glassmorphic Contrast)
- **Accent**: `#6BC4FF` (Electric Cyan)
- **Success / Online**: `#4ADE80` (Vibrant Neon Green)
- **Error / Offline**: `#EF4444` (Vibrant Red)

### 8.2 Shell Layout
- **Top Bar**: Connection status pill (`DEVICE CONNECTED` / `OFFLINE SIMULATOR`), battery monitor (`92%`), active layer badge (`MAIN LAYER` / `FN LAYER`), and profile selector (`P1`, `P2`, `P3`).
- **Sidebar**: Icons and labels for Dashboard, Lighting, Key Remap, Macro Studio, and Settings.
- **Central Canvas**: Real-time interactive 61-key visualizer reflecting switch states and lighting effects.

---

## 9. Security & Safety Rules

1. **No Root Requirement**: The application operates in standard user space with zero root/sudo escalation.
2. **Firmware Safeguard**: Flashing opcodes (`0x55`, `0x5A`) are excluded from source code to eliminate hardware bricking hazards.
3. **Reset Safeguard**: Factory reset command `0x06, 0x0F, 0xFF` is locked behind an explicit confirmation dialog.

---

## 10. Technical Specification Sign-Off

This document and its companion references in [`docs/`](file:///home/devx/Development/MK1300-V2/docs/) provide an exhaustive, evidence-verified foundation for all Linux desktop development.
