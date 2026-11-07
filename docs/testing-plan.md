# Testing & Verification Plan: Ant Esports MK1300 V2

## 1. Scope & Strategy

Testing is split into three levels:
1. **Unit & Protocol Serialization Tests** (Hardware-independent, runs in CI/CD).
2. **Mock Hardware Integration Tests** (Virtual USB device responding with recorded packets).
3. **Physical Hardware Verification** (Executed when physical keyboard is connected to Windows host).

---

## 2. Test Suites

### Suite 1: Binary Packet Serialization & Parsing (Unit Tests)
* **T-01: Keyboard Hardware Config Parser**:
  * Input: Mock 64-byte buffer with firmware version `0x0066` (102), battery `85%`, profile `1`.
  * Verify: Correct parsing of 16-bit fields, battery, and serial number string.
* **T-02: Lighting Packet Builder**:
  * Input: Mode `5` (Horizontal Streamer), Brightness `3`, Speed `4`, Direction `1`, HSV `(210°, 100%, 100%)`.
  * Verify: Generated 64-byte packet matches `[0x06, 0x0B, 11, 0, 0, 0, 0, 5, 3, 4, 1, 1, 0, 148, 255, 255, 0...]`.
* **T-03: Macro Compiler & Decompiler Round-Trip**:
  * Input: Macro `M0` with 4 actions: Press `A` (delay 50ms), Release `A` (delay 100ms), Press `B`, Release `B`.
  * Verify: Compiled 4096-byte buffer has pointer `0x0040` at offset `0`, flag bytes have bit 7 set on final action, bit 6 set on presses. Decompiling buffer reproduces identical actions.
* **T-04: HSV to RGB Color Math**:
  * Verify that `(H: 0°, S: 100%, V: 100%)` converts to `#FF0000` and byte `0`.

### Suite 2: UI & State Management Tests
* **T-05: 61-Key Layout Dimension & Hit Testing**:
  * Verify that clicking key at coordinate `(x: 3.75u, y: 4.0u)` hits the `Spacebar` (width 6.25u).
* **T-06: Layer Switching**:
  * Verify switching between Layer 0 and Layer 1 changes displayed legends from default to Fn bindings.
* **T-07: Category Key Mapping Selection**:
  * Verify selecting Media Mute (`type: 48, code1: 226`) updates the selected key model.

### Suite 3: Hardware Verification (With Physical Device)
* **T-08: Device Detection**:
  * Verify automatic detection when keyboard is plugged into USB port.
* **T-09: Live Lighting Synchronizer**:
  * Verify pressing `Fn + \` on physical keyboard triggers `0xAA, 0xFA` inbound report and updates UI slider.
* **T-10: Onboard Profile Persistence**:
  * Switch to Profile 2, remap `Esc` to `~`, power cycle keyboard, verify setting is preserved.
