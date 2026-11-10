# MK1300 V2 - Protocol & Command Reference

This document provides a comprehensive, bit-exact reference of all recovered USB HID commands for the **MK1300 V2 Mechanical Gaming Keyboard** (Vision 9520 MCU).

---

## 1. Low-Level Transport & Framing

- **Transport**: USB HID Interrupt Transfer.
- **Payload Size**: Exactly 64 bytes fixed length (`reportPayloadSize = 64`).
- **Buffer Length for Output Reports**: 65 bytes where byte 0 is Report ID `0x00`, followed by the 64-byte payload.
- **Report ID**: `0x00` (unnumbered reports).
- **Endianness**: Little-Endian (all 16-bit word offsets and values encode LSB first).
- **Control Interface**: Interface `1` (Vendor-defined HID collection: Usage Page `0xFF00`, Usage `0x0002`).

---

## 2. Command Index

| Operation | Command Code | Request Wire Structure | Response Expected | Verification |
|---|---|---|---|---|
| **Get Device Configuration** | `0x06, 0x05` | `[0x06, 0x05, 0x00, ...]` | 64-byte config response | **Source-verified** |
| **Get Active Lighting Config** | `0x06, 0x0A` | `[0x06, 0x0A, 0x00, ...]` | 64-byte lighting response | **Source-verified** |
| **Set Active Lighting Config** | `0x06, 0x0B` | `[0x06, 0x0B, 0x0B, 0, 0, type, 0, mode, brt, spd, dir, clrMode, 0, H, S, V, ...]` | None (or echo report) | **Source-verified** |
| **Query Effect Preset Defaults**| `0x06, 0x16` | `[0x06, 0x16, 0, 0, 0, 1, 0, mode, 0...]` | 64-byte preset response | **Source-verified** |
| **Set Active Profile** | `0x06, 0xFB` | `[0x06, 0xFB, profileIndex, 0...]` | None | **Source-verified** |
| **Set Inactivity Auto-Sleep** | `0x06, 0xFC` | `[0x06, 0xFC, 0x02, 0, 0, secLow, secHigh, 0...]` | None | **Source-verified** |
| **Restore Factory Defaults** | `0x06, 0x0F, 0xFF` | `[0x06, 0x0F, 0xFF, 0...]` | None | **Source-verified** |
| **Read Key Remap Chunk** | `0x06, 0x08` | `[0x06, 0x08, 0x3A, offL, offH, 0, layer, 0...]` | 64-byte chunk response | **Source-verified** |
| **Write Key Remap Chunk** | `0x06, 0x09` | `[0x06, 0x09, len, offL, offH, 0, layer, 0, ...chunkData]` | None | **Source-verified** |
| **Write Single Key Remap** | `0x06, 0x10` | `[0x06, 0x10, 0x07, offL, offH, 0, layer, 0, type, c1, c2, c3, 0...]` | None | **Source-verified** |
| **Read Custom Per-Key RGB** | `0x06, 0x13` | `[0x06, 0x13, 0x3A, offL, offH, 0...]` | 64-byte RGB response | **Source-verified** |
| **Write Custom Per-Key RGB** | `0x06, 0x12` | `[0x06, 0x12, len, offL, offH, 0, 0, 0, ...rgbData]` | None | **Source-verified** |
| **Write Single Key RGB** | `0x06, 0x14` | `[0x06, 0x14, 0x03, offL, offH, 0, 0, 0, R, G, B, 0...]` | None | **Source-verified** |
| **Read Macro Storage (4KB)** | `0x06, 0x0C` | `[0x06, 0x0C, len, offL, offH, 0...]` | 64-byte macro chunk | **Source-verified** |
| **Write Macro Storage (4KB)** | `0x06, 0x0D` | `[0x06, 0x0D, len, offL, offH, ...macroData]` | None | **Source-verified** |
| **Clear Macro Storage** | `0x06, 0x0F, 0x04` | `[0x06, 0x0F, 0x04, 0...]` | None | **Source-verified** |
| **Unsolicited Live Event** | `0xAA, 0xFA` | *Inbound broadcast from keyboard* | Live hardware notification | **Source-verified** |

---

## 3. Deep Command Field Breakdown

### 3.1 Get Device Configuration (`0x06, 0x05`)
- **Request**:
  - `Byte 0`: `0x06`
  - `Byte 1`: `0x05`
  - `Bytes 2..63`: `0x00`
- **Response Parsing**:
  - `Byte 0`: Root opcode echo (`0x06`)
  - `Byte 1`: Subcommand echo (`0x05`)
  - `Bytes 2..3`: Product ID echo (`buffer[2] | (buffer[3] << 8)`)
  - `Bytes 4..5`: Firmware version (`(buffer[5] << 8) | buffer[4]`, e.g. Major `buffer[5]`, Minor `buffer[4]`)
  - `Byte 6`: Work mode / connection medium (0 = USB Wired, 1 = 2.4GHz RF, 2 = Bluetooth)
  - `Byte 7`: Wireless link status
  - `Byte 8`: Battery percentage (0 to 100)
  - `Byte 9`: Battery charging state (1 = charging, 0 = discharging)
  - `Byte 10`: Supported hardware profiles count (3 profiles)
  - `Byte 11`: Currently active profile (0 = Profile 1, 1 = Profile 2, 2 = Profile 3)
  - `Byte 12`: Supported layers count (2 layers: Layer 0 Main, Layer 1 Fn)
  - `Byte 13`: Currently active layer (0 or 1)
  - `Bytes 14..15`: Auto-sleep timeout in seconds (`buffer[14] | (buffer[15] << 8)`)
  - `Bytes 16..31`: Keyboard serial number string (ASCII)

### 3.2 Set Active Lighting Config (`0x06, 0x0B`)
- **Request Structure**:
  - `Byte 0`: `0x06` (Root opcode)
  - `Byte 1`: `0x0B` (Subcommand)
  - `Byte 2`: `0x0B` (Payload parameter length: 11 bytes)
  - `Byte 3`: `0x00`
  - `Byte 4`: `0x00`
  - `Byte 5`: `type` (1 = Standard lighting mode)
  - `Byte 6`: `0x00`
  - `Byte 7`: `mode` (Lighting mode index 0 to 21)
  - `Byte 8`: `brightness` (Level 0 to 4)
  - `Byte 9`: `speed` (Level 0 to 4)
  - `Byte 10`: `direction` (0 = Left/Top, 1 = Right/Bottom)
  - `Byte 11`: `colorMode` (0 = Dynamic Rainbow, 1 = Solid Color)
  - `Byte 12`: `0x00`
  - `Byte 13`: `hue` ($0\text{--}255 \to 0\text{--}360^\circ$: `Math.floor(h / 360 * 255)`)
  - `Byte 14`: `saturation` ($0\text{--}255 \to 0\text{--}100\%$: `Math.floor(s / 100 * 255)`)
  - `Byte 15`: `value` ($0\text{--}255 \to 0\text{--}100\%$: `Math.floor(v / 100 * 255)`)
  - `Bytes 16..63`: `0x00` Padding

### 3.3 Unsolicited Live Event Packet (`0xAA, 0xFA`)
- **Direction**: Inbound (Keyboard Interrupt IN endpoint $\to$ Host)
- **Header**:
  - `Byte 0`: `0xAA` (170)
  - `Byte 1`: `0xFA` (250)
  - `Byte 2`: `0x09` (Payload length: 9 bytes)
  - `Bytes 3..5`: `0x00` Padding
- **Payload**:
  - `Byte 6`: `type` (1)
  - `Byte 7`: `mode` (0 to 21)
  - `Byte 8`: `brightness` (0 to 4)
  - `Byte 9`: `speed` (0 to 4)
  - `Byte 10`: `direction` (0 or 1)
  - `Byte 11`: `colorMode` (0 or 1)
  - `Byte 12`: `h` ($0\text{--}255$)
  - `Byte 13`: `s` ($0\text{--}255$)
  - `Byte 14`: `v` ($0\text{--}255$)
  - `Bytes 15..63`: `0x00` Padding
- **Trigger**: Dispatched automatically by MCU when user changes lighting via onboard Fn shortcuts (e.g. `Fn + \`, `Fn + Enter`).

### 3.3 Single Key Remapping (`0x06, 0x10`)
- **Request Structure**:
  - `Byte 0`: `0x06`
  - `Byte 1`: `0x10`
  - `Byte 2`: `0x07` (Parameter length)
  - `Byte 3`: `(4 * keyIndex) & 0xFF` (Little-Endian byte offset low)
  - `Byte 4`: `(4 * keyIndex) >> 8` (Little-Endian byte offset high)
  - `Byte 5`: `0x00`
  - `Byte 6`: `layer` (0 = Main Layer, 1 = Fn Layer)
  - `Byte 7`: `0x00`
  - `Byte 8`: `type` (Action type: standard key, media, macro, mouse, disabled)
  - `Byte 9`: `code1` (Modifier mask or primary code)
  - `Byte 10`: `code2` (HID usage keycode or macro index)
  - `Byte 11`: `code3` (Extended parameters or 0)
  - `Bytes 12..63`: `0x00`

### 3.4 Inbound Live Event Broadcast (`0xAA, 0xFA`)
When a user presses hardware shortcut keys on the keyboard (such as `Fn + \|` to toggle lighting effects or `Fn + Up/Down` for brightness), the Vision 9520 MCU immediately sends an unsolicited report on Interface 1:
- `Byte 0`: `0xAA`
- `Byte 1`: `0xFA`
- `Byte 2`: Event type (e.g. `0x02` for lighting state change)
- `Byte 3`: Reserved
- `Byte 4`: Current lighting type
- `Byte 5`: Current lighting mode (0–21)
- `Byte 6`: Current brightness (0–4)
- `Byte 7`: Current speed (0–4)
- `Byte 8`: Current direction (1 or 2)
- `Byte 9`: Current color mode (0 or 1)
- `Byte 10`: Current Hue (0–255)
- `Byte 11`: Current Saturation (0–255)
- `Byte 12`: Current Value (0–255)
- The Flutter client parses this packet and updates UI sliders and swatches in real-time.

---

## 4. Communication Flow & Command Queueing

All USB communications must flow through a serialized command queue:
```mermaid
sequenceDiagram
    participant UI as Flutter UI Action
    participant SVC as KeyboardService
    participant Q as CommandQueue
    participant HID as hidapi Native C-FFI
    participant DEV as Keyboard (Vision 9520)

    UI->>SVC: setLightingMode(mode)
    SVC->>Q: writeAndReadCommand(packet)
    Note over Q: Queue locks mutex; ensures single-flight packet
    Q->>HID: hid_write(handle, 65-byte buf)
    HID->>DEV: USB Interrupt OUT (EP 0x01)
    DEV-->>HID: USB Interrupt IN (EP 0x81)
    HID-->>Q: hid_read_timeout(handle, 64-byte buf, 1000ms)
    Q-->>SVC: Return 64-byte response
    SVC-->>UI: Update reactive StateNotifier
```

### Safety & Timeout Rules
1. **Single-Flight Rule**: Never issue concurrent `hid_write` calls without waiting for the response or a 1000ms timeout.
2. **Chunk Spacing**: When writing 4KB Macro EEPROM or Keymap tables, enforce an inter-packet delay of $\ge 10\text{ ms}$ to give the Vision 9520 MCU internal EEPROM write cycle time to settle.
3. **Flashing Prohibition**: Commands `0x55` and `0x5A` (bootloader entry / ISP flash) are prohibited in initial and standard application builds to eliminate bricking hazards.
