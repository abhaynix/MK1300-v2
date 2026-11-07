/// Pure Dart HSV Color representation independent of Flutter UI framework.
class HsvColor {
  final double hue; // 0.0 to 360.0 degrees
  final double saturation; // 0.0 to 1.0 (0% to 100%)
  final double value; // 0.0 to 1.0 (0% to 100%)
  final double alpha; // 0.0 to 1.0 (defaults to 1.0)

  const HsvColor({
    required this.hue,
    required this.saturation,
    required this.value,
    this.alpha = 1.0,
  });

  /// Normalizes and clamps hue to [0.0, 360.0), sat to [0.0, 1.0], val to [0.0, 1.0].
  factory HsvColor.fromNormalized({
    required double hue,
    required double saturation,
    required double value,
    double alpha = 1.0,
  }) {
    double normHue = hue % 360.0;
    if (normHue < 0.0) normHue += 360.0;
    // Handle floating point edge near 360
    if (normHue >= 360.0) normHue = 0.0;

    final normSat = saturation.clamp(0.0, 1.0);
    final normVal = value.clamp(0.0, 1.0);
    final normAlpha = alpha.clamp(0.0, 1.0);

    return HsvColor(
      hue: normHue,
      saturation: normSat,
      value: normVal,
      alpha: normAlpha,
    );
  }

  /// Converts RGB (0-255 channels) to HSV.
  factory HsvColor.fromRGB(int r, int g, int b, [double alpha = 1.0]) {
    final clampR = r.clamp(0, 255) / 255.0;
    final clampG = g.clamp(0, 255) / 255.0;
    final clampB = b.clamp(0, 255) / 255.0;

    final max = [clampR, clampG, clampB].reduce((curr, next) => curr > next ? curr : next);
    final min = [clampR, clampG, clampB].reduce((curr, next) => curr < next ? curr : next);
    final delta = max - min;

    double h = 0.0;
    if (delta > 0.000001) {
      if (max == clampR) {
        h = 60.0 * (((clampG - clampB) / delta) % 6.0);
      } else if (max == clampG) {
        h = 60.0 * (((clampB - clampR) / delta) + 2.0);
      } else {
        h = 60.0 * (((clampR - clampG) / delta) + 4.0);
      }
    }
    if (h < 0.0) h += 360.0;
    if (h >= 360.0) h = 0.0;

    final s = max <= 0.000001 ? 0.0 : delta / max;
    final v = max;

    return HsvColor(
      hue: h,
      saturation: s.clamp(0.0, 1.0),
      value: v.clamp(0.0, 1.0),
      alpha: alpha.clamp(0.0, 1.0),
    );
  }

  /// Converts this HSV instance to RGB channel values `[R, G, B]` (each 0 to 255).
  List<int> toRGB() {
    final c = value * saturation;
    final hPrime = (hue % 360.0) / 60.0;
    final x = c * (1.0 - ((hPrime % 2.0) - 1.0).abs());
    final m = value - c;

    double r1 = 0.0, g1 = 0.0, b1 = 0.0;
    if (hPrime >= 0.0 && hPrime < 1.0) {
      r1 = c; g1 = x; b1 = 0.0;
    } else if (hPrime >= 1.0 && hPrime < 2.0) {
      r1 = x; g1 = c; b1 = 0.0;
    } else if (hPrime >= 2.0 && hPrime < 3.0) {
      r1 = 0.0; g1 = c; b1 = x;
    } else if (hPrime >= 3.0 && hPrime < 4.0) {
      r1 = 0.0; g1 = x; b1 = c;
    } else if (hPrime >= 4.0 && hPrime < 5.0) {
      r1 = x; g1 = 0.0; b1 = c;
    } else if (hPrime >= 5.0 && hPrime < 6.0) {
      r1 = c; g1 = 0.0; b1 = x;
    }

    final int r = ((r1 + m) * 255.0).round().clamp(0, 255);
    final int g = ((g1 + m) * 255.0).round().clamp(0, 255);
    final int b = ((b1 + m) * 255.0).round().clamp(0, 255);

    return [r, g, b];
  }

  /// Converts this HSV instance to a 32-bit ARGB integer.
  int toARGB32() {
    final rgb = toRGB();
    final a = (alpha * 255.0).round().clamp(0, 255);
    return (a << 24) | (rgb[0] << 16) | (rgb[1] << 8) | rgb[2];
  }

  /// Formats this color as uppercase hex string `#RRGGBB`.
  String toHex() {
    final rgb = toRGB();
    final rStr = rgb[0].toRadixString(16).padLeft(2, '0').toUpperCase();
    final gStr = rgb[1].toRadixString(16).padLeft(2, '0').toUpperCase();
    final bStr = rgb[2].toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$rStr$gStr$bStr';
  }

  /// Parses a hexadecimal string (e.g. "#FF5500", "FF5500", "#FFF", or with alpha) into [HsvColor].
  /// Returns [fallback] if parsing fails.
  static HsvColor fromHex(String hexString, {HsvColor fallback = const HsvColor(hue: 0, saturation: 0, value: 1)}) {
    String clean = hexString.trim().replaceAll('#', '');
    if (clean.length == 3) {
      // 3-digit shorthand #RGB -> #RRGGBB
      clean = clean.split('').map((c) => '$c$c').join();
    }

    if (clean.length == 6) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) {
        final r = (val >> 16) & 0xFF;
        final g = (val >> 8) & 0xFF;
        final b = val & 0xFF;
        return HsvColor.fromRGB(r, g, b);
      }
    } else if (clean.length == 8) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) {
        final a = ((val >> 24) & 0xFF) / 255.0;
        final r = (val >> 16) & 0xFF;
        final g = (val >> 8) & 0xFF;
        final b = val & 0xFF;
        return HsvColor.fromRGB(r, g, b, a);
      }
    }
    return fallback;
  }

  /// Converts Vision 9520 MCU firmware byte values (0-255) to [HsvColor].
  /// H: 0-255 -> 0-360 degrees: (360 * byte / 255)
  /// S: 0-255 -> 0-100 percent: (byte / 255)
  /// V: 0-255 -> 0-100 percent: (byte / 255)
  factory HsvColor.fromFirmwareBytes(int hByte, int sByte, int vByte) {
    final h = (360.0 * hByte.clamp(0, 255) / 255.0).clamp(0.0, 360.0);
    final s = (sByte.clamp(0, 255) / 255.0).clamp(0.0, 1.0);
    final v = (vByte.clamp(0, 255) / 255.0).clamp(0.0, 1.0);
    return HsvColor(hue: h == 360.0 ? 0.0 : h, saturation: s, value: v);
  }

  /// Converts to Vision 9520 MCU firmware bytes `[hByte, sByte, vByte]` (0-255).
  List<int> toFirmwareBytes() {
    final normH = (hue % 360.0);
    final hByte = (normH * 255.0 / 360.0).round().clamp(0, 255);
    final sByte = (saturation * 255.0).round().clamp(0, 255);
    final vByte = (value * 255.0).round().clamp(0, 255);
    return [hByte, sByte, vByte];
  }

  HsvColor copyWith({
    double? hue,
    double? saturation,
    double? value,
    double? alpha,
  }) {
    return HsvColor(
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      value: value ?? this.value,
      alpha: alpha ?? this.alpha,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HsvColor &&
        (other.hue - hue).abs() < 0.001 &&
        (other.saturation - saturation).abs() < 0.001 &&
        (other.value - value).abs() < 0.001 &&
        (other.alpha - alpha).abs() < 0.001;
  }

  @override
  int get hashCode => Object.hash(hue.round(), (saturation * 100).round(), (value * 100).round());

  @override
  String toString() => 'HsvColor(h: ${hue.toStringAsFixed(1)}°, s: ${(saturation * 100).toStringAsFixed(1)}%, v: ${(value * 100).toStringAsFixed(1)}%)';
}
