import 'dart:async';
import 'dart:typed_data';

/// Abstract USB HID device communication interface.
abstract class HidDevice {
  /// Whether the device connection is open.
  bool get isOpen;

  /// Vendor ID of the connected device.
  int get vendorId;

  /// Product ID of the connected device.
  int get productId;

  /// Product name reported by the device or descriptor.
  String get productName;

  /// Stream of unsolicited inbound HID reports (e.g. 0xAA, 0xFA events).
  Stream<Uint8List> get reportStream;

  /// Opens the USB HID device handle.
  Future<bool> open();

  /// Closes the USB HID device handle.
  Future<void> close();

  /// Writes a 64-byte report to the device.
  /// On standard hidapi, a 65-byte buffer starting with Report ID 0 is transmitted.
  Future<bool> writeReport(Uint8List payload);

  /// Reads a 64-byte report from the device with [timeoutMs] millisecond timeout.
  Future<Uint8List?> readReport({int timeoutMs = 1000});
}
