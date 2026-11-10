# Keyboard Lighting & RGB Effects: MK1300 V2

## 1. Overview

The MK1300 V2 mechanical keyboard features full per-key RGB backlighting driven by the Vision 9520 MCU. The software supports **22 distinct preset lighting effects** plus custom per-key color programming.

---

## 2. Complete Preset Lighting Effect Matrix

Recovered from chunk `2853` (`assets/data/36ae_fe12.json`) and verified with English language pack chunk `1249`:

| ID | Name (EN) | Name (Original) | Lang ID | Brightness | Speed | Direction | Color/Palette | Description |
|---|---|---|---|---|---|---|---|---|
| `0` | **Off** | 关闭 | 2010 | ❌ No | ❌ No | ❌ No | ❌ No | All LEDs turned off |
| `1` | **Static** | 常亮 | 2001 | ✅ Yes (0-4) | ❌ No | ❌ No | ✅ Yes | Constant solid illumination |
| `2` | **Breath** | 呼吸 | 2002 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Smooth pulsing brightness |
| `3` | **Spin** | 旋转 | 2014 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Rotating color wheel / radial spin |
| `4` | **ColorLoop**| 色谱循环 | 2015 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Full spectrum cycling across all keys |
| `5` | **Stream** | 左右流光 | 2016 | ✅ Yes (0-4) | ✅ Yes (0-4) | ✅ 1 (L/R) | ✅ Yes | Horizontal wave flow |
| `6` | **Bloom** | 绽放 | 2017 | ✅ Yes (0-4) | ✅ Yes (0-4) | ✅ 1 (Center) | ✅ Yes | Light expanding from center outwards |
| `7` | **UDWave** | 上下流光 | 2018 | ✅ Yes (0-4) | ✅ Yes (0-4) | ✅ 2 (U/D) | ✅ Yes | Vertical wave flow |
| `8` | **TrigSingle** | 按亮 | 2023 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Key lights up on press, fades out |
| `9` | **Sine wave** | 正弦波 | 2039 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Smooth sinusoidal wave oscillation |
| `10`| **Chase** | 太极 | 3012 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Dual circular swirling pattern |
| `11`| **Shrink** | 聚集 | 3010 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Light contracting inwards |
| `12`| **Cross** | 穿梭 | 2019 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Fast traveling light streaks |
| `13`| **Twin Flowers** | 一石二鸟 | 2025 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Dual symmetric ripple pulses |
| `14`| **Twinkling Star** | 流星 | 2032 | ✅ Yes (0-4) | ✅ Yes (0-4) | ✅ 1 (L/R) | ✅ Yes | Diagonal shooting stars |
| `15`| **Soduko** | 九宫格 | 2024 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Segmented block lighting |
| `16`| **Wheel** | 车轮 | 2036 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Radial wheel rotation |
| `17`| **Tide** | 潮汐 | 2026 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Surging ocean wave effect |
| `18`| **Snake** | 贪吃蛇 | 2020 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Snake-like trail winding through keys |
| `19`| **Snake Circle** | 画圈 | 3004 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Concentric circular rings |
| `20`| **Meteor** | 流星2 | 2022 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Fast high-intensity meteor rain |
| `21`| **Cross Lighting** | 交叉点亮 | 3038 | ✅ Yes (0-4) | ✅ Yes (0-4) | ❌ No | ✅ Yes | Row & column cross laser upon keypress |

---

## 3. Lighting Control Parameters

* **Brightness**: 5 Levels (`0` = Off, `1` = 25%, `2` = 50%, `3` = 75%, `4` = 100%).
* **Speed**: 5 Levels (`0` = Slowest, `4` = Fastest).
* **Direction**:
  * `1` = Left to Right (or Inwards/Outwards depending on mode).
  * `2` = Right to Left (or Top to Bottom / Up to Down).
* **Color Mode**:
  * `0`: Rainbow / Multi-color Dynamic.
  * `1`: Single Color (Selected from palette or HSV picker).
* **Color Encoding**:
  * Original hardware uses HSV internally:
    * `H` (Hue): `0 - 255` mapped to `0° - 360°` (`H = round(360 * byte / 255)`)
    * `S` (Saturation): `0 - 255` mapped to `0 - 100%` (`S = round(100 * byte / 255)`)
    * `V` (Value): `0 - 255` mapped to `0 - 100%` (`V = round(100 * byte / 255)`)
  * Color presets available in UI (Recovered from source): Red, Orange, Yellow, Green, Cyan, Blue, Purple, White.
* **Local Simulation vs Hardware Writes**:
  * Phase 6A establishes responsive local animation previews via `LightingPreviewEngine`.
  * UI control adjustments alter local preview state and mark state as `isPreviewDirty` without emitting unverified physical USB HID commands.

---

## 4. Custom Per-Key RGB Lighting ("Custom Light")

* Each of the 61 keys can be assigned an individual 24-bit RGB hex color (`#RRGGBB`).
* The data is transmitted in 3-byte RGB tuples (`[R, G, B]`) per key.
* Total size for 61 keys = 183 bytes, split across 4 packets of 56 bytes maximum.
* Single-key color updates are supported via `CMD 0x06, Sub 0x14` without re-flashing the entire keyboard.
