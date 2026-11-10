/// USB Hardware Identifiers for MK1300 V2 Keyboard
class UsbConstants {
  UsbConstants._();

  /// Vision MCU Vendor ID (Decimal: 13998)
  static const int vendorId = 0x36AE;

  /// MK1300 V2 61-Key Product ID (Decimal: 65042)
  static const int productId = 0xFE12;

  /// Vendor-defined HID Usage Page (Decimal: 65280)
  static const int usagePage = 0xFF00;

  /// Vendor-defined HID Usage (Decimal: 2)
  static const int usage = 0x0002;

  /// HID Interface number for vendor control
  static const int controlInterface = 1;

  /// Fixed payload size in bytes for USB HID Interrupt reports
  static const int reportPayloadSize = 64;

  /// Total buffer size when prepending Report ID 0x00
  static const int fullReportBufferSize = 65;

  /// Root command opcode for device operations
  static const int rootOpcode = 0x06;

  /// Unsolicited live hardware event header bytes
  static const int eventHeaderByte0 = 0xAA;
  static const int eventHeaderByte1 = 0xFA;
}
