import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_studio/core/utils/hsv_color.dart';

void main() {
  group('HsvColor Pure Dart Engine Tests', () {
    test('HSV to RGB Pure Red (H=0, S=1.0, V=1.0)', () {
      const hsv = HsvColor(hue: 0, saturation: 1.0, value: 1.0);
      final rgb = hsv.toRGB();
      expect(rgb, equals([255, 0, 0]));
      expect(hsv.toHex(), equals('#FF0000'));
    });

    test('HSV to RGB Pure Green (H=120, S=1.0, V=1.0)', () {
      const hsv = HsvColor(hue: 120, saturation: 1.0, value: 1.0);
      final rgb = hsv.toRGB();
      expect(rgb, equals([0, 255, 0]));
      expect(hsv.toHex(), equals('#00FF00'));
    });

    test('HSV to RGB Pure Blue (H=240, S=1.0, V=1.0)', () {
      const hsv = HsvColor(hue: 240, saturation: 1.0, value: 1.0);
      final rgb = hsv.toRGB();
      expect(rgb, equals([0, 0, 255]));
      expect(hsv.toHex(), equals('#0000FF'));
    });

    test('HSV to RGB Pure White (H=0, S=0.0, V=1.0)', () {
      const hsv = HsvColor(hue: 0, saturation: 0.0, value: 1.0);
      final rgb = hsv.toRGB();
      expect(rgb, equals([255, 255, 255]));
      expect(hsv.toHex(), equals('#FFFFFF'));
    });

    test('HSV to RGB Pure Black (H=0, S=0.0, V=0.0)', () {
      const hsv = HsvColor(hue: 0, saturation: 0.0, value: 0.0);
      final rgb = hsv.toRGB();
      expect(rgb, equals([0, 0, 0]));
      expect(hsv.toHex(), equals('#000000'));
    });

    test('RGB to HSV conversion of Cyan [0, 255, 255]', () {
      final hsv = HsvColor.fromRGB(0, 255, 255);
      expect(hsv.hue, closeTo(180.0, 0.1));
      expect(hsv.saturation, closeTo(1.0, 0.001));
      expect(hsv.value, closeTo(1.0, 0.001));
    });

    test('RGB to HSV conversion of Yellow [255, 255, 0]', () {
      final hsv = HsvColor.fromRGB(255, 255, 0);
      expect(hsv.hue, closeTo(60.0, 0.1));
      expect(hsv.saturation, closeTo(1.0, 0.001));
      expect(hsv.value, closeTo(1.0, 0.001));
    });

    test('RGB to HSV conversion of Magenta [255, 0, 255]', () {
      final hsv = HsvColor.fromRGB(255, 0, 255);
      expect(hsv.hue, closeTo(300.0, 0.1));
      expect(hsv.saturation, closeTo(1.0, 0.001));
      expect(hsv.value, closeTo(1.0, 0.001));
    });

    test('RGB to HSV conversion of Mid Gray [128, 128, 128]', () {
      final hsv = HsvColor.fromRGB(128, 128, 128);
      expect(hsv.saturation, closeTo(0.0, 0.001));
      expect(hsv.value, closeTo(128 / 255.0, 0.001));
    });

    test('Hue normalization and boundary handling', () {
      // 360 degrees should normalize to 0 degrees
      final h1 = HsvColor.fromNormalized(hue: 360.0, saturation: 1.0, value: 1.0);
      expect(h1.hue, equals(0.0));

      // Negative angles should wrap properly: -60 -> 300
      final h2 = HsvColor.fromNormalized(hue: -60.0, saturation: 1.0, value: 1.0);
      expect(h2.hue, equals(300.0));

      // Over 360 should wrap properly: 450 -> 90
      final h3 = HsvColor.fromNormalized(hue: 450.0, saturation: 1.0, value: 1.0);
      expect(h3.hue, equals(90.0));
    });

    test('Saturation and Value clamping', () {
      final hsv = HsvColor.fromNormalized(hue: 120.0, saturation: 2.5, value: -0.5);
      expect(hsv.saturation, equals(1.0));
      expect(hsv.value, equals(0.0));
    });

    test('Hex parsing of standard 6-digit hex (#00FFFF)', () {
      final hsv = HsvColor.fromHex('#00FFFF');
      final rgb = hsv.toRGB();
      expect(rgb, equals([0, 255, 255]));
    });

    test('Hex parsing without leading hash (FF5500)', () {
      final hsv = HsvColor.fromHex('FF5500');
      final rgb = hsv.toRGB();
      expect(rgb, equals([255, 85, 0]));
    });

    test('Hex parsing shorthand 3-digit (#F0F)', () {
      final hsv = HsvColor.fromHex('#F0F');
      final rgb = hsv.toRGB();
      expect(rgb, equals([255, 0, 255]));
    });

    test('Hex parsing with alpha 8-digit (#80FF0000)', () {
      final hsv = HsvColor.fromHex('#80FF0000');
      final rgb = hsv.toRGB();
      expect(rgb, equals([255, 0, 0]));
      expect(hsv.alpha, closeTo(128 / 255.0, 0.01));
    });

    test('Invalid hex input returns fallback color safely', () {
      const fallback = HsvColor(hue: 200, saturation: 0.5, value: 0.8);
      final hsv = HsvColor.fromHex('NOT_A_HEX', fallback: fallback);
      expect(hsv, equals(fallback));

      final hsvEmpty = HsvColor.fromHex('', fallback: fallback);
      expect(hsvEmpty, equals(fallback));
    });

    test('Firmware HSV byte conversion roundtrip (Vision 9520 MCU)', () {
      // 0, 255, 255 -> Pure Red
      final red = HsvColor.fromFirmwareBytes(0, 255, 255);
      expect(red.toRGB(), equals([255, 0, 0]));
      expect(red.toFirmwareBytes(), equals([0, 255, 255]));

      // 85, 255, 255 -> Green (~120 degrees)
      // 85 / 255 * 360 = 120
      final green = HsvColor.fromFirmwareBytes(85, 255, 255);
      expect(green.hue, closeTo(120.0, 0.1));
      expect(green.toFirmwareBytes(), equals([85, 255, 255]));

      // 170, 255, 255 -> Blue (~240 degrees)
      // 170 / 255 * 360 = 240
      final blue = HsvColor.fromFirmwareBytes(170, 255, 255);
      expect(blue.hue, closeTo(240.0, 0.1));
      expect(blue.toFirmwareBytes(), equals([170, 255, 255]));
    });

    test('Exact HSV Angle Boundaries (0, 180, 359, 360 degrees)', () {
      // 0 degrees -> Red
      final h0 = HsvColor(hue: 0.0, saturation: 1.0, value: 1.0);
      expect(h0.toRGB(), equals([255, 0, 0]));
      expect(h0.toFirmwareBytes()[0], equals(0));

      // 180 degrees -> Cyan
      final h180 = HsvColor(hue: 180.0, saturation: 1.0, value: 1.0);
      expect(h180.toRGB(), equals([0, 255, 255]));
      expect(h180.toFirmwareBytes()[0], equals(128)); // round(180 * 255 / 360) = 128

      // 359 degrees -> Near Red
      final h359 = HsvColor(hue: 359.0, saturation: 1.0, value: 1.0);
      final rgb359 = h359.toRGB();
      expect(rgb359[0], equals(255));
      expect(rgb359[1], equals(0));
      expect(rgb359[2], inInclusiveRange(0, 10)); // tiny blue component
      expect(h359.toFirmwareBytes()[0], equals(254)); // round(359 * 255 / 360) = 254

      // 360 degrees normalized -> 0 degrees
      final h360 = HsvColor.fromNormalized(hue: 360.0, saturation: 1.0, value: 1.0);
      expect(h360.hue, equals(0.0));
      expect(h360.toFirmwareBytes()[0], equals(0));
    });

    test('Full RGB to HSV and HSV to RGB Roundtrip for standard primaries', () {
      final testColors = [
        [255, 0, 0], // Red
        [0, 255, 0], // Green
        [0, 0, 255], // Blue
        [255, 255, 0], // Yellow
        [0, 255, 255], // Cyan
        [255, 0, 255], // Magenta
        [255, 255, 255], // White
        [0, 0, 0], // Black
        [128, 128, 128], // Gray
      ];

      for (final rgb in testColors) {
        final hsv = HsvColor.fromRGB(rgb[0], rgb[1], rgb[2]);
        final back = hsv.toRGB();
        expect(back, equals(rgb), reason: 'Failed roundtrip for $rgb');
      }
    });

    test('Exact Hex Alpha-Byte Conventions (#AARRGGBB vs #RRGGBB)', () {
      // 6-digit hex assumes alpha = 1.0 (0xFF)
      final hex6 = HsvColor.fromHex('#123456');
      expect(hex6.alpha, equals(1.0));
      expect(hex6.toARGB32() >> 24, equals(0xFF));

      // 8-digit hex parses explicit alpha: #80123456 -> alpha = 128/255 = ~0.5
      final hex8 = HsvColor.fromHex('#80123456');
      expect(hex8.alpha, closeTo(128 / 255.0, 0.01));
      expect((hex8.toARGB32() >> 24) & 0xFF, equals(128));

      // Shorthand 3-digit: #F80 -> #FF8800
      final hex3 = HsvColor.fromHex('#F80');
      expect(hex3.toRGB(), equals([255, 136, 0]));
      expect(hex3.alpha, equals(1.0));
    });
  });
}
