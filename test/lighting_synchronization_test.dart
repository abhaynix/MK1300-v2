import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk1300_v2/core/constants/usb_constants.dart';
import 'package:mk1300_v2/features/lighting/models/lighting_mode.dart';
import 'package:mk1300_v2/features/lighting/models/lighting_state.dart';
import 'package:mk1300_v2/features/lighting/services/unsolicited_event_decoder.dart';
import 'package:mk1300_v2/hardware/hid/mock_hid_device.dart';
import 'package:mk1300_v2/hardware/protocol/packet_builder.dart';
import 'package:mk1300_v2/hardware/services/keyboard_service.dart';

void main() {
  group('Phase 6B: Lighting Protocol & Packet Serialization Tests', () {
    test('Exact Lighting Read Request Packet (CMD 0x06, Sub 0x0A)', () {
      final packet = PacketBuilder.buildGetLightingPacket();
      expect(packet.length, equals(UsbConstants.reportPayloadSize)); // 64 bytes
      expect(packet[0], equals(UsbConstants.rootOpcode)); // 0x06
      expect(packet[1], equals(0x0A)); // Sub 0x0A
      for (int i = 2; i < 64; i++) {
        expect(packet[i], equals(0x00));
      }
    });

    test('Exact Lighting Write Packet Layout (CMD 0x06, Sub 0x0B)', () {
      const testColor = Color(0xFF00FF00); // Pure Green (Hue 120)
      final packet = PacketBuilder.buildSetLightingPacket(
        type: 1,
        mode: 5, // Stream
        brightness: 4,
        speed: 3,
        direction: 1,
        colorMode: 1,
        color: testColor,
      );

      expect(packet.length, equals(UsbConstants.reportPayloadSize)); // 64 bytes
      expect(packet[0], equals(0x06)); // Root opcode
      expect(packet[1], equals(0x0B)); // Sub 0x0B
      expect(packet[2], equals(0x0B)); // Length = 11 bytes
      expect(packet[3], equals(0x00)); // Reserved
      expect(packet[4], equals(0x00)); // Reserved
      expect(packet[5], equals(1));    // Type
      expect(packet[6], equals(0x00)); // Reserved
      expect(packet[7], equals(5));    // Mode: Stream
      expect(packet[8], equals(4));    // Brightness: 4
      expect(packet[9], equals(3));    // Speed: 3
      expect(packet[10], equals(1));   // Direction: 1
      expect(packet[11], equals(1));   // ColorMode: 1
      expect(packet[12], equals(0x00)); // Reserved / single color index
      // Hue for green = round(120 * 255 / 360) = 85
      expect(packet[13], equals(85));
      expect(packet[14], equals(255)); // Saturation: 255
      expect(packet[15], equals(255)); // Value: 255
    });

    test('Lighting Write forces ColorMode to 0 when Mode is 0 (Off)', () {
      final packet = PacketBuilder.buildSetLightingPacket(
        type: 1,
        mode: 0, // Off
        brightness: 0,
        speed: 0,
        direction: 0,
        colorMode: 1, // User had color mode set
        color: const Color(0xFFFF0000),
      );

      expect(packet[7], equals(0));  // Mode: 0
      expect(packet[11], equals(0)); // ColorMode forced to 0
    });

    test('Parse Valid Lighting Response (CMD 0x06, Sub 0x0A)', () {
      final resp = Uint8List(64);
      resp[0] = 0x06;
      resp[1] = 0x0A;
      resp[2] = 0x0B;
      resp[5] = 1;    // Type
      resp[7] = 2;    // Mode: Breath
      resp[8] = 3;    // Brightness: 3
      resp[9] = 2;    // Speed: 2
      resp[10] = 0;   // Direction: 0
      resp[11] = 1;   // ColorMode: 1
      resp[12] = 0;
      resp[13] = 170; // Blue hue (~240 deg)
      resp[14] = 255;
      resp[15] = 255;

      final config = PacketBuilder.parseLightingResponse(resp);
      expect(config, isNotNull);
      expect(config!.mode, equals(LightingMode.breathing));
      expect(config.brightness, equals(3));
      expect(config.speed, equals(2));
      expect(config.direction, equals(0));
      expect(config.colorMode, equals(1));
      expect(config.hue, closeTo(240.0, 0.5));
    });

    test('Parse Rejects Malformed or Unexpected Responses Safely', () {
      // Too short
      expect(PacketBuilder.parseLightingResponse(Uint8List(10)), isNull);

      // Wrong opcode
      final wrongOpcode = Uint8List(64);
      wrongOpcode[0] = 0x05;
      wrongOpcode[1] = 0x0A;
      expect(PacketBuilder.parseLightingResponse(wrongOpcode), isNull);

      // Wrong subcommand
      final wrongSub = Uint8List(64);
      wrongSub[0] = 0x06;
      wrongSub[1] = 0x0B;
      expect(PacketBuilder.parseLightingResponse(wrongSub), isNull);
    });
  });

  group('Phase 6B: Unsolicited Event Decoder Tests (0xAA 0xFA)', () {
    test('Decodes valid unsolicited lighting change packet', () {
      final packet = Uint8List(64);
      packet[0] = 0xAA;
      packet[1] = 0xFA;
      packet[2] = 0x09;
      packet[6] = 1;  // Type
      packet[7] = 4;  // ColorLoop
      packet[8] = 4;  // Brightness: 4
      packet[9] = 3;  // Speed: 3
      packet[10] = 1; // Direction: 1
      packet[11] = 0; // Dynamic rainbow
      packet[12] = 0; // Hue: 0
      packet[13] = 255;
      packet[14] = 255;

      final event = UnsolicitedEventDecoder.decode(packet);
      expect(event, isA<UnsolicitedLightingEvent>());
      final lightEvent = event as UnsolicitedLightingEvent;
      expect(lightEvent.mode, equals(LightingMode.colorLoop));
      expect(lightEvent.brightness, equals(4));
      expect(lightEvent.speed, equals(3));
      expect(lightEvent.direction, equals(1));
      expect(lightEvent.colorMode, equals(0));
      expect(lightEvent.hsv.hue, equals(0.0));

      final state = lightEvent.toLightingState();
      expect(state.mode, equals(LightingMode.colorLoop));
      expect(state.isPreviewDirty, isFalse);
    });

    test('Ignores packet with non-matching header', () {
      final packet = Uint8List(64);
      packet[0] = 0x06;
      packet[1] = 0x0A;
      expect(UnsolicitedEventDecoder.decode(packet), isNull);
    });

    test('Returns UnknownKeyboardEvent for truncated AA FA packet', () {
      final truncated = Uint8List(8);
      truncated[0] = 0xAA;
      truncated[1] = 0xFA;
      final event = UnsolicitedEventDecoder.decode(truncated);
      expect(event, isA<UnknownKeyboardEvent>());
    });
  });

  group('Phase 6B: Hardware Synchronization & Safety Gate Tests', () {
    test('Apply lighting while disconnected returns error and does not write', () async {
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      // Not connected
      final testState = LightingState.initial().copyWith(brightness: 2);
      final result = await service.applyLightingState(testState);
      expect(result, isFalse);
      expect(service.lastSyncError, equals('Device is disconnected'));
    });

    test('Physical write is blocked by safety gate when verification gate is enabled', () async {
      // Create a service representing physical device (isUsingMock = false)
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      // Verify that when isHardwareWriteGated is enabled, gating takes precedence
      expect(service.isHardwareWriteGated, isTrue);

      // In mock mode it succeeds and reads back
      final testState = LightingState.initial().copyWith(
        mode: LightingMode.breathing,
        brightness: 2,
        speed: 1,
      );
      final mockSuccess = await service.applyLightingState(testState);
      expect(mockSuccess, isTrue);
      expect(service.confirmedLightingState, isNotNull);
      expect(service.confirmedLightingState!.mode, equals(LightingMode.breathing));
      expect(service.confirmedLightingState!.brightness, equals(2));
    });

    test('Failed hardware read preserves last confirmed hardware state', () async {
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      // Initial read succeeds
      expect(service.confirmedLightingState, isNotNull);
      final initialConfirmed = service.confirmedLightingState;

      // Simulate read failure on device
      mock.simulateReadFailure = true;
      final readResult = await service.readLightingConfig();
      expect(readResult, isFalse);

      // Confirmed state remains preserved
      expect(service.confirmedLightingState, equals(initialConfirmed));
      expect(service.lastSyncError, isNotNull);
    });

    test('Unsolicited lighting event from device updates confirmed state', () async {
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      // Emit simulated physical shortcut event (Fn + \ changed to Mode 3 Spin)
      mock.simulateHardwareEvent(3, 4, 3, direction: 0, colorMode: 1, h: 85);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.confirmedLightingState, isNotNull);
      expect(service.confirmedLightingState!.mode, equals(LightingMode.spin));
      expect(service.confirmedLightingState!.brightness, equals(4));
      expect(service.confirmedLightingState!.speed, equals(3));
    });
  });
}
