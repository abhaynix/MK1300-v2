/// Device hardware state model.
class KeyboardConfig {
  final int version;
  final int pid;
  final int firmwareVersion;
  final int workMode;
  final int linkStatus;
  final int battery;
  final int charging;
  final int profileCount;
  final int currentProfile;
  final int layerCount;
  final int currentLayer;
  final int autoSleepTime;
  final String serialNumber;

  const KeyboardConfig({
    required this.version,
    required this.pid,
    required this.firmwareVersion,
    required this.workMode,
    required this.linkStatus,
    required this.battery,
    required this.charging,
    required this.profileCount,
    required this.currentProfile,
    required this.layerCount,
    required this.currentLayer,
    required this.autoSleepTime,
    required this.serialNumber,
  });

  int get firmwareVersionMajor => (firmwareVersion >> 8) & 0xFF;
  int get firmwareVersionMinor => firmwareVersion & 0xFF;
  int get activeLayer => currentLayer;

  KeyboardConfig copyWith({
    int? currentProfile,
    int? currentLayer,
    int? autoSleepTime,
    int? battery,
  }) {
    return KeyboardConfig(
      version: version,
      pid: pid,
      firmwareVersion: firmwareVersion,
      workMode: workMode,
      linkStatus: linkStatus,
      battery: battery ?? this.battery,
      charging: charging,
      profileCount: profileCount,
      currentProfile: currentProfile ?? this.currentProfile,
      layerCount: layerCount,
      currentLayer: currentLayer ?? this.currentLayer,
      autoSleepTime: autoSleepTime ?? this.autoSleepTime,
      serialNumber: serialNumber,
    );
  }
}
