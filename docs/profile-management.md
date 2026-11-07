# Profile Management: Ant Esports MK1300 V2

## 1. Hardware Profiles Overview

The MK1300 V2 hardware supports **onboard hardware profiles**:

* **Hardware Capacity**: 3 Independent Profiles (Profile 1, Profile 2, Profile 3).
* **Storage Location**: Non-volatile onboard keyboard MCU memory.
* **Scope of Profile**:
  * Complete 61-key remapping table for Layer 0 (Main Layer).
  * Complete 61-key remapping table for Layer 1 (Fn Layer).
  * Lighting effect mode, brightness, speed, direction, and color HSV values.
  * Custom per-key RGB backlight configurations.
* **Active Profile Switching**:
  * Software: Send `CMD 0x06, Sub 0xFB, [profile_index]`.
  * Hardware Shortcut: `Fn + ProfileSwitch` key if mapped.

---

## 2. Software Profile Storage & Persistence

In addition to onboard hardware profiles:
* Original application stored local workspace state in browser `localStorage`:
  * `macro_arr`: JSON array of macro items and actions.
  * `macro_action_list`: Active macro working list.
  * `i18nextLng`: UI language choice (`en`, `cn`, etc.).
  * Selected theme: Light / Dark.
* Export and Import:
  * Users can export configuration files to `.json`.
  * Allows unlimited software-side profiles to be saved on disk and flashed to the keyboard as needed.

---

## 3. Profile Data Model

```json
{
  "profile_id": 0,
  "profile_name": "Profile 1 - Gaming",
  "layer_0_keys": [
    { "index": 0, "type": 32, "code1": 0, "code2": 41, "code3": 0, "color": "#FF0000" }
  ],
  "layer_1_keys": [
    { "index": 0, "type": 32, "code1": 0, "code2": 58, "code3": 0, "color": "#00FF00" }
  ],
  "lighting": {
    "mode": 1,
    "brightness": 4,
    "speed": 2,
    "direction": 1,
    "color_mode": 1,
    "hsv": { "h": 210, "s": 100, "v": 100 }
  },
  "macros": []
}
```
