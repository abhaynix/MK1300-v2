# USB HID Protocol Specification: Ant Esports MK1300 V2

## 1. Hardware Overview

* **Keyboard Model**: Ant Esports MK1300 V2 (61-Key ARGB Compact Mechanical Gaming Keyboard)
* **Internal Code**: `RS0-61K-ARGB`
* **Controller MCU**: Vision / YinHua 9520 (`mcu_type: "9520"`)
* **Vendor ID (VID)**: `0x36AE` (Decimal 13998)
* **Product ID (PID)**: `0xFE12` (Decimal 65042)
* **HID Usage Page**: `0xFF00` (Vendor-defined 65280)
* **HID Usage**: `0x0002` (Vendor-defined usage 2)
* **HID Interface**: 1 (Vendor Control Interface)

---

## 2. Low-Level Framing & Report Transport

The keyboard uses standard USB HID interrupt endpoints with 64-byte report buffers.

* **Report ID**: `0x00` (Report ID 0 / unnumbered report)
* **Report Length**: 64 bytes payload
* **Transmission Mode**:
  * Host to Device: Output Report (or Feature Report) of 64 bytes.
  * Device to Host: Input Report of 64 bytes.
* **Endianness**: Multi-byte numeric fields are encoded in **Little-Endian** format (`byte[0] | (byte[1] << 8)`).

### Command Framing Structure
All configuration and query commands are constructed as 64-byte buffers:

```
Byte 0:  Command Group / Root Operation Code (e.g. 0x06)
Byte 1:  Subcommand / Function ID (e.g. 0x05, 0x0A, 0x08, 0x09, 0x0C, 0x0D, etc.)
Byte 2:  Data Length / Packet Length / Parameter
Byte 3..63: Parameters, Data Payloads, Chunk Offsets, or Key Mappings (Zero-padded to 64 bytes)
```

---

## 3. Protocol Command Reference

### Command Group 0x06 (Device Operations)

#### 3.1 Get Keyboard Hardware Configuration
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x05
  Byte 2..63: 0x00
  ```
* **Response Format**:
  ```
  Byte 0..4:   Header / Status
  Byte 5..6:   Hardware Version (uint16_t, Little-Endian)
  Byte 7..8:   Product ID (uint16_t, Little-Endian)
  Byte 9..10:  Firmware Version (uint16_t, Little-Endian)
  Byte 11:     Work Mode
  Byte 12:     Link Status (0 = Disconnected, 1 = Wired USB, 2 = 2.4G, 3 = BT)
  Byte 13:     Battery Level (0 - 100%)
  Byte 14:     Charging Status (0 = Not charging, 1 = Charging, 2 = Full)
  Byte 15:     Total Profiles Supported (e.g. 3)
  Byte 16:     Active Profile Index (0-based)
  Byte 17:     Total Layers Supported (e.g. 2: Main & Fn)
  Byte 18:     Active Layer Index (0 = Main, 1 = Fn)
  Byte 19..20: Auto Sleep Time in seconds (uint16_t, Little-Endian)
  Byte 21..42: Serial Number String (ASCII characters)
  Byte 43..63: Reserved
  ```

#### 3.2 Get Lighting Configuration
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x0A (10)
  Byte 2..63: 0x00
  ```
* **Response Format**:
  ```
  Byte 0..4: Header
  Byte 5:    Lighting Type
  Byte 6:    Reserved (0x00)
  Byte 7:    Active Lighting Mode (0 - 21)
  Byte 8:    Brightness Level (0 - 4 or 0 - 100%)
  Byte 9:    Speed Level (0 - 4)
  Byte 10:   Direction (1 = Left/Horizontal, 2 = Up/Vertical)
  Byte 11:   Color Mode (0 = Colorful / Dynamic, 1 = Single Color)
  Byte 12:   Single Color Preset Index (0 - 7)
  Byte 13:   Hue (H: 0 - 255 mapped to 0° - 360°)
  Byte 14:   Saturation (S: 0 - 255 mapped to 0 - 100%)
  Byte 15:   Value / Brightness (V: 0 - 255 mapped to 0 - 100%)
  ```

#### 3.3 Set Lighting Configuration
* **Request Packet**:
  ```
  Byte 0:  0x06
  Byte 1:  0x0B (11)
  Byte 2:  Payload Length (11 bytes: 0x0B)
  Byte 3:  0x00
  Byte 4:  0x00
  Byte 5:  Lighting Type
  Byte 6:  0x00
  Byte 7:  Mode (0 = Off, 1 = Static, 2 = Breathing, ..., 21 = Laser)
  Byte 8:  Brightness (0 - 4)
  Byte 9:  Speed (0 - 4)
  Byte 10: Direction (1 or 2)
  Byte 11: Color Mode (0 if mode == 0, else 1)
  Byte 12: 0x00
  Byte 13: Hue byte (H * 255 / 360)
  Byte 14: Saturation byte (S * 255 / 100)
  Byte 15: Value byte (V * 255 / 100)
  Byte 16..63: 0x00
  ```

#### 3.4 Query Default Lighting Effect Preset
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x16 (22)
  Byte 2..5: 0x00
  Byte 6: 0x01
  Byte 7: 0x00
  Byte 8: Target Lighting Mode (0 - 21)
  Byte 9..63: 0x00
  ```
* Returns default parameters for the specified lighting effect.

#### 3.5 Set Active Profile
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0xFB (251)
  Byte 2: Profile Index (0, 1, 2)
  Byte 3..63: 0x00
  ```

#### 3.6 Set Auto-Sleep Timeout
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0xFC (252)
  Byte 2: 0x02
  Byte 3: 0x00
  Byte 4: 0x00
  Byte 5: Timeout Seconds Low Byte (e.g. 120 = 0x78)
  Byte 6: Timeout Seconds High Byte (e.g. 120 = 0x00)
  Byte 7..63: 0x00
  ```

#### 3.7 Restore Factory Defaults
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x0F (15)
  Byte 2: 0xFF (255)
  Byte 3..63: 0x00
  ```

#### 3.8 Read Key Remapping Table (Chunked)
Keys are represented as 4-byte descriptors: `[new_type, new_code1, new_code2, new_code3]`.
Total size for 61 keys = 244 bytes.
Read in chunks of 56 payload bytes:

* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x08
  Byte 2: 0x3A (58)
  Byte 3: Offset Low Byte (0, 56, 112, 168, 224)
  Byte 4: Offset High Byte
  Byte 5: 0x00
  Byte 6: Layer (0 = Main Layer, 1 = Fn Layer)
  Byte 7..63: 0x00
  ```
* **Response Packet**:
  `Byte 8..63` contains up to 56 bytes of key mapping definitions.

#### 3.9 Write Key Remapping Table (Chunked)
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x09
  Byte 2: Chunk Length (59 or remainder + 3)
  Byte 3: Offset Low Byte
  Byte 4: Offset High Byte
  Byte 5: 0x00
  Byte 6: Layer (0 = Main, 1 = Fn)
  Byte 7: 0x00
  Byte 8..63: Key data payload (up to 56 bytes)
  ```

#### 3.10 Write Single Key Remap
* **Request Packet**:
  ```
  Byte 0:  0x06
  Byte 1:  0x10 (16)
  Byte 2:  0x07
  Byte 3:  (4 * key_index) & 0xFF
  Byte 4:  (4 * key_index) >> 8
  Byte 5:  0x00
  Byte 6:  Layer (0 = Main, 1 = Fn)
  Byte 7:  0x00
  Byte 8:  new_type
  Byte 9:  new_code1
  Byte 10: new_code2
  Byte 11: new_code3
  Byte 12..63: 0x00
  ```

#### 3.11 Read Custom Per-Key RGB Colors
Per-key color data is 3 bytes per key: `[R, G, B]`.
For 61 keys = 183 bytes.

* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x13 (19)
  Byte 2: 0x3A (58)
  Byte 3: Offset Low Byte
  Byte 4: Offset High Byte
  Byte 5..63: 0x00
  ```
* Response: `Byte 8..63` returns RGB triples.

#### 3.12 Write Custom Per-Key RGB Colors (Chunked)
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x12 (18)
  Byte 2: Chunk Length (59 or remainder + 3)
  Byte 3: Offset Low Byte
  Byte 4: Offset High Byte
  Byte 5..63: Payload (RGB triples)
  ```

#### 3.13 Write Single Key RGB Color
* **Request Packet**:
  ```
  Byte 0:  0x06
  Byte 1:  0x14 (20)
  Byte 2:  0x03
  Byte 3:  (3 * key_index) & 0xFF
  Byte 4:  (3 * key_index) >> 8
  Byte 5:  0x00
  Byte 6:  0x00
  Byte 7:  0x00
  Byte 8:  Red (0 - 255)
  Byte 9:  Green (0 - 255)
  Byte 10: Blue (0 - 255)
  Byte 11..63: 0x00
  ```

#### 3.14 Read Macro Storage (4096 Bytes)
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x0C (12)
  Byte 2: Chunk Length (56 bytes)
  Byte 3: Offset Low Byte (0, 56, 112, ...)
  Byte 4: Offset High Byte
  Byte 5..63: 0x00
  ```
* Response: `Byte 8..63` returns 56 bytes of macro storage.

#### 3.15 Write Macro Storage (Chunked)
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x0D (13)
  Byte 2: Chunk Length (up to 59 bytes)
  Byte 3: Offset Low Byte
  Byte 4: Offset High Byte
  Byte 5..63: Macro binary chunk data
  ```

#### 3.16 Clear All Macros
* **Request Packet**:
  ```
  Byte 0: 0x06
  Byte 1: 0x0F (15)
  Byte 2: 0x04
  Byte 3..63: 0x00
  ```

---

## 4. Unsolicited Inbound Hardware Events

The keyboard firmware broadcasts state changes over the HID interrupt endpoint:

* **Header**: `report[0] == 0xAA (170)` and `report[1] == 0xFA (250)`
* **Event Payload**:
  ```
  Byte 0: 0xAA
  Byte 1: 0xFA
  Byte 2..4: Event metadata
  Byte 5: Lighting Type
  Byte 6: Reserved
  Byte 7: Lighting Mode
  Byte 8: Brightness
  Byte 9: Speed
  Byte 10: Direction
  Byte 11: Color Mode
  Byte 12..14: HSV values
  ```
Allows the application UI to synchronize immediately when physical keyboard shortcut keys (e.g. `Fn + \` or `Fn + Backspace`) are pressed on the keyboard.
