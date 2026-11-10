# Ant Esports MK1300 V2 - Open Questions & Hardware Unknowns

This document catalogs technical ambiguities, hardware-specific unknowns, and protocol edge cases identified during reverse engineering and Linux environment testing.

---

## 1. Verified & Resolved Questions

### 1.1 Keyboard Matrix Inconsistency (RESOLVED)
- **Question**: Why did prior documents mention both 74 and 75 positions, with 13 unused positions and 61 physical keys?
- **Verified Source Evidence**: `assets/data/36ae_fe12.json`
- **Resolution**:
  - The electrical switch matrix declared in firmware is $5 \text{ rows} \times 15 \text{ cols} = 75$ crosspoints.
  - The key array contains indices ranging from `0` to `73` (74 positions total). Position 74 is unused.
  - Exactly 13 indices in the range $0\text{--}73$ are empty gap positions:
    `[14, 29, 42, 44, 46, 57, 59, 63, 64, 65, 67, 68, 69]`.
  - Exactly 61 active physical mechanical switches are mapped ($74 - 13 = 61$).
  - All four numbers are consistent and fully reconciled.

### 1.2 HID Report Size & OS Buffer Sizing (RESOLVED)
- **Question**: Why does the USB HID descriptor define a 64-byte interrupt report, while code allocates 65 bytes?
- **Verified Source Evidence**: Linux `hidraw` kernel semantics and `comm.js` `sendReport(0, l)`.
- **Resolution**: OS HID write APIs require Byte 0 to carry the Report ID (`0x00` for unnumbered collections), followed by the 64-byte payload.

---

## 2. Unresolved Questions & Hardware Verification Gaps

### 2.1 Physical Hardware Absence on Test Host
- **Status**: **BLOCKED**
- **Details**: The physical Ant Esports MK1300 V2 keyboard (`VID 0x36AE`, `PID 0xFE12`) was not plugged into the Ubuntu Linux test environment during Phase 4 verification. Physical device enumeration, descriptor dump, non-root access verification, and live response byte capture could not be conducted without the physical device.

### 2.2 Wireless Battery Voltage Curve & ADC Linearization
- **Evidence**: `CMD 0x06, 0x05` returns a byte at offset 8 representing battery level (0–100) and byte 9 representing charging status (0 or 1).
- **Classification**: **Inferred**.
- **Unknown**: Does the Vision 9520 MCU compute the percentage onboard using an internal ADC lookup table, or does it return a raw battery voltage scalar?
- **Action Required**: Inspect raw byte values across multiple battery states on physical hardware.

### 2.3 Onboard Profile Storage Bounds
- **Evidence**: `CMD 0x06, 0xFB` switches active profile index (0, 1, 2).
- **Classification**: **Source-verified**.
- **Unknown**: Does the Vision 9520 MCU store 3 full copies of the 74-key keymap and 4096-byte macro arena in internal flash memory, or does profile switching only affect lighting and active keymaps while sharing the macro arena?
- **Action Required**: Inspect EEPROM behavior after writing distinct macros to Profile 1 vs Profile 2 on physical hardware.

### 2.4 Per-Key Custom RGB Flash Persistence
- **Evidence**: `CMD 0x06, 0x14` writes a single key's RGB using byte offset `(3 * keyIndex)`.
- **Classification**: **Source-verified**.
- **Unknown**: Does writing single-key RGB via `0x14` automatically persist to the onboard flash, or does the keyboard require a subsequent commit/write command (`0x12`)?
- **Action Required**: Test whether single-key RGB changes survive power-cycling the USB connection.

### 2.5 Lighting Preset Direction Semantics Across Hardware Modes
- **Evidence**: `assets/data/36ae_fe12.json` specifies `direction: 1` for modes 5, 6, 14, and `direction: 2` for mode 7.
- **Classification**: **Source-verified from asset JSON / Inferred for MCU execution**.
- **Unknown**: For mode 6 (Bloom/Ripple) and mode 14 (Twinkling Star), does `direction: 1` control inward vs outward expansion or left-to-right flow?
- **Action Required**: Verify physical light propagation direction on hardware for values `0x01` and `0x02` in modes 6 and 14.

### 2.6 Local Animation Preview Approximation
- **Status**: **SIMULATION VERIFIED**
- **Details**: `LightingPreviewEngine` provides a mathematical desktop simulation of the 22 lighting modes for interactive local previewing. Because physical MCU PWM frequency, step interpolation curves, and LED diffusion optics cannot be measured without the physical keyboard, local preview behavior is classified as an approximation of the physical hardware visual output.

### 2.7 Key Remapping Fn Layer Secondary Defaults
- **Status**: **INFERRED**
- **Details**: The default mappings for the Fn Layer (`Layer 1`) in `KeyMapping.fromGeometry(..., layer: 1)` (such as `1`..`0` -> `F1`..`F10`, `W` -> `Up`, `Esc` -> `` ` ``) are inferred from standard 60% compact keyboard firmware conventions and project documentation. The recovered vendor Electron application dynamically queried layer mappings from the device upon initialization rather than hardcoding static fallbacks.
- **Action Required**: Once physical hardware is connected, read back raw factory Layer 1 tables via `CMD 0x06, 0x08` to verify factory secondary assignments.

### 2.8 Hardware Function Key Type Collision
- **Status**: **KNOWN LIMITATION / AMBIGUITY**
- **Details**: In recovered key catalog data, Hardware Function keys (category 54, type `31` / `0x1F`) have collisions on `value1` (e.g. Brightness + and Light Effect mode switch both declare `value1: 1`). The original JavaScript vendor application relied on separate internal catalog identifiers before wire packet serialization.
- **Action Required**: Verify how the Vision 9520 MCU distinguishes hardware function subcodes when receiving `CMD 0x06, 0x10` with type `31`.

---

## 3. Firmware Flashing & ISP Protocol (Flagged Unsafe / Excluded)

- **Evidence**: The original Electron app contained scripts for bootloader communication using opcodes `0x55` and `0x5A`.
- **Classification**: **Flagged Unsafe / Excluded**.
- **Risk**: Issuing write commands to bootloader addresses without signed manufacturer binary payloads can permanently brick the Vision 9520 MCU.
- **Resolution**: Firmware flashing has been strictly omitted from the application codebase.
