# Key Remapping & Layer System: MK1300 V2

## 1. Keyboard Form Factor & Key Matrix

* **Form Factor**: 60% Compact (61 keys total, ANSI standard US layout).
* **Matrix Size**: 5 rows × 15 columns (75 electrical intersections, 61 physical switch positions).
* **Key Index Range**: `0` to `73` (with holes for spacebar and modifier spacing).
* **Key Descriptor Structure**: Each key in the layout is represented by a 4-byte tuple in hardware:
  ```c
  struct KeyMapping {
      uint8_t new_type;   // Key Type category
      uint8_t new_code1;  // Modifiers / Sub-category
      uint8_t new_code2;  // Primary key code (HID usage ID or custom action)
      uint8_t new_code3;  // Loop mode / Wheel delta / Sub-parameter
  };
  ```

---

## 2. Key Type Categories

| Type ID | Hex | Category | Description | Parameters |
|---|---|---|---|---|
| `32` | `0x20` | **Standard Key** | Standard HID keyboard key | `new_code1`: Modifier mask, `new_code2`: USB HID usage code (e.g. 4 = A, 41 = Esc) |
| `48` | `0x30` | **Media / Consumer** | Volume, Play/Pause, Browser keys | `new_code1`: Consumer usage code (e.g. 233 = Vol+, 205 = Play), `new_code2`: Page |
| `16` | `0x10` | **Mouse Button** | Mouse clicks and scroll wheel | `new_code1`: Button mask (1=L, 2=R, 4=M, 8=Back, 16=Fwd), `new_code3`: Wheel delta |
| `17` | `0x11` | **Mouse Cursor** | Cursor movement emulation | `new_code1`, `new_code2`: X/Y direction and distance |
| `31` | `0x1F` | **Hardware Functions**| Keyboard-internal actions | `new_code1`: Action ID (Lighting mode switch, speed+/-, brightness+/-, profile switch, lock) |
| `64` | `0x40` | **System Power** | Power control | `new_code1`: 1 = Power, 2 = Sleep, 4 = Wakeup |
| `96` | `0x60` | **Macro Trigger** | Executes assigned macro | `new_code1`: Macro index (0 - 15), `new_code2`: 1, `new_code3`: Playback loop mode |
| `255` | `0xFF` | **Custom Combo** | Key combination (e.g. Ctrl+Alt+Del) | `new_code1`: Modifier bitmask, `new_code2`: Key code |

---

## 3. Physical 61-Key Layout Mapping

| Physical Key | Default Name | Row | Col | Layout Index | Default Type | Default HID Code |
|---|---|---|---|---|---|---|
| `Esc` | Esc | 0 | 0 | 0 | 32 (0x20) | 41 (0x29) |
| `1` | 1 | 0 | 1 | 1 | 32 | 30 (0x1E) |
| `2` | 2 | 0 | 2 | 2 | 32 | 31 (0x1F) |
| `3` | 3 | 0 | 3 | 3 | 32 | 32 (0x20) |
| `4` | 4 | 0 | 4 | 4 | 32 | 33 (0x21) |
| `5` | 5 | 0 | 5 | 5 | 32 | 34 (0x22) |
| `6` | 6 | 0 | 6 | 6 | 32 | 35 (0x23) |
| `7` | 7 | 0 | 7 | 7 | 32 | 36 (0x24) |
| `8` | 8 | 0 | 8 | 8 | 32 | 37 (0x25) |
| `9` | 9 | 0 | 9 | 9 | 32 | 38 (0x26) |
| `0` | 0 | 0 | 10 | 10 | 32 | 39 (0x27) |
| `-` | - | 0 | 11 | 11 | 32 | 45 (0x2D) |
| `+` | = | 0 | 12 | 12 | 32 | 46 (0x2E) |
| `Backspace`| Back | 0 | 13 | 13 | 32 | 42 (0x2A) |
| `Tab` | Tab | 1 | 0 | 15 | 32 | 43 (0x2B) |
| `Q` | Q | 1 | 1 | 16 | 32 | 20 (0x14) |
| `W` | W | 1 | 2 | 17 | 32 | 26 (0x1A) |
| `E` | E | 1 | 3 | 18 | 32 | 8 (0x08) |
| `R` | R | 1 | 4 | 19 | 32 | 21 (0x15) |
| `T` | T | 1 | 5 | 20 | 32 | 23 (0x17) |
| `Y` | Y | 1 | 6 | 21 | 32 | 28 (0x1C) |
| `U` | U | 1 | 7 | 22 | 32 | 24 (0x18) |
| `I` | I | 1 | 8 | 23 | 32 | 12 (0x0C) |
| `O` | O | 1 | 9 | 24 | 32 | 18 (0x12) |
| `P` | P | 1 | 10 | 25 | 32 | 19 (0x13) |
| `[` | [ | 1 | 11 | 26 | 32 | 47 (0x2F) |
| `]` | ] | 1 | 12 | 27 | 32 | 48 (0x30) |
| `\` | \ | 1 | 13 | 28 | 32 | 49 (0x31) |
| `Caps Lock`| Caps | 2 | 0 | 30 | 32 | 57 (0x39) |
| `A` | A | 2 | 1 | 31 | 32 | 4 (0x04) |
| `S` | S | 2 | 2 | 32 | 32 | 22 (0x16) |
| `D` | D | 2 | 3 | 33 | 32 | 7 (0x07) |
| `F` | F | 2 | 4 | 34 | 32 | 9 (0x09) |
| `G` | G | 2 | 5 | 35 | 32 | 10 (0x0A) |
| `H` | H | 2 | 6 | 36 | 32 | 11 (0x0B) |
| `J` | J | 2 | 7 | 37 | 32 | 13 (0x0D) |
| `K` | K | 2 | 8 | 38 | 32 | 14 (0x0E) |
| `L` | L | 2 | 9 | 39 | 32 | 15 (0x0F) |
| `;` | ; | 2 | 10 | 40 | 32 | 51 (0x33) |
| `'` | ' | 2 | 11 | 41 | 32 | 52 (0x34) |
| `Enter` | Enter | 2 | 13 | 43 | 32 | 40 (0x28) |
| `LShift` | Shift | 3 | 0 | 45 | 32 | 225 (0xE1) |
| `Z` | Z | 3 | 2 | 47 | 32 | 29 (0x1D) |
| `X` | X | 3 | 3 | 48 | 32 | 27 (0x1B) |
| `C` | C | 3 | 4 | 49 | 32 | 6 (0x06) |
| `V` | V | 3 | 5 | 50 | 32 | 25 (0x19) |
| `B` | B | 3 | 6 | 51 | 32 | 5 (0x05) |
| `N` | N | 3 | 7 | 52 | 32 | 17 (0x11) |
| `M` | M | 3 | 8 | 53 | 32 | 16 (0x10) |
| `,` | < | 3 | 9 | 54 | 32 | 54 (0x36) |
| `.` | > | 3 | 10 | 55 | 32 | 55 (0x37) |
| `/` | ? | 3 | 11 | 56 | 32 | 56 (0x38) |
| `RShift` | Shift | 3 | 13 | 58 | 32 | 229 (0xE5) |
| `LCtrl` | Ctrl | 4 | 0 | 60 | 32 | 256 (0xE0) |
| `LWin` | Win | 4 | 1 | 61 | 32 | 2048 (0xE3)|
| `LAlt` | Alt | 4 | 2 | 62 | 32 | 1024 (0xE2)|
| `Space` | Space | 4 | 6 | 66 | 32 | 44 (0x2C) |
| `RAlt` | Alt | 4 | 10 | 70 | 32 | 230 (0xE6) |
| `Fn` | Fn | 4 | 11 | 71 | 32 | 255 (0xFF) |
| `App/Menu`| App | 4 | 12 | 72 | 32 | 101 (0x65) |
| `RCtrl` | RCtrl | 4 | 13 | 73 | 32 | 117 (0x75) |

---

## 4. Multi-Layer Functionality

* **Main Layer (`0`)**: Default key assignments when typing normally.
* **Fn Layer (`1`)**: Secondary actions invoked when holding or locking the `Fn` key:
  * Numbers `1`..`0` mapped to `F1`..`F10`
  * `-` mapped to `F11`, `+` mapped to `F12`
  * `W`/`A`/`S`/`D` mapped to Arrow keys (`Up`/`Left`/`Down`/`Right`)
  * `Esc` mapped to `` ` `` (Grave accent)
  * `[` / `]` mapped to `PrintScreen` / `ScrollLock`
  * `;` / `'` mapped to `PageUp` / `PageDown`
  * `.` / `/` mapped to `Insert` / `Delete`
  * Backspace mapped to Reset / Factory restore

> [!NOTE]
> **Source Verification Status of Fn Defaults**:
> The Fn Layer secondary mapping defaults listed above are **inferred** from standard 60% compact keyboard firmware conventions and project documentation. The recovered vendor application reads layer assignments dynamically from the keyboard microcontroller (via `CMD 0x06, 0x08`), rather than hardcoding static fallback tables.

---

## 5. Architecture: Confirmed vs Pending State Model

To prevent accidental hardware state corruption and erratic UI flickering during key configuration, the software implements an explicit transactional state pattern:

```
[Key Catalog / User Selection]
              │
              ▼
  ┌───────────────────────┐
  │ Local Pending State   │ ◄── Local modifications (newType, newCode1..3, newName)
  │ (isPendingChange = true)│     Visualized with Amber dot indicator on Keycap
  └───────────┬───────────┘
              │
       User clicks "Apply"
              │
              ▼
  ┌───────────────────────┐
  │ Hardware Safety Gate  │ ──► [BLOCKED] if physical device & isHardwareWriteGated
  └───────────┬───────────┘
              │ (Simulated Mock or Un-gated Physical)
              ▼
  ┌───────────────────────┐
  │ USB HID Command Queue │ ──► CMD 0x06, Sub 0x10 (Single Key) or Sub 0x09 (Chunk)
  └───────────┬───────────┘
              │
       Command Confirmed
              │
              ▼
  ┌───────────────────────┐
  │ Confirmed State       │ ◄── confirmedType/Code1..3 updated
  │ (isPendingChange = false)│  Status changes to "Hardware In Sync"
  └───────────────────────┘
```

### 5.1 Revert and Reset Capabilities
* **Revert Pending (`revertPendingRemaps`)**: Discards all uncommitted changes on the active layer and restores each key back to its `confirmed` state.
* **Reset Selected Key (`resetSelectedKeyToDefault`)**: Re-assigns the selected key's pending action to its physical factory default.
* **Reset Entire Layer (`resetLayerToDefault`)**: Restores all 61 keys in the active layer to their factory default mappings.

---

## 6. Hardware Write Safety Gate

* **Safety Policy**: Direct physical writes to connected MK1300 V2 USB hardware remain **strictly blocked** by default (`isHardwareWriteGated = true`).
* **Enforcement Point**: Both `KeyboardService.applyKeyRemap(keyIndex)` and `KeyboardService.applyAllPendingRemaps({layer})` reject write attempts with:
  `"Physical hardware writes are currently gated pending hardware verification"`.
* **Safe Development**: Simulated mock devices (`MockHidDevice`) bypass the safety gate in development and automated testing, allowing complete end-to-end simulation of key remapping, chunk updates, and readback synchronization without risk to real hardware.
