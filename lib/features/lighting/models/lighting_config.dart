import 'package:flutter/painting.dart';
import 'lighting_mode.dart';

/// Lighting configuration state model.
class LightingConfig {
  final int type;
  final LightingMode mode;
  final int brightness; // 0 to 4
  final int speed; // 0 to 4
  final int direction; // 1 = Horizontal/In, 2 = Vertical/Out
  final int colorMode; // 0 = Rainbow dynamic, 1 = Solid color
  final int singleColorIndex;
  final double hue; // 0.0 to 360.0
  final double saturation; // 0.0 to 100.0
  final double value; // 0.0 to 100.0

  const LightingConfig({
    required this.type,
    required this.mode,
    required this.brightness,
    required this.speed,
    required this.direction,
    required this.colorMode,
    required this.singleColorIndex,
    required this.hue,
    required this.saturation,
    required this.value,
  });

  Color get color {
    final hsv = HSVColor.fromAHSV(
      1.0,
      hue.clamp(0.0, 360.0),
      (saturation / 100.0).clamp(0.0, 1.0),
      (value / 100.0).clamp(0.0, 1.0),
    );
    return hsv.toColor();
  }

  LightingConfig copyWith({
    int? type,
    LightingMode? mode,
    int? brightness,
    int? speed,
    int? direction,
    int? colorMode,
    int? singleColorIndex,
    double? hue,
    double? saturation,
    double? value,
  }) {
    return LightingConfig(
      type: type ?? this.type,
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      speed: speed ?? this.speed,
      direction: direction ?? this.direction,
      colorMode: colorMode ?? this.colorMode,
      singleColorIndex: singleColorIndex ?? this.singleColorIndex,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      value: value ?? this.value,
    );
  }
}
