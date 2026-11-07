/// Hardware connection state representation.
enum DeviceConnectionState {
  /// No device connected, simulator inactive.
  disconnected,

  /// Scanning USB bus / searching for device matching VID/PID.
  searching,

  /// In the process of opening device handle and handshaking.
  connecting,

  /// Successfully connected to physical USB HID keyboard.
  connected,

  /// Device found on USB bus, but access was denied (e.g. missing udev rule on Linux).
  permissionDenied,

  /// Encountered I/O or communication error while communicating with device.
  connectionError,

  /// Attempting to automatically reconnect after unexpected disconnection.
  reconnecting,
}

extension DeviceConnectionStateX on DeviceConnectionState {
  String get displayLabel {
    switch (this) {
      case DeviceConnectionState.disconnected:
        return 'DISCONNECTED';
      case DeviceConnectionState.searching:
        return 'SEARCHING BUS';
      case DeviceConnectionState.connecting:
        return 'CONNECTING';
      case DeviceConnectionState.connected:
        return 'DEVICE CONNECTED';
      case DeviceConnectionState.permissionDenied:
        return 'PERMISSION DENIED';
      case DeviceConnectionState.connectionError:
        return 'COMMUNICATION ERROR';
      case DeviceConnectionState.reconnecting:
        return 'RECONNECTING';
    }
  }

  bool get isOperational => this == DeviceConnectionState.connected;
}
