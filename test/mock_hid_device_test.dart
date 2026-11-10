import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_studio/core/constants/usb_constants.dart';
import 'package:keyboard_studio/hardware/hid/device_connection_state.dart';
import 'package:keyboard_studio/hardware/hid/hid_device.dart';
import 'package:keyboard_studio/hardware/hid/mock_hid_device.dart';
import 'package:keyboard_studio/hardware/services/keyboard_service.dart';

void main() {
  group('HID Hardware Abstraction & Mock Provider Tests', () {
    late MockHidDevice mockDevice;

    setUp(() {
      mockDevice = MockHidDevice();
    });

    tearDown(() async {
      await mockDevice.close();
    });

    test('MockHidDevice implements HidDevice interface contract', () {
      expect(mockDevice, isA<HidDevice>());
      expect(mockDevice.vendorId, equals(UsbConstants.vendorId));
      expect(mockDevice.productId, equals(UsbConstants.productId));
      expect(mockDevice.productName, contains('Simulated'));
      expect(mockDevice.isOpen, isFalse);
    });

    test('MockHidDevice open and close lifecycle', () async {
      final opened = await mockDevice.open();
      expect(opened, isTrue);
      expect(mockDevice.isOpen, isTrue);

      await mockDevice.close();
      expect(mockDevice.isOpen, isFalse);
    });

    test('MockHidDevice configuration query (CMD 0x06, 0x05)', () async {
      await mockDevice.open();

      final req = Uint8List(64);
      req[0] = 0x06;
      req[1] = 0x05;

      final writeOk = await mockDevice.writeReport(req);
      expect(writeOk, isTrue);

      final resp = await mockDevice.readReport(timeoutMs: 500);
      expect(resp, isNotNull);
      expect(resp!.length, equals(64));
      expect(resp[0], equals(0x06));
      expect(resp[1], equals(0x05));
      expect(resp[13], equals(92)); // Battery at index 13
    });

    test('MockHidDevice lighting configuration (CMD 0x06, 0x0B & 0x0A)', () async {
      await mockDevice.open();

      // Write lighting config: Mode 2 (Breathing), Brightness 4, Speed 3
      final writePkt = Uint8List(64);
      writePkt[0] = 0x06;
      writePkt[1] = 0x0B;
      writePkt[7] = 2; // Mode 2
      writePkt[8] = 4; // Brightness 4
      writePkt[9] = 3; // Speed 3

      await mockDevice.writeReport(writePkt);

      // Read back with CMD 0x06, 0x0A
      final queryPkt = Uint8List(64);
      queryPkt[0] = 0x06;
      queryPkt[1] = 0x0A;
      await mockDevice.writeReport(queryPkt);

      final resp = await mockDevice.readReport(timeoutMs: 500);
      expect(resp, isNotNull);
      expect(resp![0], equals(0x06));
      expect(resp[1], equals(0x0A));
      expect(resp[7], equals(2)); // Mode
      expect(resp[8], equals(4)); // Brightness
      expect(resp[9], equals(3)); // Speed
    });

    test('MockHidDevice macro storage read/write (CMD 0x06, 0x0D & 0x0C)', () async {
      await mockDevice.open();

      // Write test chunk to offset 64
      final writePkt = Uint8List(64);
      writePkt[0] = 0x06;
      writePkt[1] = 0x0D;
      writePkt[2] = 4; // 4 bytes
      writePkt[3] = 64; // Offset 64 low byte
      writePkt[4] = 0; // Offset high byte
      writePkt[5] = 0xAA;
      writePkt[6] = 0xBB;
      writePkt[7] = 0xCC;
      writePkt[8] = 0xDD;

      await mockDevice.writeReport(writePkt);

      // Read chunk back
      final readPkt = Uint8List(64);
      readPkt[0] = 0x06;
      readPkt[1] = 0x0C;
      readPkt[2] = 4;
      readPkt[3] = 64;
      readPkt[4] = 0;

      await mockDevice.writeReport(readPkt);
      final resp = await mockDevice.readReport(timeoutMs: 500);

      expect(resp, isNotNull);
      expect(resp![0], equals(0x06));
      expect(resp[1], equals(0x0C));
      expect(resp[8], equals(0xAA));
      expect(resp[9], equals(0xBB));
      expect(resp[10], equals(0xCC));
      expect(resp[11], equals(0xDD));
    });

    test('MockHidDevice profile switching (CMD 0x06, 0xFB)', () async {
      await mockDevice.open();

      // Switch to Profile 2 (index 1)
      final profPkt = Uint8List(64);
      profPkt[0] = 0x06;
      profPkt[1] = 0xFB;
      profPkt[2] = 1;

      await mockDevice.writeReport(profPkt);

      // Verify in config query
      final queryPkt = Uint8List(64);
      queryPkt[0] = 0x06;
      queryPkt[1] = 0x05;
      await mockDevice.writeReport(queryPkt);

      final resp = await mockDevice.readReport(timeoutMs: 500);
      expect(resp, isNotNull);
      expect(resp![16], equals(1)); // Current profile 1 (P2) at index 16
    });

    test('MockHidDevice auto-sleep setting (CMD 0x06, 0xFC)', () async {
      await mockDevice.open();

      // Set 600s sleep (0x0258)
      final sleepPkt = Uint8List(64);
      sleepPkt[0] = 0x06;
      sleepPkt[1] = 0xFC;
      sleepPkt[2] = 2;
      sleepPkt[5] = 0x58; // 600 low
      sleepPkt[6] = 0x02; // 600 high

      await mockDevice.writeReport(sleepPkt);

      // Verify in config
      final queryPkt = Uint8List(64);
      queryPkt[0] = 0x06;
      queryPkt[1] = 0x05;
      await mockDevice.writeReport(queryPkt);

      final resp = await mockDevice.readReport(timeoutMs: 500);
      expect(resp, isNotNull);
      final readSec = resp![19] | (resp[20] << 8); // Auto-sleep at index 19..20
      expect(readSec, equals(600));
    });
  });

  group('KeyboardService State & Repository Tests', () {
    test('KeyboardService connects to mock device and initializes state', () async {
      final service = KeyboardService(customDevice: MockHidDevice());
      expect(service.isConnected, isFalse);
      expect(service.connectionState, equals(DeviceConnectionState.disconnected));

      final connected = await service.connect(forceMock: true);
      expect(connected, isTrue);
      expect(service.isConnected, isTrue);
      expect(service.isUsingMock, isTrue);
      expect(service.connectionState, equals(DeviceConnectionState.connected));
      expect(service.config, isNotNull);
      expect(service.config!.pid, equals(UsbConstants.productId));
      expect(service.lightingConfig, isNotNull);

      await service.disconnect();
      expect(service.isConnected, isFalse);
      expect(service.connectionState, equals(DeviceConnectionState.disconnected));
    });
  });
}
