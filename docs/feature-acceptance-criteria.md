# Ant Esports MK1300 V2 - Feature Acceptance Criteria

This document provides explicit, testable acceptance criteria for every application capability.

---

## 1. Hardware Connection & USB HID Management

### AC-1.1: Physical Device Discovery
- **Given**: An Ant Esports MK1300 V2 keyboard is attached to a Linux host via USB.
- **When**: The application launches or the "Rescan Bus" button is pressed.
- **Then**: `hidapi` must discover a device with VID `0x36AE`, PID `0xFE12`, and Interface `1`.
- **And**: The top bar status badge must change to `DEVICE CONNECTED` (Green).

### AC-1.2: Graceful Simulation Fallback
- **Given**: No physical MK1300 V2 keyboard is connected to the machine.
- **When**: The application launches.
- **Then**: The application must not crash or fail.
- **And**: The top bar status badge must indicate `OFFLINE SIMULATOR` (Amber/Red).
- **And**: All UI views (lighting preview, key remapping, macros) must remain completely interactive using the internal simulated `MockHidDevice`.

### AC-1.3: Permission Denied Handling
- **Given**: The keyboard is attached, but the user lacks udev permissions to read/write `/dev/hidraw*`.
- **When**: The application attempts connection.
- **Then**: The application must catch `EACCES` cleanly and present a udev setup notification rather than crashing.

---

## 2. Lighting & Visualizer System

### AC-2.1: Mode Selection
- **Given**: The user is on the Lighting tab.
- **When**: The user selects any of the 22 preset lighting modes from the dropdown.
- **Then**: The keyboard visualizer must immediately update its animation to reflect the selected mode.
- **And**: A 64-byte packet with opcode `0x06, 0x0B` containing the mode index (0–21) must be dispatched to the device.

### AC-2.2: Parameter Availability Matrix
- **Given**: A lighting mode that does not support speed or direction (e.g. Mode 1 "Static").
- **When**: The mode is active.
- **Then**: The Speed and Direction sliders/toggles must be disabled in the UI.

### AC-2.3: HSV Color Mapping
- **Given**: The user picks a color with RGB `(255, 0, 0)`.
- **When**: The packet is constructed.
- **Then**: `hue`, `sat`, and `val` bytes must equal `[0, 255, 255]`.

### AC-2.4: Real-time Live Event Updates (`0xAA, 0xFA`)
- **Given**: The keyboard is connected and the user presses `Fn + \|` on the physical keyboard.
- **When**: The keyboard sends an unsolicited report starting with `0xAA, 0xFA`.
- **Then**: The application's reactive service must parse the updated mode/brightness bytes and update the active UI dropdown and sliders without requiring user interaction.

---

## 3. Key Remapping & Layer Controls

### AC-3.1: 61-Key Switch Layout
- **Given**: The user opens the Key Remapping tab.
- **When**: The view renders.
- **Then**: Exactly 61 interactive keycaps matching ANSI 60% standard geometry must appear on screen.

### AC-3.2: Layer Toggling
- **Given**: The user toggles between "Main Layer" and "Fn Layer".
- **When**: The layer is switched.
- **Then**: The visual key legends must dynamically reflect the layer assignments (e.g. `1` on Main Layer, `F1` on Fn Layer).

### AC-3.3: Atomic Key Remapping
- **Given**: The user selects keycap `Caps Lock` (index 28) and assigns `Left Control`.
- **When**: Assignment is confirmed.
- **Then**: A 64-byte packet `CMD 0x06, 0x10` must be dispatched with offset byte `(28 * 4) = 112` and standard HID usage code for Control (`0xE0`).
- **And**: Keymap in memory must update immediately.

---

## 4. Macro System & EEPROM Compiler

### AC-4.1: Slot Availability
- **Given**: The user opens Macro Studio.
- **When**: Viewing macro list.
- **Then**: Exactly 16 macro slots (`M0` to `M15`) must be available for creation and editing.

### AC-4.2: EEPROM Round-trip Integrity
- **Given**: A set of configured macros with key-down, key-up, and delay actions.
- **When**: Compiled to 4096 bytes via `MacroCompiler.compileToEeprom` and immediately decoded via `MacroCompiler.decompileFromEeprom`.
- **Then**: All macro names, action counts, key codes, and millisecond delays must match the original objects with 100% precision.

### AC-4.3: Hardware Write Chunking
- **Given**: The user clicks "Program to Keyboard".
- **When**: The save process executes.
- **Then**: The 4096-byte EEPROM must be sliced into 59-byte chunks and sent across sequential `CMD 0x06, 0x0D` reports with $\ge 10\text{ ms}$ inter-packet spacing.

---

## 5. Profiles & System Settings

### AC-5.1: Profile Switching
- **Given**: The user clicks `P2` in the top bar.
- **When**: The switch action triggers.
- **Then**: Packet `0x06, 0xFB, 0x01` must be sent to the device.
- **And**: The application must reload lighting and keymap state for Profile 2 from the device.

### AC-5.2: Inactivity Timeout
- **Given**: The user selects `5 Minutes` in Settings.
- **When**: Value changes.
- **Then**: Packet `0x06, 0xFC, 0x02, 0x00, 0x00, 0x2C, 0x01` (300 seconds LE) must be dispatched.

### AC-5.3: Factory Reset Safeguard
- **Given**: The user clicks "Restore Factory Defaults".
- **When**: The button is clicked.
- **Then**: A modal confirmation dialog must appear warning of data erasure.
- **And**: The reset command `0x06, 0x0F, 0xFF` must ONLY be dispatched if the user explicitly confirms in the dialog.
