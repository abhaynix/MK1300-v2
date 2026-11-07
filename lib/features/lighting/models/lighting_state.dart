import 'package:flutter/painting.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/hsv_color.dart';
import 'lighting_mode.dart';

/// Comprehensive local state for Lighting Studio with preview capability.
/// Keeps local preview modifications separated from actual committed hardware states.
class LightingState {
  final LightingMode mode;
  final int brightness; // 0 to 4
  final int speed; // 0 to 4
  final int direction; // 1 = L/R (or inward/outward), 2 = U/D
  final int colorMode; // 0 = Rainbow dynamic, 1 = Solid color
  final HsvColor selectedColor;
  final List<Color> customSwatches;
  final Map<int, Color> perKeyColors; // Key index -> Color
  final bool isCustomMode;
  final bool isPreviewDirty; // True if preview contains unapplied changes

  const LightingState({
    required this.mode,
    required this.brightness,
    required this.speed,
    required this.direction,
    required this.colorMode,
    required this.selectedColor,
    required this.customSwatches,
    required this.perKeyColors,
    this.isCustomMode = false,
    this.isPreviewDirty = false,
  });

  /// Factory for standard defaults matching MK1300 V2 power-on defaults.
  factory LightingState.initial() {
    return LightingState(
      mode: LightingMode.stream,
      brightness: 4,
      speed: 2,
      direction: 1,
      colorMode: 0,
      selectedColor: const HsvColor(hue: 180.0, saturation: 1.0, value: 1.0), // Cyan default
      customSwatches: List<Color>.from(ColorUtils.presetPalette),
      perKeyColors: const {},
      isCustomMode: false,
      isPreviewDirty: false,
    );
  }

  /// Flutter [Color] accessor for [selectedColor].
  Color get color => ColorUtils.fromHsv(selectedColor);

  /// Helper to get color for a specific key index (custom per-key or fallback).
  Color? getKeyColor(int index) => perKeyColors[index];

  LightingState copyWith({
    LightingMode? mode,
    int? brightness,
    int? speed,
    int? direction,
    int? colorMode,
    HsvColor? selectedColor,
    List<Color>? customSwatches,
    Map<int, Color>? perKeyColors,
    bool? isCustomMode,
    bool? isPreviewDirty,
  }) {
    return LightingState(
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      speed: speed ?? this.speed,
      direction: direction ?? this.direction,
      colorMode: colorMode ?? this.colorMode,
      selectedColor: selectedColor ?? this.selectedColor,
      customSwatches: customSwatches ?? this.customSwatches,
      perKeyColors: perKeyColors ?? this.perKeyColors,
      isCustomMode: isCustomMode ?? this.isCustomMode,
      isPreviewDirty: isPreviewDirty ?? this.isPreviewDirty,
    );
  }
}
