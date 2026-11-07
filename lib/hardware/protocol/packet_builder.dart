import 'dart:typed_data';
import 'dart:ui';
import '../../core/constants/usb_constants.dart';
import '../../core/utils/byte_buffer.dart';
import '../../core/utils/color_utils.dart';
import '../../features/device/models/keyboard_config.dart';
import '../../features/lighting/models/lighting_config.dart';
import '../../features/lighting/models/lighting_mode.dart';

/// Builder and parser for MK1300 V2 64-byte USB HID report packets.
class PacketBuilder {
  PacketBuilder._();

  // -------------------------------------------------------------
  // Command Packet Construction
  // -------------------------------------------------------------

  /// Constructs CMD 0x06, Sub 0x05 (Get Device Hardware Config)
  static Uint8List buildGetConfigPacket() {
    return ByteBufferUtils.createReportPayload([UsbConstants.rootOpcode, 0x05]);
  }

  /// Constructs CMD 0x06, Sub 0x0A (Get Active Lighting Config)
  static Uint8List buildGetLightingPacket() {
    return ByteBufferUtils.createReportPayload([UsbConstants.rootOpcode, 0x0A]);
  }

  /// Constructs CMD 0x06, Sub 0x16 (Query Effect Preset Defaults)
  static Uint8List buildQueryEffectPacket(int mode) {
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x16,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      mode,
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x0B (Set Active Lighting Config)
  static Uint8List buildSetLightingPacket({
    required int type,
    required int mode,
    required int brightness,
    required int speed,
    required int direction,
    required int colorMode,
    required Color color,
  }) {
    final hsv = ColorUtils.toFirmwareHsv(color);
    final int h = hsv[0];
    final int s = hsv[1];
    final int v = hsv[2];

    final int effectiveColorMode = (mode == 0) ? 0 : colorMode;

    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x0B,
      0x0B, // Payload length (11 bytes)
      0x00,
      0x00,
      type,
      0x00,
      mode,
      brightness,
      speed,
      direction,
      effectiveColorMode,
      0x00,
      h,
      s,
      v,
    ]);
  }

  /// Constructs CMD 0x06, Sub 0xFB (Set Active Profile: 0, 1, 2)
  static Uint8List buildSetProfilePacket(int profileIndex) {
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0xFB,
      profileIndex,
    ]);
  }

  /// Constructs CMD 0x06, Sub 0xFC (Set Auto Sleep Time in seconds)
  static Uint8List buildSetSleepPacket(int seconds) {
    final secBytes = ByteBufferUtils.toUint16BytesLE(seconds);
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0xFC,
      0x02,
      0x00,
      0x00,
      secBytes[0],
      secBytes[1],
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x0F, 0xFF (Factory Reset)
  static Uint8List buildFactoryResetPacket() {
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x0F,
      0xFF,
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x0F, 0x04 (Reset Macros)
  static Uint8List buildResetMacrosPacket() {
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x0F,
      0x04,
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x08 (Read Keymap Chunk)
  static Uint8List buildReadKeymapChunkPacket(int byteOffset, int layer) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(byteOffset);
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x08,
      0x3A, // 58 bytes
      offBytes[0],
      offBytes[1],
      0x00,
      layer,
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x09 (Write Keymap Chunk)
  static Uint8List buildWriteKeymapChunkPacket(
    int byteOffset,
    int layer,
    List<int> chunkData,
    bool isLastChunk,
    int totalBytes,
  ) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(byteOffset);
    int lenParam = 59;
    if (isLastChunk && (totalBytes % 56) > 0) {
      lenParam = (totalBytes % 56) + 3;
    }

    final packet = ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x09,
      lenParam,
      offBytes[0],
      offBytes[1],
      0x00,
      layer,
      0x00,
    ]);

    for (int i = 0; i < chunkData.length && (8 + i) < 64; i++) {
      packet[8 + i] = chunkData[i];
    }
    return packet;
  }

  /// Constructs CMD 0x06, Sub 0x10 (Write Single Key Remap)
  static Uint8List buildWriteSingleKeyPacket({
    required int keyIndex,
    required int layer,
    required int type,
    required int code1,
    required int code2,
    required int code3,
  }) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(4 * keyIndex);
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x10,
      0x07,
      offBytes[0],
      offBytes[1],
      0x00,
      layer,
      0x00,
      type,
      code1,
      code2,
      code3,
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x13 (Read Custom Per-Key RGB Chunk)
  static Uint8List buildReadRgbChunkPacket(int byteOffset) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(byteOffset);
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x13,
      0x3A,
      offBytes[0],
      offBytes[1],
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x12 (Write Custom Per-Key RGB Chunk)
  static Uint8List buildWriteRgbChunkPacket(
    int byteOffset,
    List<int> chunkData,
    bool isLastChunk,
    int totalBytes,
  ) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(byteOffset);
    int lenParam = 59;
    if (isLastChunk && (totalBytes % 56) > 0) {
      lenParam = (totalBytes % 56) + 3;
    }

    final packet = ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x12,
      lenParam,
      offBytes[0],
      offBytes[1],
    ]);

    for (int i = 0; i < chunkData.length && (7 + i) < 64; i++) {
      packet[7 + i] = chunkData[i];
    }
    return packet;
  }

  /// Constructs CMD 0x06, Sub 0x14 (Write Single Key RGB Color)
  static Uint8List buildWriteSingleKeyRgbPacket({
    required int keyIndex,
    required Color color,
  }) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(3 * keyIndex);
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x14,
      0x03,
      offBytes[0],
      offBytes[1],
      0x00,
      0x00,
      0x00,
      (color.r * 255.0).round().clamp(0, 255),
      (color.g * 255.0).round().clamp(0, 255),
      (color.b * 255.0).round().clamp(0, 255),
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x0C (Read Macro Chunk)
  static Uint8List buildReadMacroChunkPacket(int byteOffset, int length) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(byteOffset);
    return ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x0C,
      length,
      offBytes[0],
      offBytes[1],
    ]);
  }

  /// Constructs CMD 0x06, Sub 0x0D (Write Macro Chunk)
  static Uint8List buildWriteMacroChunkPacket(int byteOffset, List<int> chunk) {
    final offBytes = ByteBufferUtils.toUint16BytesLE(byteOffset);
    final packet = ByteBufferUtils.createReportPayload([
      UsbConstants.rootOpcode,
      0x0D,
      chunk.length,
      offBytes[0],
      offBytes[1],
    ]);
    for (int i = 0; i < chunk.length && (5 + i) < 64; i++) {
      packet[5 + i] = chunk[i];
    }
    return packet;
  }

  // -------------------------------------------------------------
  // Response Parsing
  // -------------------------------------------------------------

  /// Parses response to CMD 0x06, Sub 0x05 into [KeyboardConfig].
  static KeyboardConfig? parseConfigResponse(Uint8List response) {
    if (response.length < 21) return null;
    final statusLen = response[2];
    final hwVer = ByteBufferUtils.readUint16LE(response, 5);
    final pid = ByteBufferUtils.readUint16LE(response, 7);
    final fwVer = ByteBufferUtils.readUint16LE(response, 9);
    final workMode = response[11];
    final linkStatus = response[12];
    final battery = response[13];
    final charging = response[14];
    final profileCnt = response[15];
    final activeProfile = response[16];
    final layerCnt = response[17];
    final activeLayer = response[18];
    final autoSleep = (statusLen >= 16) ? ByteBufferUtils.readUint16LE(response, 19) : 0;

    String serialStr = '';
    if (statusLen >= 40 && response.length >= 43) {
      final chars = response.sublist(21, 43).where((c) => c > 0).toList();
      serialStr = String.fromCharCodes(chars);
    }

    return KeyboardConfig(
      version: hwVer,
      pid: pid,
      firmwareVersion: fwVer,
      workMode: workMode,
      linkStatus: linkStatus,
      battery: battery,
      charging: charging,
      profileCount: profileCnt,
      currentProfile: activeProfile,
      layerCount: layerCnt,
      currentLayer: activeLayer,
      autoSleepTime: autoSleep,
      serialNumber: serialStr.isNotEmpty ? serialStr : 'MK1300-V2',
    );
  }

  /// Parses response to CMD 0x06, Sub 0x0A into [LightingConfig].
  static LightingConfig? parseLightingResponse(Uint8List response) {
    if (response.length < 16) return null;
    final type = response[5];
    final modeVal = response[7];
    final brightness = response[8];
    final speed = response[9];
    final direction = response[10];
    final colorMode = response[11];
    final singleColorIdx = response[12];
    final hByte = response[13];
    final sByte = response[14];
    final vByte = response[15];

    final mode = LightingMode.values.firstWhere(
      (m) => m.value == modeVal,
      orElse: () => LightingMode.staticOn,
    );

    return LightingConfig(
      type: type,
      mode: mode,
      brightness: brightness,
      speed: speed,
      direction: direction,
      colorMode: colorMode,
      singleColorIndex: singleColorIdx,
      hue: (360.0 * hByte / 255.0).clamp(0.0, 360.0),
      saturation: (100.0 * sByte / 255.0).clamp(0.0, 100.0),
      value: (100.0 * vByte / 255.0).clamp(0.0, 100.0),
    );
  }
}
