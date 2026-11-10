import 'package:flutter/painting.dart';
import 'hsv_color.dart';

/// Comprehensive color conversion utilities for MK1300 V2.
/// Bridges pure Dart [HsvColor], Flutter framework [Color], hex strings, and MCU firmware bytes.
class ColorUtils {
  ColorUtils._();

  /// Converts firmware byte values (0-255) to normalized HSV and Flutter [Color].
  /// Firmware encoding:
  /// H: 0-255 -> 0-360 degrees: round(360 * byte / 255)
  /// S: 0-255 -> 0-100 percent: round(100 * byte / 255)
  /// V: 0-255 -> 0-100 percent: round(100 * byte / 255)
  static Color fromFirmwareHsv(int hByte, int sByte, int vByte) {
    final hsv = HsvColor.fromFirmwareBytes(hByte, sByte, vByte);
    return fromHsv(hsv);
  }

  /// Converts a Flutter [Color] to firmware [hByte, sByte, vByte] values (0-255).
  static List<int> toFirmwareHsv(Color color) {
    final hsv = toHsv(color);
    return hsv.toFirmwareBytes();
  }

  /// Converts pure Dart [HsvColor] to Flutter [Color].
  static Color fromHsv(HsvColor hsv) {
    final rgb = hsv.toRGB();
    final a = (hsv.alpha * 255.0).round().clamp(0, 255);
    return Color.fromARGB(a, rgb[0], rgb[1], rgb[2]);
  }

  /// Converts Flutter [Color] to pure Dart [HsvColor].
  static HsvColor toHsv(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return HsvColor.fromRGB(r, g, b, color.a);
  }

  /// Parses a hex color string like "#FF5500", "FF5500", or "#FFF" to Flutter [Color].
  static Color fromHex(String hexString, {Color defaultColor = const Color(0xFFFFFFFF)}) {
    final parsed = HsvColor.fromHex(hexString, fallback: toHsv(defaultColor));
    return fromHsv(parsed);
  }

  /// Formats a Flutter [Color] into uppercase hex `#RRGGBB`.
  static String toHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = (color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = (color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$r$g$b';
  }

  /// Converts [Color] to 3-byte RGB `[R, G, B]`.
  static List<int> toRgbBytes(Color color) {
    return [
      (color.r * 255.0).round().clamp(0, 255),
      (color.g * 255.0).round().clamp(0, 255),
      (color.b * 255.0).round().clamp(0, 255),
    ];
  }

  /// Converts RGB channels (0-255) to a Flutter [Color].
  static Color fromRgb(int r, int g, int b, [double alpha = 1.0]) {
    final clampedR = r.clamp(0, 255);
    final clampedG = g.clamp(0, 255);
    final clampedB = b.clamp(0, 255);
    final a = (alpha.clamp(0.0, 1.0) * 255.0).round().clamp(0, 255);
    return Color.fromARGB(a, clampedR, clampedG, clampedB);
  }

  /// Recovered 8 preset color palette swatches from original MK1300 V2 software.
  /// Source-verified from `chunk 1249` / `36ae_fe12.json`: Red, Orange, Yellow, Green, Cyan, Blue, Purple, White.
  static const List<Color> presetPalette = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF7F00), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF00), // Green
    Color(0xFF00FFFF), // Cyan
    Color(0xFF0000FF), // Blue
    Color(0xFF8B00FF), // Purple
    Color(0xFFFFFFFF), // White
  ];
}
