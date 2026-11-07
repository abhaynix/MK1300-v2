import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:mk1300_v2/core/constants/usb_constants.dart';
import 'package:mk1300_v2/core/utils/color_utils.dart';
import 'package:mk1300_v2/hardware/protocol/packet_builder.dart';
import 'package:mk1300_v2/features/macros/models/macro_action.dart';
import 'package:mk1300_v2/features/macros/models/macro_model.dart';
import 'package:mk1300_v2/features/macros/services/macro_compiler.dart';

void main() {
  group('ColorUtils Firmware HSV Math Tests', () {
    test('Firmware HSV to Color conversion (Full Red)', () {
      // 0 hue, 255 sat, 255 val -> Red
      final color = ColorUtils.fromFirmwareHsv(0, 255, 255);
      expect(color.r, greaterThanOrEqualTo(0.99));
      expect(color.g, lessThanOrEqualTo(0.01));
      expect(color.b, lessThanOrEqualTo(0.01));
    });

    test('Firmware HSV to Color conversion (Cyan 180 deg)', () {
      // 128 / 255 * 360 ~= 180.7 degrees -> Cyan
      final color = ColorUtils.fromFirmwareHsv(128, 255, 255);
      expect(color.r, lessThanOrEqualTo(0.02));
      expect(color.g, greaterThan(0.95));
      expect(color.b, greaterThan(0.95));
    });

    test('Color to Firmware HSV roundtrip', () {
      const original = Color(0xFFFF0000); // Pure Red
      final hsvBytes = ColorUtils.toFirmwareHsv(original);
      expect(hsvBytes.length, equals(3));
      expect(hsvBytes[0], equals(0)); // 0 deg Hue
      expect(hsvBytes[1], equals(255)); // 100% Sat
      expect(hsvBytes[2], equals(255)); // 100% Val
    });
  });

  group('PacketBuilder 64-Byte Report Serialization Tests', () {
    test('Get Device Config Packet (CMD 0x06, Sub 0x05)', () {
      final packet = PacketBuilder.buildGetConfigPacket();
      expect(packet.length, equals(UsbConstants.reportPayloadSize));
      expect(packet[0], equals(UsbConstants.rootOpcode)); // 0x06
      expect(packet[1], equals(0x05)); // Sub 0x05
    });

    test('Set Lighting Packet (CMD 0x06, Sub 0x0B)', () {
      final packet = PacketBuilder.buildSetLightingPacket(
        type: 0,
        mode: 3, // Breathing
        brightness: 4,
        speed: 2,
        direction: 1,
        colorMode: 1, // Solid
        color: const Color(0xFF00FF00), // Green
      );

      expect(packet.length, equals(UsbConstants.reportPayloadSize));
      expect(packet[0], equals(UsbConstants.rootOpcode)); // 0x06
      expect(packet[1], equals(0x0B)); // Sub 0x0B Set Lighting
      expect(packet[2], equals(11)); // Payload length (11 bytes)
      expect(packet[5], equals(0)); // Type
      expect(packet[7], equals(3)); // Mode
      expect(packet[8], equals(4)); // Brightness
      expect(packet[9], equals(2)); // Speed
      expect(packet[10], equals(1)); // Direction
      expect(packet[11], equals(1)); // Color Mode
    });

    test('Profile Switch Packet (CMD 0x06, Sub 0xFB)', () {
      final packet = PacketBuilder.buildSetProfilePacket(2); // Profile 3 (index 2)
      expect(packet.length, equals(64));
      expect(packet[0], equals(0x06));
      expect(packet[1], equals(0xFB));
      expect(packet[2], equals(0x02));
    });

    test('Auto-Sleep Packet (CMD 0x06, Sub 0xFC)', () {
      final packet = PacketBuilder.buildSetSleepPacket(300); // 300 seconds (0x012C)
      expect(packet.length, equals(64));
      expect(packet[0], equals(0x06));
      expect(packet[1], equals(0xFC));
      expect(packet[2], equals(0x02)); // Length param
      expect(packet[5], equals(0x2C)); // Low byte
      expect(packet[6], equals(0x01)); // High byte
    });

    test('Factory Reset Packet (CMD 0x06, Sub 0x0F, 0xFF)', () {
      final packet = PacketBuilder.buildFactoryResetPacket();
      expect(packet.length, equals(64));
      expect(packet[0], equals(0x06));
      expect(packet[1], equals(0x0F));
      expect(packet[2], equals(0xFF));
    });

    test('Single Key Remap Packet (CMD 0x06, Sub 0x10)', () {
      final packet = PacketBuilder.buildWriteSingleKeyPacket(
        keyIndex: 12,
        layer: 0,
        type: 32, // standard HID key
        code1: 0x02, // Shift
        code2: 0x04, // 'A'
        code3: 0,
      );

      expect(packet.length, equals(64));
      expect(packet[0], equals(0x06));
      expect(packet[1], equals(0x10));
      expect(packet[2], equals(0x07)); // Length param
      // 4 * 12 = 48 (0x0030)
      expect(packet[3], equals(0x30));
      expect(packet[4], equals(0x00));
      expect(packet[6], equals(0)); // Layer 0
      expect(packet[8], equals(32)); // Type
      expect(packet[9], equals(0x02)); // Code 1
      expect(packet[10], equals(0x04)); // Code 2
    });
  });

  group('MacroCompiler 4096-Byte EEPROM Tests', () {
    test('Compile and Decompile Macro Round-trip', () {
      final testMacros = List.generate(16, (i) => MacroModel(name: 'Macro $i', actions: []));
      
      // Add test keystrokes to Macro 0: 'A' down (50ms), 'A' up (50ms)
      testMacros[0].actions.addAll([
        MacroAction(name: 'A', code: 0x04, type: MacroActionType.keyboardKey, isPress: true, delay: 50),
        MacroAction(name: 'A', code: 0x04, type: MacroActionType.keyboardKey, isPress: false, delay: 50),
      ]);

      // Add test keystrokes to Macro 1: 'B' down (120ms), 'B' up (60ms)
      testMacros[1].actions.addAll([
        MacroAction(name: 'B', code: 0x05, type: MacroActionType.keyboardKey, isPress: true, delay: 120),
        MacroAction(name: 'B', code: 0x05, type: MacroActionType.keyboardKey, isPress: false, delay: 60),
      ]);

      // Compile to EEPROM
      final eeprom = MacroCompiler.compileToEeprom(testMacros);
      expect(eeprom.length, equals(4096));

      // Header check: Macro 0 offset is at 0..1 (should point to 64: 0x40, 0x00)
      final m0Offset = eeprom[0] | (eeprom[1] << 8);
      expect(m0Offset, equals(64));

      // Macro 1 offset should follow Macro 0's 2 actions (2 * 4 = 8 bytes -> offset 72)
      final m1Offset = eeprom[2] | (eeprom[3] << 8);
      expect(m1Offset, equals(72));

      // Decompile back from EEPROM
      final decompiled = MacroCompiler.decompileFromEeprom(eeprom);
      expect(decompiled.length, equals(16));

      // Verify Macro 0 actions
      expect(decompiled[0].actions.length, equals(2));
      expect(decompiled[0].actions[0].code, equals(0x04));
      expect(decompiled[0].actions[0].isPress, isTrue);
      expect(decompiled[0].actions[0].delay, equals(50));
      expect(decompiled[0].actions[1].code, equals(0x04));
      expect(decompiled[0].actions[1].isPress, isFalse);
      expect(decompiled[0].actions[1].delay, equals(50));

      // Verify Macro 1 actions
      expect(decompiled[1].actions.length, equals(2));
      expect(decompiled[1].actions[0].code, equals(0x05));
      expect(decompiled[1].actions[0].isPress, isTrue);
      expect(decompiled[1].actions[0].delay, equals(120));
      expect(decompiled[1].actions[1].code, equals(0x05));
      expect(decompiled[1].actions[1].isPress, isFalse);
      expect(decompiled[1].actions[1].delay, equals(60));

      // Verify other empty macros
      for (int i = 2; i < 16; i++) {
        expect(decompiled[i].actions, isEmpty);
      }
    });
  });
}
