import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../../core/constants/usb_constants.dart';
import 'hid_device.dart';

// -------------------------------------------------------------
// Native C Structs for hidapi on Linux
// -------------------------------------------------------------

final class HidDeviceInfo extends Struct {
  external Pointer<Utf8> path;
  @Uint16()
  external int vendorId;
  @Uint16()
  external int productId;
  external Pointer<WChar> serialNumber;
  @Uint16()
  external int releaseNumber;
  external Pointer<WChar> manufacturerString;
  external Pointer<WChar> productString;
  @Uint16()
  external int usagePage;
  @Uint16()
  external int usage;
  @Int32()
  external int interfaceNumber;
  external Pointer<HidDeviceInfo> next;
}

final class HidDeviceHandle extends Opaque {}

// -------------------------------------------------------------
// Function Signatures
// -------------------------------------------------------------

typedef HidInitNative = Int32 Function();
typedef HidInitDart = int Function();

typedef HidExitNative = Int32 Function();
typedef HidExitDart = int Function();

typedef HidEnumerateNative = Pointer<HidDeviceInfo> Function(Uint16 vendorId, Uint16 productId);
typedef HidEnumerateDart = Pointer<HidDeviceInfo> Function(int vendorId, int productId);

typedef HidFreeEnumerationNative = Void Function(Pointer<HidDeviceInfo> devs);
typedef HidFreeEnumerationDart = void Function(Pointer<HidDeviceInfo> devs);

typedef HidOpenPathNative = Pointer<HidDeviceHandle> Function(Pointer<Utf8> path);
typedef HidOpenPathDart = Pointer<HidDeviceHandle> Function(Pointer<Utf8> path);

typedef HidWriteNative = Int32 Function(Pointer<HidDeviceHandle> device, Pointer<Uint8> data, IntPtr length);
typedef HidWriteDart = int Function(Pointer<HidDeviceHandle> device, Pointer<Uint8> data, int length);

typedef HidReadTimeoutNative = Int32 Function(Pointer<HidDeviceHandle> device, Pointer<Uint8> data, IntPtr length, Int32 milliseconds);
typedef HidReadTimeoutDart = int Function(Pointer<HidDeviceHandle> device, Pointer<Uint8> data, int length, int milliseconds);

typedef HidCloseNative = Void Function(Pointer<HidDeviceHandle> device);
typedef HidCloseDart = void Function(Pointer<HidDeviceHandle> device);

/// Native Linux FFI implementation of [HidDevice] using libhidapi (hidraw or libusb backend).
class LinuxHidDevice implements HidDevice {
  static DynamicLibrary? _lib;
  static bool _initialized = false;

  static HidInitDart? _hidInit;
  static HidExitDart? _hidExit;
  static HidEnumerateDart? _hidEnumerate;
  static HidFreeEnumerationDart? _hidFreeEnumeration;
  static HidOpenPathDart? _hidOpenPath;
  static HidWriteDart? _hidWrite;
  static HidReadTimeoutDart? _hidReadTimeout;
  static HidCloseDart? _hidClose;

  Pointer<HidDeviceHandle>? _handle;
  final StreamController<Uint8List> _reportStreamController = StreamController<Uint8List>.broadcast();
  bool _isReading = false;

  @override
  bool get isOpen => _handle != null && _handle != nullptr;

  @override
  final int vendorId;

  @override
  final int productId;

  @override
  final String productName;

  final String devicePath;

  LinuxHidDevice({
    required this.vendorId,
    required this.productId,
    required this.productName,
    required this.devicePath,
  });

  @override
  Stream<Uint8List> get reportStream => _reportStreamController.stream;

  /// Loads hidapi dynamic library on Linux safely.
  static bool loadLibrary() {
    if (_initialized) return true;
    if (!Platform.isLinux) return false;

    final candidates = [
      'libhidapi-hidraw.so.0',
      'libhidapi-hidraw.so',
      'libhidapi-libusb.so.0',
      'libhidapi-libusb.so',
      'libhidapi.so.0',
      'libhidapi.so',
    ];

    for (final name in candidates) {
      try {
        _lib = DynamicLibrary.open(name);
        break;
      } catch (_) {
        // Try next candidate
      }
    }

    if (_lib == null) return false;

    try {
      _hidInit = _lib!.lookupFunction<HidInitNative, HidInitDart>('hid_init');
      _hidExit = _lib!.lookupFunction<HidExitNative, HidExitDart>('hid_exit');
      _hidEnumerate = _lib!.lookupFunction<HidEnumerateNative, HidEnumerateDart>('hid_enumerate');
      _hidFreeEnumeration = _lib!.lookupFunction<HidFreeEnumerationNative, HidFreeEnumerationDart>('hid_free_enumeration');
      _hidOpenPath = _lib!.lookupFunction<HidOpenPathNative, HidOpenPathDart>('hid_open_path');
      _hidWrite = _lib!.lookupFunction<HidWriteNative, HidWriteDart>('hid_write');
      _hidReadTimeout = _lib!.lookupFunction<HidReadTimeoutNative, HidReadTimeoutDart>('hid_read_timeout');
      _hidClose = _lib!.lookupFunction<HidCloseNative, HidCloseDart>('hid_close');

      _hidInit!();
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Completer<Uint8List?>? _pendingReadCompleter;

  /// Enumerates connected USB devices on Linux matching Ant Esports MK1300 V2.
  static List<LinuxHidDevice> enumerateDevices({
    int vid = UsbConstants.vendorId,
    int pid = UsbConstants.productId,
  }) {
    if (!loadLibrary() || _hidEnumerate == null) return [];

    final List<LinuxHidDevice> results = [];
    final Pointer<HidDeviceInfo> root = _hidEnumerate!(vid, pid);
    Pointer<HidDeviceInfo> current = root;

    while (current != nullptr) {
      final info = current.ref;
      final pathStr = info.path.toDartString();
      // Match vendor control interface (usagePage 0xFF00, or interface 1/2)
      // Prioritize vendor-defined usagePage 0xFF00 or interfaceNumber == controlInterface
      final isVendorControl = info.usagePage == UsbConstants.usagePage ||
          info.interfaceNumber == UsbConstants.controlInterface;

      if (isVendorControl || info.usagePage == 0) {
        final device = LinuxHidDevice(
          vendorId: info.vendorId,
          productId: info.productId,
          productName: 'Ant Esports MK1300 V2',
          devicePath: pathStr,
        );
        // Put vendor-specific matches at the front of the list
        if (isVendorControl) {
          results.insert(0, device);
        } else {
          results.add(device);
        }
      }
      current = info.next;
    }

    _hidFreeEnumeration!(root);
    return results;
  }

  @override
  Future<bool> open() async {
    if (isOpen) return true;
    if (!loadLibrary() || _hidOpenPath == null) return false;

    final pathPtr = devicePath.toNativeUtf8();
    try {
      _handle = _hidOpenPath!(pathPtr);
      final success = _handle != null && _handle != nullptr;
      if (success) {
        _startBackgroundReadLoop();
      }
      return success;
    } finally {
      calloc.free(pathPtr);
    }
  }

  void _startBackgroundReadLoop() {
    _isReading = true;
    Future.microtask(() async {
      final buf = calloc<Uint8>(64);
      try {
        while (_isReading && isOpen) {
          final res = _hidReadTimeout!(_handle!, buf, 64, 50);
          if (res > 0) {
            final data = Uint8List.fromList(buf.asTypedList(res));
            // Dispatch to awaiting command reader if present
            if (_pendingReadCompleter != null && !_pendingReadCompleter!.isCompleted) {
              final completer = _pendingReadCompleter!;
              _pendingReadCompleter = null;
              completer.complete(data);
            } else if (data.length >= 2 &&
                data[0] == UsbConstants.eventHeaderByte0 &&
                data[1] == UsbConstants.eventHeaderByte1) {
              _reportStreamController.add(data);
            }
          }
          await Future.delayed(const Duration(milliseconds: 10));
        }
      } finally {
        calloc.free(buf);
      }
    });
  }

  @override
  Future<bool> writeReport(Uint8List payload) async {
    if (!isOpen || _hidWrite == null) return false;

    // Allocate 65 bytes: Byte 0 is Report ID 0x00, followed by 64 bytes payload
    final buf = calloc<Uint8>(65);
    try {
      buf[0] = 0x00; // Report ID 0
      for (int i = 0; i < 64 && i < payload.length; i++) {
        buf[i + 1] = payload[i];
      }
      final written = _hidWrite!(_handle!, buf, 65);
      return written >= 0;
    } finally {
      calloc.free(buf);
    }
  }

  @override
  Future<Uint8List?> readReport({int timeoutMs = 1000}) async {
    if (!isOpen) return null;
    final completer = Completer<Uint8List?>();
    _pendingReadCompleter = completer;

    try {
      return await completer.future.timeout(
        Duration(milliseconds: timeoutMs),
        onTimeout: () {
          if (_pendingReadCompleter == completer) {
            _pendingReadCompleter = null;
          }
          return null;
        },
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    _isReading = false;
    if (isOpen && _hidClose != null) {
      _hidClose!(_handle!);
      _handle = null;
    }
    await _reportStreamController.close();
  }

  /// Global cleanup for the hidapi library.
  static void exitLibrary() {
    if (_initialized && _hidExit != null) {
      _hidExit!();
      _initialized = false;
    }
  }
}
