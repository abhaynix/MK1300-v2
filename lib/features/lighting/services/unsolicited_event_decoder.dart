import 'package:flutter/foundation.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/hsv_color.dart';
import '../models/lighting_mode.dart';
import '../models/lighting_state.dart';

/// Type of decoded hardware event from the keyboard.
enum KeyboardEventType {
  lightingChanged,
  unknown,
}

/// Base class for all unsolicited event packets received from the keyboard.
@immutable
abstract class KeyboardEvent {
  final KeyboardEventType type;
  final Uint8List rawPacket;

  const KeyboardEvent({required this.type, required this.rawPacket});
}

/// Unsolicited event emitted when physical hardware shortcuts change lighting
/// (Header: `0xAA 0xFA`).
@immutable
class UnsolicitedLightingEvent extends KeyboardEvent {
  final int payloadLength;
  final int hardwareType;
  final LightingMode mode;
  final int brightness; // 0 to 4
  final int speed; // 0 to 4
  final int direction; // 0 = L/T, 1 = R/B
  final int colorMode; // 0 = Dynamic/Rainbow, 1 = Solid color
  final HsvColor hsv;

  const UnsolicitedLightingEvent({
    required super.rawPacket,
    required this.payloadLength,
    required this.hardwareType,
    required this.mode,
    required this.brightness,
    required this.speed,
    required this.direction,
    required this.colorMode,
    required this.hsv,
  }) : super(type: KeyboardEventType.lightingChanged);

  /// Converts this event into a confirmed [LightingState].
  LightingState toLightingState() {
    return LightingState(
      mode: mode,
      brightness: brightness,
      speed: speed,
      direction: direction,
      colorMode: colorMode,
      selectedColor: hsv,
      customSwatches: List.from(ColorUtils.presetPalette),
      perKeyColors: const {},
      isCustomMode: false,
      isPreviewDirty: false,
    );
  }

  @override
  String toString() =>
      'UnsolicitedLightingEvent(mode: ${mode.label}, brt: $brightness, spd: $speed, dir: $direction, clrMode: $colorMode, hsv: $hsv)';
}

/// Represents an unrecognized or unhandled event packet starting with `0xAA 0xFA` or other headers.
@immutable
class UnknownKeyboardEvent extends KeyboardEvent {
  const UnknownKeyboardEvent({required super.rawPacket})
      : super(type: KeyboardEventType.unknown);

  @override
  String toString() =>
      'UnknownKeyboardEvent(header: 0x${rawPacket.isNotEmpty ? rawPacket[0].toRadixString(16).padLeft(2, '0') : '00'}, len: ${rawPacket.length})';
}

/// Pure Dart decoder for unsolicited keyboard event packets.
/// Source evidence: `extracted/unpacked/build/_next/static/chunks/app/page-1d7c89b2cab3983d.js` (lines 11357 & 60009).
/// Header format: `Byte 0 = 0xAA (170)`, `Byte 1 = 0xFA (250)`.
class UnsolicitedEventDecoder {
  UnsolicitedEventDecoder._();

  static const int headerByte0 = 0xAA;
  static const int headerByte1 = 0xFA;

  /// Decodes a raw HID input report into a typed [KeyboardEvent], or returns null if not an unsolicited event.
  static KeyboardEvent? decode(Uint8List packet) {
    if (packet.length < 2) return null;

    // Check unsolicited event header: 0xAA 0xFA
    if (packet[0] != headerByte0 || packet[1] != headerByte1) {
      return null;
    }

    // Packet must have at least 15 bytes to contain the lighting event payload
    // Source: a = e[2] (payload length), e.slice(6, 4 + a)
    // Payload layout:
    // e[6]:  type
    // e[7]:  mode (0-21)
    // e[8]:  brightness (0-4)
    // e[9]:  speed (0-4)
    // e[10]: direction (0-1)
    // e[11]: color (0-1)
    // e[12]: h (0-255)
    // e[13]: s (0-255)
    // e[14]: v (0-255)
    if (packet.length < 15) {
      return UnknownKeyboardEvent(rawPacket: packet);
    }

    try {
      final payloadLen = packet[2];
      final hwType = packet[6];
      final modeVal = packet[7];
      final mode = LightingMode.fromValue(modeVal);
      final brightness = packet[8].clamp(0, 4);
      final speed = packet[9].clamp(0, 4);
      final direction = packet[10].clamp(0, 1);
      final colorMode = packet[11].clamp(0, 1);

      // Vision 9520 MCU HSV byte values (0-255)
      final hByte = packet[12];
      final sByte = packet[13];
      final vByte = packet[14];

      final hsv = HsvColor.fromFirmwareBytes(hByte, sByte, vByte);

      return UnsolicitedLightingEvent(
        rawPacket: packet,
        payloadLength: payloadLen,
        hardwareType: hwType,
        mode: mode,
        brightness: brightness,
        speed: speed,
        direction: direction,
        colorMode: colorMode,
        hsv: hsv,
      );
    } catch (_) {
      return UnknownKeyboardEvent(rawPacket: packet);
    }
  }
}
