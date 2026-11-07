/// All 22 recovered preset lighting effects for Ant Esports MK1300 V2.
/// Source: `assets/data/36ae_fe12.json` (chunk 2853) & language pack chunk 1249.
///
/// Each enum value includes:
/// - [value]: Firmware mode index (0-21)
/// - [label]: Source-verified English display name
/// - [originalName]: Chinese name in original firmware
/// - [langId]: Localization string ID in unpacked Electron app
/// - [hasBrightness]: Whether hardware/firmware accepts brightness control
/// - [hasSpeed]: Whether hardware/firmware accepts speed control
/// - [hasDirection]: Whether hardware/firmware supports direction (0=none, 1=Horizontal/Ripple, 2=Vertical)
/// - [hasColor]: Whether mode supports custom single/palette color selection
/// - [hasPalette]: Whether mode accepts the 8-color preset swatches
enum LightingMode {
  off(0, 'Off', '关闭', 2010, false, false, 0, false, false),
  staticOn(1, 'Static', '常亮', 2001, true, false, 0, true, true),
  breathing(2, 'Breath', '呼吸', 2002, true, true, 0, true, true),
  spin(3, 'Spin', '旋转', 2014, true, true, 0, true, true),
  colorLoop(4, 'ColorLoop', '色谱循环', 2015, true, true, 0, true, true),
  stream(5, 'Stream', '左右流光', 2016, true, true, 1, true, true),
  bloom(6, 'Bloom', '绽放', 2017, true, true, 1, true, true),
  udWave(7, 'UDWave', '上下流光', 2018, true, true, 2, true, true),
  trigSingle(8, 'TrigSingle', '按亮', 2023, true, true, 0, true, true),
  sineWave(9, 'Sine wave', '正弦波', 2039, true, true, 0, true, true),
  chase(10, 'Chase', '太极', 3012, true, true, 0, true, true),
  shrink(11, 'Shrink', '聚集', 3010, true, true, 0, true, true),
  cross(12, 'Cross', '穿梭', 2019, true, true, 0, true, true),
  twinFlowers(13, 'Twin Flowers', '一石二鸟', 2025, true, true, 0, true, true),
  twinklingStar(14, 'Twinkling Star', '流星', 2032, true, true, 1, true, true),
  soduko(15, 'Soduko', '九宫格', 2024, true, true, 0, true, true),
  wheel(16, 'Wheel', '车轮', 2036, true, true, 0, true, true),
  tide(17, 'Tide', '潮汐', 2026, true, true, 0, true, true),
  snake(18, 'Snake', '贪吃蛇', 2020, true, true, 0, true, true),
  snakeCircle(19, 'Snake Circle', '画圈', 3004, true, true, 0, true, true),
  meteor(20, 'Meteor', '流星2', 2022, true, true, 0, true, true),
  crossLighting(21, 'Cross Lighting', '交叉点亮', 3038, true, true, 0, true, true);

  final int value;
  final String label;
  final String originalName;
  final int langId;
  final bool hasBrightness;
  final bool hasSpeed;
  final int hasDirection; // 0 = No direction, 1 = Horizontal/Spread (L/R), 2 = Vertical (U/D)
  final bool hasColor;
  final bool hasPalette;

  const LightingMode(
    this.value,
    this.label,
    this.originalName,
    this.langId,
    this.hasBrightness,
    this.hasSpeed,
    this.hasDirection,
    this.hasColor,
    this.hasPalette,
  );

  /// Helper to lookup mode by raw integer value.
  static LightingMode fromValue(int val) {
    return LightingMode.values.firstWhere(
      (m) => m.value == val,
      orElse: () => LightingMode.staticOn,
    );
  }
}
