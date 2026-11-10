import 'dart:async';
import 'dart:typed_data';
import '../../core/constants/usb_constants.dart';
import '../../core/utils/byte_buffer.dart';
import '../../features/key_remapping/models/key_geometry.dart';
import 'hid_device.dart';

/// Simulated MK1300 V2 USB HID device for development, testing, and offline previews.
class MockHidDevice implements HidDevice {
  bool _isOpen = false;
  final StreamController<Uint8List> _reportStreamController = StreamController<Uint8List>.broadcast();

  // Internal simulated state
  int _activeProfile = 0;
  int _activeLayer = 0;
  int _batteryLevel = 92;
  int _autoSleepSeconds = 120;
  int _lightingMode = 5; // Horizontal Streamer
  int _brightness = 3;
  int _speed = 2;
  int _direction = 1;
  int _colorMode = 0; // Rainbow dynamic
  int _hue = 150;
  int _sat = 255;
  int _val = 255;

  final Uint8List _macroEeprom = Uint8List(4096);
  final List<List<int>> _layer0Keys = List.generate(74, (i) => [32, 0, i, 0]);
  final List<List<int>> _layer1Keys = List.generate(74, (i) => [32, 0, i, 0]);
  final List<List<int>> _keyColors = List.generate(74, (i) => [0, 200, 255]);

  // Failure & delay simulation flags
  bool simulateWriteFailure = false;
  bool simulateReadFailure = false;
  int simulatedResponseDelayMs = 0;

  Uint8List? _lastWritePayload;

  MockHidDevice() {
    // Initialize macro table with 0xFF in header
    for (int i = 0; i < 64; i++) {
      _macroEeprom[i] = 0xFF;
    }
    // Initialize keys with standard 61-key layout defaults
    for (final geo in KeyGeometry.fallbackLayout61) {
      if (geo.index < _layer0Keys.length) {
        _layer0Keys[geo.index] = [32, 0, geo.defaultCode, 0];
        _layer1Keys[geo.index] = [32, 0, geo.defaultCode, 0];
      }
    }
  }

  @override
  bool get isOpen => _isOpen;

  @override
  int get vendorId => UsbConstants.vendorId;

  @override
  int get productId => UsbConstants.productId;

  @override
  String get productName => 'MK1300 V2 (Simulated)';

  int get batteryLevel => _batteryLevel;

  /// Inspects a simulated key descriptor tuple [type, code1, code2, code3] for testing.
  List<int>? getKeyDescriptor(int layer, int keyIdx) {
    final list = (layer == 1) ? _layer1Keys : _layer0Keys;
    if (keyIdx >= 0 && keyIdx < list.length) {
      return List<int>.from(list[keyIdx]);
    }
    return null;
  }

  @override
  Stream<Uint8List> get reportStream => _reportStreamController.stream;

  @override
  Future<bool> open() async {
    _isOpen = true;
    return true;
  }

  @override
  Future<void> close() async {
    _isOpen = false;
    unawaited(_reportStreamController.close());
  }

  @override
  Future<bool> writeReport(Uint8List payload) async {
    if (!_isOpen || simulateWriteFailure) return false;
    if (simulatedResponseDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: simulatedResponseDelayMs));
    }
    _lastWritePayload = Uint8List.fromList(payload);

    if (payload.length < 2) return true;
    final opcode = payload[0];
    final sub = payload[1];

    if (opcode == UsbConstants.rootOpcode) {
      switch (sub) {
        case 0x0B: // Set Lighting
          if (payload.length >= 16) {
            _lightingMode = payload[7];
            _brightness = payload[8];
            _speed = payload[9];
            _direction = payload[10];
            _colorMode = payload[11];
            _hue = payload[13];
            _sat = payload[14];
            _val = payload[15];
          }
          break;
        case 0xFB: // Set Profile
          if (payload.length >= 3) {
            _activeProfile = payload[2];
          }
          break;
        case 0xFC: // Set Sleep
          if (payload.length >= 7) {
            _autoSleepSeconds = ByteBufferUtils.fromUint16BytesLE(payload[5], payload[6]);
          }
          break;
        case 0x09: // Write Keymap Chunk
          if (payload.length >= 8) {
            final lenParam = payload[2];
            final byteOffset = ByteBufferUtils.fromUint16BytesLE(payload[3], payload[4]);
            final layer = payload[6];
            final targetLayer = (layer == 1) ? _layer1Keys : _layer0Keys;
            final chunkDataLen = (lenParam > 3) ? (lenParam - 3) : (payload.length - 8);

            for (int i = 0; i < chunkDataLen && (8 + i + 3) < payload.length; i += 4) {
              final keyByteOffset = byteOffset + i;
              final keyIdx = keyByteOffset ~/ 4;
              if (keyIdx < targetLayer.length) {
                targetLayer[keyIdx] = [
                  payload[8 + i],
                  payload[8 + i + 1],
                  payload[8 + i + 2],
                  payload[8 + i + 3],
                ];
              }
            }
          }
          break;
        case 0x10: // Write Single Key
          if (payload.length >= 12) {
            final keyOffset = ByteBufferUtils.fromUint16BytesLE(payload[3], payload[4]);
            final keyIdx = keyOffset ~/ 4;
            final layer = payload[6];
            final targetLayer = (layer == 1) ? _layer1Keys : _layer0Keys;
            if (keyIdx < targetLayer.length) {
              targetLayer[keyIdx] = [payload[8], payload[9], payload[10], payload[11]];
            }
          }
          break;
        case 0x14: // Write Single Key RGB
          if (payload.length >= 11) {
            final colorOffset = ByteBufferUtils.fromUint16BytesLE(payload[3], payload[4]);
            final keyIdx = colorOffset ~/ 3;
            if (keyIdx < _keyColors.length) {
              _keyColors[keyIdx] = [payload[8], payload[9], payload[10]];
            }
          }
          break;
        case 0x0D: // Write Macro Chunk
          if (payload.length >= 5) {
            final len = payload[2];
            final offset = ByteBufferUtils.fromUint16BytesLE(payload[3], payload[4]);
            for (int i = 0; i < len && (offset + i) < 4096; i++) {
              if (5 + i < payload.length) {
                _macroEeprom[offset + i] = payload[5 + i];
              }
            }
          }
          break;
        case 0x0F: // Reset
          if (payload.length >= 3) {
            if (payload[2] == 0xFF) {
              // Factory reset
              _lightingMode = 1;
              _brightness = 3;
              _speed = 2;
              _activeLayer = 0;
              _batteryLevel = 92;
            } else if (payload[2] == 0x04) {
              // Reset Macro storage
              for (int i = 0; i < 64; i++) {
                _macroEeprom[i] = 0xFF;
              }
              for (int i = 64; i < 4096; i++) {
                _macroEeprom[i] = 0x00;
              }
            }
          }
          break;
      }
    }
    return true;
  }

  @override
  Future<Uint8List?> readReport({int timeoutMs = 1000}) async {
    if (!_isOpen || simulateReadFailure || _lastWritePayload == null) return null;
    if (simulatedResponseDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: simulatedResponseDelayMs));
    }

    final req = _lastWritePayload!;
    final opcode = req[0];
    final sub = req[1];
    final resp = Uint8List(64);

    if (opcode == UsbConstants.rootOpcode) {
      switch (sub) {
        case 0x05: // Get Config
          resp[0] = 0x06;
          resp[1] = 0x05;
          resp[2] = 0x2A; // Length / status (42)
          // Firmware & hardware bytes
          ByteBufferUtils.writeUint16LE(resp, 5, 0x0100); // HW Version 1.0
          ByteBufferUtils.writeUint16LE(resp, 7, UsbConstants.productId);
          ByteBufferUtils.writeUint16LE(resp, 9, 102); // FW Version 102
          resp[11] = 1; // Work Mode (Wired)
          resp[12] = 1; // Link Status (Connected)
          resp[13] = _batteryLevel;
          resp[14] = 0; // Not charging
          resp[15] = 3; // 3 profiles
          resp[16] = _activeProfile;
          resp[17] = 2; // 2 layers
          resp[18] = _activeLayer;
          ByteBufferUtils.writeUint16LE(resp, 19, _autoSleepSeconds);
          // Serial number "MK1300V2-2026"
          final serial = 'MK1300V2-2026'.codeUnits;
          for (int i = 0; i < serial.length && i < 22; i++) {
            resp[21 + i] = serial[i];
          }
          return resp;

        case 0x0A: // Get Lighting Config
          resp[0] = 0x06;
          resp[1] = 0x0A;
          resp[2] = 0x0B;
          resp[5] = 0; // Type
          resp[6] = 0;
          resp[7] = _lightingMode;
          resp[8] = _brightness;
          resp[9] = _speed;
          resp[10] = _direction;
          resp[11] = _colorMode;
          resp[12] = 0; // Single color index
          resp[13] = _hue;
          resp[14] = _sat;
          resp[15] = _val;
          return resp;

        case 0x16: // Query Effect Preset Defaults
          final targetMode = req[7];
          resp[0] = 0x06;
          resp[1] = 0x16;
          resp[7] = targetMode;
          resp[8] = 3; // Brightness
          resp[9] = 2; // Speed
          resp[10] = 1; // Direction
          resp[11] = 0; // Color mode
          resp[13] = 100;
          resp[14] = 255;
          resp[15] = 255;
          return resp;

        case 0x08: // Read Keymap Chunk
          final offset = ByteBufferUtils.fromUint16BytesLE(req[3], req[4]);
          final layer = req[6];
          final sourceKeys = (layer == 1) ? _layer1Keys : _layer0Keys;
          resp[0] = 0x06;
          resp[1] = 0x08;
          // Flatten 4-byte key descriptors into payload starting at offset 8
          int written = 0;
          for (int i = 0; i < sourceKeys.length && written < 56; i++) {
            final byteIndex = i * 4;
            if (byteIndex >= offset && byteIndex < offset + 56) {
              final internalOffset = byteIndex - offset;
              for (int k = 0; k < 4 && internalOffset + k < 56; k++) {
                resp[8 + internalOffset + k] = sourceKeys[i][k];
                written++;
              }
            }
          }
          return resp;

        case 0x13: // Read RGB Chunk
          final offset = ByteBufferUtils.fromUint16BytesLE(req[3], req[4]);
          resp[0] = 0x06;
          resp[1] = 0x13;
          int written = 0;
          for (int i = 0; i < _keyColors.length && written < 56; i++) {
            final byteIndex = i * 3;
            if (byteIndex >= offset && byteIndex < offset + 56) {
              final internalOffset = byteIndex - offset;
              for (int k = 0; k < 3 && internalOffset + k < 56; k++) {
                resp[8 + internalOffset + k] = _keyColors[i][k];
                written++;
              }
            }
          }
          return resp;

        case 0x0C: // Read Macro Chunk
          final len = req[2];
          final offset = ByteBufferUtils.fromUint16BytesLE(req[3], req[4]);
          resp[0] = 0x06;
          resp[1] = 0x0C;
          for (int i = 0; i < len && offset + i < 4096 && 8 + i < 64; i++) {
            resp[8 + i] = _macroEeprom[offset + i];
          }
          return resp;
      }
    }

    return resp;
  }

  /// Emits a raw unsolicited hardware report.
  void emitUnsolicitedReport(Uint8List report) {
    if (_isOpen && !_reportStreamController.isClosed) {
      _reportStreamController.add(report);
    }
  }

  /// Emits a simulated live hardware shortcut event (e.g. Fn + \ changed mode).
  void simulateHardwareEvent(int newMode, int brightness, int speed, {int direction = 1, int colorMode = 0, int h = 100, int s = 255, int v = 255}) {
    final event = Uint8List(64);
    event[0] = UsbConstants.eventHeaderByte0; // 0xAA
    event[1] = UsbConstants.eventHeaderByte1; // 0xFA
    event[2] = 0x09; // length
    event[6] = 1;    // type
    event[7] = newMode;
    event[8] = brightness;
    event[9] = speed;
    event[10] = direction;
    event[11] = colorMode;
    event[12] = h;
    event[13] = s;
    event[14] = v;
    emitUnsolicitedReport(event);
  }
}
