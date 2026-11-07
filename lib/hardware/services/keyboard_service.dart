import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../core/constants/usb_constants.dart';
import '../../core/utils/color_utils.dart';
import '../../features/device/models/keyboard_config.dart';
import '../../features/key_remapping/models/key_geometry.dart';
import '../../features/key_remapping/models/key_mapping.dart';
import '../../features/lighting/models/lighting_config.dart';
import '../../features/lighting/models/lighting_mode.dart';
import '../../features/macros/models/macro_model.dart';
import '../../features/macros/services/macro_compiler.dart';
import '../hid/device_connection_state.dart';
import '../hid/hid_device.dart';
import '../hid/linux_hid_device.dart';
import '../hid/mock_hid_device.dart';
import '../protocol/command_queue.dart';
import '../protocol/packet_builder.dart';

/// Central controller service for MK1300 V2 keyboard management.
class KeyboardService extends ChangeNotifier {
  HidDevice _device;
  late CommandQueue _commandQueue;
  StreamSubscription<Uint8List>? _eventSub;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isUsingMock = false;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;

  KeyboardConfig? _config;
  LightingConfig? _lightingConfig;
  int _activeLayer = 0; // 0 = Main, 1 = Fn
  int _selectedKeyIndex = 0;

  // Key mappings for both layers
  final List<KeyMapping> _layer0 = KeyGeometry.layout61.map((g) => KeyMapping.fromGeometry(g)).toList();
  final List<KeyMapping> _layer1 = KeyGeometry.layout61.map((g) => KeyMapping.fromGeometry(g)).toList();

  // Macros
  List<MacroModel> _macros = List.generate(16, (i) => MacroModel(name: 'M$i', actions: []));

  KeyboardService({HidDevice? customDevice})
      : _device = customDevice ?? MockHidDevice() {
    _commandQueue = CommandQueue(_device);
    if (customDevice is MockHidDevice) {
      _isUsingMock = true;
    }
  }

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isUsingMock => _isUsingMock;
  DeviceConnectionState get connectionState => _connectionState;
  HidDevice get device => _device;
  int get batteryLevel => (_device is MockHidDevice) ? (_device as MockHidDevice).batteryLevel : 100;
  KeyboardConfig? get config => _config;
  LightingConfig? get lightingConfig => _lightingConfig;
  int get activeLayer => _activeLayer;
  int get selectedKeyIndex => _selectedKeyIndex;
  List<KeyMapping> get currentKeys => (_activeLayer == 1) ? _layer1 : _layer0;
  List<KeyMapping> get layer0Keys => _layer0;
  List<KeyMapping> get layer1Keys => _layer1;
  List<MacroModel> get macros => _macros;

  KeyMapping? get selectedKey {
    if (_selectedKeyIndex >= 0 && _selectedKeyIndex < currentKeys.length) {
      return currentKeys[_selectedKeyIndex];
    }
    return null;
  }

  void selectKey(int index) {
    _selectedKeyIndex = index;
    notifyListeners();
  }

  void setActiveLayer(int layer) {
    if (_activeLayer != layer) {
      _activeLayer = layer;
      notifyListeners();
    }
  }

  /// Attempts to connect to physical keyboard, falling back to simulated mock device.
  Future<bool> connect({bool forceMock = false}) async {
    _isConnecting = true;
    _connectionState = DeviceConnectionState.searching;
    notifyListeners();

    try {
      if (!forceMock) {
        _connectionState = DeviceConnectionState.searching;
        notifyListeners();
        final physicalDevices = LinuxHidDevice.enumerateDevices();
        if (physicalDevices.isNotEmpty) {
          _connectionState = DeviceConnectionState.connecting;
          notifyListeners();
          await _device.close();
          _device = physicalDevices.first;
          _commandQueue = CommandQueue(_device);
          _isUsingMock = false;
        } else {
          // No physical keyboard found, use Mock device
          _device = MockHidDevice();
          _commandQueue = CommandQueue(_device);
          _isUsingMock = true;
        }
      } else {
        _device = MockHidDevice();
        _commandQueue = CommandQueue(_device);
        _isUsingMock = true;
      }

      final opened = await _device.open();
      if (!opened) {
        _isConnected = false;
        _isConnecting = false;
        _connectionState = _isUsingMock
            ? DeviceConnectionState.connectionError
            : DeviceConnectionState.permissionDenied;
        notifyListeners();
        return false;
      }

      _isConnected = true;
      _connectionState = DeviceConnectionState.connected;
      _eventSub = _device.reportStream.listen(_handleHardwareEvent);

      // Perform initial device queries
      await _fetchInitialHardwareState();
      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _connectionState = DeviceConnectionState.connectionError;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await _device.close();
    _isConnected = false;
    _connectionState = DeviceConnectionState.disconnected;
    notifyListeners();
  }

  Future<void> _fetchInitialHardwareState() async {
    // 1. Get Hardware Config
    final cfgPacket = PacketBuilder.buildGetConfigPacket();
    final cfgResp = await _commandQueue.writeAndReadCommand(cfgPacket);
    if (cfgResp != null) {
      _config = PacketBuilder.parseConfigResponse(cfgResp);
    }

    // 2. Get Lighting Config
    final lightPacket = PacketBuilder.buildGetLightingPacket();
    final lightResp = await _commandQueue.writeAndReadCommand(lightPacket);
    if (lightResp != null) {
      _lightingConfig = PacketBuilder.parseLightingResponse(lightResp);
    }

    // 3. Read Key Mappings for Layer 0 & 1
    await _readKeyLayoutFromDevice(0);
    await _readKeyLayoutFromDevice(1);

    // 4. Read Custom Per-Key RGB
    await _readCustomRgbFromDevice();

    // 5. Read Macros
    await _readMacrosFromDevice();
  }

  void _handleHardwareEvent(Uint8List report) {
    if (report.length >= 16 &&
        report[0] == UsbConstants.eventHeaderByte0 &&
        report[1] == UsbConstants.eventHeaderByte1) {
      final updatedLight = PacketBuilder.parseLightingResponse(report);
      if (updatedLight != null) {
        _lightingConfig = updatedLight;
        notifyListeners();
      }
    }
  }

  // -------------------------------------------------------------
  // Lighting Actions
  // -------------------------------------------------------------

  Future<void> setLightingMode(LightingMode mode) async {
    if (_lightingConfig == null) return;
    
    // First query effect defaults
    final query = PacketBuilder.buildQueryEffectPacket(mode.value);
    final presetResp = await _commandQueue.writeAndReadCommand(query);

    int brt = _lightingConfig!.brightness;
    int spd = _lightingConfig!.speed;
    int dir = _lightingConfig!.direction;
    int clrMode = _lightingConfig!.colorMode;

    if (presetResp != null && presetResp.length >= 16) {
      brt = presetResp[8];
      spd = presetResp[9];
      dir = presetResp[10];
      clrMode = presetResp[11];
    }

    _lightingConfig = _lightingConfig!.copyWith(
      mode: mode,
      brightness: brt,
      speed: spd,
      direction: dir,
      colorMode: clrMode,
    );
    notifyListeners();

    final packet = PacketBuilder.buildSetLightingPacket(
      type: _lightingConfig!.type,
      mode: mode.value,
      brightness: brt,
      speed: spd,
      direction: dir,
      colorMode: clrMode,
      color: _lightingConfig!.color,
    );
    await _commandQueue.sendCommand(packet);
  }

  Future<void> updateLightingParams({
    int? brightness,
    int? speed,
    int? direction,
    Color? color,
    int? colorMode,
  }) async {
    if (_lightingConfig == null) return;

    final newConfig = _lightingConfig!.copyWith(
      brightness: brightness,
      speed: speed,
      direction: direction,
      colorMode: colorMode,
      hue: color != null ? ColorUtils.toFirmwareHsv(color)[0].toDouble() * 360.0 / 255.0 : null,
      saturation: color != null ? ColorUtils.toFirmwareHsv(color)[1].toDouble() * 100.0 / 255.0 : null,
      value: color != null ? ColorUtils.toFirmwareHsv(color)[2].toDouble() * 100.0 / 255.0 : null,
    );
    _lightingConfig = newConfig;
    notifyListeners();

    final packet = PacketBuilder.buildSetLightingPacket(
      type: newConfig.type,
      mode: newConfig.mode.value,
      brightness: newConfig.brightness,
      speed: newConfig.speed,
      direction: newConfig.direction,
      colorMode: newConfig.colorMode,
      color: newConfig.color,
    );
    await _commandQueue.sendCommand(packet);
  }

  // -------------------------------------------------------------
  // Key Remapping Actions
  // -------------------------------------------------------------

  Future<void> remapKey(int keyIndex, {
    required int type,
    required int code1,
    required int code2,
    required int code3,
    required String newName,
  }) async {
    final list = currentKeys;
    if (keyIndex < 0 || keyIndex >= list.length) return;

    final key = list[keyIndex];
    key.newType = type;
    key.newCode1 = code1;
    key.newCode2 = code2;
    key.newCode3 = code3;
    key.newName = newName;
    notifyListeners();

    // Fast single-key hardware write
    final packet = PacketBuilder.buildWriteSingleKeyPacket(
      keyIndex: key.keyIndex,
      layer: _activeLayer,
      type: type,
      code1: code1,
      code2: code2,
      code3: code3,
    );
    await _commandQueue.sendCommand(packet);
  }

  Future<void> setSingleKeyColor(int keyIndex, Color color) async {
    final list = currentKeys;
    if (keyIndex < 0 || keyIndex >= list.length) return;

    final key = list[keyIndex];
    key.colorHex = ColorUtils.toHex(color);
    notifyListeners();

    final packet = PacketBuilder.buildWriteSingleKeyRgbPacket(
      keyIndex: key.keyIndex,
      color: color,
    );
    await _commandQueue.sendCommand(packet);
  }

  Future<void> _readKeyLayoutFromDevice(int layer) async {
    final target = (layer == 1) ? _layer1 : _layer0;
    // 61 keys = 244 bytes. Read in 56-byte chunks (Math.ceil(244/56) = 5 chunks)
    final flatData = Uint8List(1024);
    int written = 0;

    for (int chunk = 0; chunk < 5; chunk++) {
      final req = PacketBuilder.buildReadKeymapChunkPacket(56 * chunk, layer);
      final resp = await _commandQueue.writeAndReadCommand(req);
      if (resp != null && resp.length >= 64) {
        final payload = resp.sublist(8);
        for (int i = 0; i < payload.length && (written + i) < 1024; i++) {
          flatData[written + i] = payload[i];
        }
      }
      written += 56;
    }

    for (int i = 0; i < target.length; i++) {
      final offset = 4 * target[i].keyIndex;
      if (offset + 3 < flatData.length && flatData[offset] != 0) {
        target[i].newType = flatData[offset];
        target[i].newCode1 = flatData[offset + 1];
        target[i].newCode2 = flatData[offset + 2];
        target[i].newCode3 = flatData[offset + 3];
      }
    }
  }

  Future<void> _readCustomRgbFromDevice() async {
    // 61 keys = 183 bytes. Read in 56-byte chunks (4 chunks)
    final flatData = Uint8List(1024);
    int written = 0;

    for (int chunk = 0; chunk < 4; chunk++) {
      final req = PacketBuilder.buildReadRgbChunkPacket(56 * chunk);
      final resp = await _commandQueue.writeAndReadCommand(req);
      if (resp != null && resp.length >= 64) {
        final payload = resp.sublist(8);
        for (int i = 0; i < payload.length && (written + i) < 1024; i++) {
          flatData[written + i] = payload[i];
        }
      }
      written += 56;
    }

    for (int i = 0; i < _layer0.length; i++) {
      final offset = 3 * _layer0[i].keyIndex;
      if (offset + 2 < flatData.length) {
        final r = flatData[offset];
        final g = flatData[offset + 1];
        final b = flatData[offset + 2];
        if (r != 0 || g != 0 || b != 0) {
          final hex = ColorUtils.toHex(Color.fromARGB(255, r, g, b));
          _layer0[i].colorHex = hex;
          _layer1[i].colorHex = hex;
        }
      }
    }
  }

  // -------------------------------------------------------------
  // Macro Actions
  // -------------------------------------------------------------

  Future<void> _readMacrosFromDevice() async {
    final eeprom = Uint8List(4096);
    for (int offset = 0; offset < 4096; offset += 56) {
      final len = (4096 - offset < 56) ? (4096 - offset) : 56;
      final req = PacketBuilder.buildReadMacroChunkPacket(offset, len);
      final resp = await _commandQueue.writeAndReadCommand(req);
      if (resp != null && resp.length >= 64) {
        final payload = resp.sublist(8);
        for (int i = 0; i < len && (offset + i) < 4096 && i < payload.length; i++) {
          eeprom[offset + i] = payload[i];
        }
      }
    }
    _macros = MacroCompiler.decompileFromEeprom(eeprom);
    notifyListeners();
  }

  Future<void> saveMacrosToKeyboard(List<MacroModel> newMacros) async {
    _macros = newMacros;
    notifyListeners();

    final eeprom = MacroCompiler.compileToEeprom(newMacros);
    // Write in 59-byte chunks matching JavaScript setMacroData
    for (int offset = 0; offset < 4096; offset += 59) {
      final chunkLen = (4096 - offset < 59) ? (4096 - offset) : 59;
      final chunk = eeprom.sublist(offset, offset + chunkLen);
      final packet = PacketBuilder.buildWriteMacroChunkPacket(offset, chunk);
      await _commandQueue.sendCommand(packet);
    }
  }

  // -------------------------------------------------------------
  // Profile & System Settings Actions
  // -------------------------------------------------------------

  Future<void> switchProfile(int profileIndex) async {
    final packet = PacketBuilder.buildSetProfilePacket(profileIndex);
    await _commandQueue.sendCommand(packet);
    if (_config != null) {
      _config = _config!.copyWith(currentProfile: profileIndex);
    }
    notifyListeners();
    // Refresh device parameters for new profile
    await _fetchInitialHardwareState();
  }

  Future<void> setAutoSleepTime(int seconds) async {
    final packet = PacketBuilder.buildSetSleepPacket(seconds);
    await _commandQueue.sendCommand(packet);
    if (_config != null) {
      _config = _config!.copyWith(autoSleepTime: seconds);
    }
    notifyListeners();
  }

  Future<void> restoreFactoryDefaults() async {
    final packet = PacketBuilder.buildFactoryResetPacket();
    await _commandQueue.sendCommand(packet);
    await Future.delayed(const Duration(milliseconds: 500));
    await _fetchInitialHardwareState();
  }
}
