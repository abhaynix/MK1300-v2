# Macro System & Storage Format: MK1300 V2

## 1. Overview

The MK1300 V2 software includes an on-board hardware macro recorder and playback engine. Macros are stored directly in the keyboard's non-volatile EEPROM/Flash memory (up to **4096 bytes** total macro allocation) and can execute independently of host software once programmed.

* **Macro Capacity**: Up to **16 distinct macros** (`M0` to `M15`).
* **Storage Allocation**: Fixed 4096-byte memory area.
* **Recording Capabilities**:
  * Keyboard key press / release events.
  * Mouse buttons (Left, Right, Middle, Forward, Backward) press / release.
  * Mouse wheel scroll (Scroll Up, Down, Left, Right).
  * High-resolution inter-keystroke millisecond delays (or user-defined fixed delays).
* **Playback Loop Modes**:
  * `0`: Execute once per keypress.
  * `1` (`80090`): Loop until the assigned key is released.
  * `2` (`80091`): Loop until any key is pressed.
  * `3` (`80092`): Loop until the trigger key is pressed again (Toggle).
  * `4` (`80093`): Fixed loop count (`N` times).

---

## 2. Binary Memory Layout (4096 Bytes)

The 4096-byte buffer is divided into two distinct zones:
1. **Header / Offset Table (Bytes 0 to 63)**:
   * Holds sixteen 16-bit little-endian pointers (2 bytes per macro for up to 32 slots; 16 active in software).
   * Pointer points to the byte offset in the 4096-byte buffer where that macro's action sequence begins.
   * Empty / unused macros have offset value `0xFFFF` (`[0xFF, 0xFF]`) or `0x0000`.
2. **Action Sequence Arena (Bytes 64 to 4095)**:
   * Macro action records are packed sequentially starting at byte offset `64`.

```
Byte 0..1:   Macro 0 Offset (uint16_t LE)
Byte 2..3:   Macro 1 Offset (uint16_t LE)
...
Byte 30..31: Macro 15 Offset (uint16_t LE)
Byte 32..63: Unused slots (0xFF)
Byte 64..4095: Packed 4-byte Action Records
```

---

## 3. Action Record Structure (4 Bytes Per Action)

Each event (press, release, scroll) in a macro is stored as an exact 4-byte record:

| Byte Offset | Field Name | Data Type | Description |
|---|---|---|---|
| `Byte 0` | `delay_low` | `uint8_t` | Inter-action delay in milliseconds (Low byte) |
| `Byte 1` | `delay_high`| `uint8_t` | Inter-action delay in milliseconds (High byte). `delay = byte0 \| (byte1 << 8)` (0 - 10,000 ms) |
| `Byte 2` | `flags` | `uint8_t` | Bitmask encoding action type, direction, and termination: |
| | | `Bit 7 (0x80)`| **`isLast`**: 1 if this is the final action in the macro, 0 otherwise |
| | | `Bit 6 (0x40)`| **`isPress`**: 1 = Key/Button Pressed (Down), 0 = Released (Up) |
| | | `Bits 0..5` | **`event_type`**: |
| | | | `1`: Mouse button click (`0x03` encoded) |
| | | | `2`: Keyboard keystroke (`0x02` encoded) |
| | | | `3`: Vertical mouse scroll (`0x04` encoded) |
| | | | `4`: Horizontal mouse scroll (`0x05` encoded) |
| `Byte 3` | `code` | `uint8_t` | Hardware Keycode or Button Mask: |
| | | | Standard key: USB HID usage code (e.g. 4 for A) |
| | | | Mouse button: 1=Left, 2=Right, 4=Middle, 8=Back, 16=Forward |
| | | | Mouse wheel: 1=Up/Right, 255=Down/Left |

---

## 4. Encoder and Decoder Implementation

### 4.1 Serialization Algorithm (Dart Equivalent)
```dart
Uint8List compileMacroTable(List<MacroModel> macros) {
  final buffer = Uint8List(4096);
  // Fill offset table with 0xFF
  for (int i = 0; i < 64; i++) {
    buffer[i] = 0xFF;
  }
  
  int arenaOffset = 64;
  for (int m = 0; m < macros.length && m < 16; m++) {
    final macro = macros[m];
    if (macro.actions.isEmpty) continue;
    
    // Write 16-bit offset pointer
    buffer[2 * m] = arenaOffset & 0xFF;
    buffer[2 * m + 1] = (arenaOffset >> 8) & 0xFF;
    
    for (int a = 0; a < macro.actions.length; a++) {
      final action = macro.actions[a];
      final isLast = (a == macro.actions.length - 1);
      
      int flags = 0;
      if (action.isPress) flags |= 0x40; // Bit 6
      if (isLast) flags |= 0x80;          // Bit 7
      
      switch (action.type) {
        case MacroActionType.mouseButton:
          flags |= 0x03;
          break;
        case MacroActionType.keyboardKey:
          flags |= 0x02;
          break;
        case MacroActionType.scrollVertical:
          flags |= 0x04;
          break;
        case MacroActionType.scrollHorizontal:
          flags |= 0x05;
          break;
      }
      
      final delay = action.delay.clamp(0, 10000);
      buffer[arenaOffset + 0] = delay & 0xFF;
      buffer[arenaOffset + 1] = (delay >> 8) & 0xFF;
      buffer[arenaOffset + 2] = flags;
      buffer[arenaOffset + 3] = action.code & 0xFF;
      
      arenaOffset += 4;
      if (arenaOffset >= 4096) break; // EEPROM bounds check
    }
  }
  return buffer;
}
```

---

## 5. UI Features & File Format

* **Macro Import / Export**:
  * Original application allows importing and exporting macros as JSON files (`.json`).
  * File format is an array of objects: `[{ name: "M0", list: [{ name: "A", code: 4, type: 2, action: 1, delay: 50 }, ...] }]`.
* **Editor Capabilities**:
  * Insert mouse movements/clicks.
  * Move actions Up/Down/Top/Bottom in sequence.
  * Direct inline editing of delay values in milliseconds.
  * Record live keypresses with browser/window event listener.
