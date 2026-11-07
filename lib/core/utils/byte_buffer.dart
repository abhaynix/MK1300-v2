import 'dart:typed_data';

/// Binary buffer utilities for Little-Endian encoding matching keyboard firmware.
class ByteBufferUtils {
  ByteBufferUtils._();

  /// Reads a 16-bit unsigned integer in Little-Endian format.
  static int readUint16LE(List<int> bytes, int offset) {
    if (offset + 1 >= bytes.length) return 0;
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  /// Writes a 16-bit unsigned integer in Little-Endian format into [target] at [offset].
  static void writeUint16LE(List<int> target, int offset, int value) {
    if (offset + 1 < target.length) {
      target[offset] = value & 0xFF;
      target[offset + 1] = (value >> 8) & 0xFF;
    }
  }

  /// Splits an integer into [lowByte, highByte].
  static List<int> toUint16BytesLE(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  /// Combines [lowByte, highByte] into uint16.
  static int fromUint16BytesLE(int low, int high) {
    return low | (high << 8);
  }

  /// Creates a zero-filled 64-byte payload.
  static Uint8List createReportPayload([List<int>? initialBytes]) {
    final report = Uint8List(64);
    if (initialBytes != null) {
      for (int i = 0; i < initialBytes.length && i < 64; i++) {
        report[i] = initialBytes[i];
      }
    }
    return report;
  }

  /// Formats byte array to debug hex string.
  static String toHexString(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}
