import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk1300_v2/core/constants/usb_constants.dart';
import 'package:mk1300_v2/features/key_remapping/models/key_geometry.dart';
import 'package:mk1300_v2/features/key_remapping/models/key_mapping.dart';
import 'package:mk1300_v2/features/key_remapping/presentation/key_remapping_page.dart';
import 'package:mk1300_v2/features/key_remapping/presentation/keyboard_visualizer.dart';
import 'package:mk1300_v2/hardware/hid/hid_device.dart';
import 'package:mk1300_v2/hardware/hid/mock_hid_device.dart';
import 'package:mk1300_v2/hardware/protocol/packet_builder.dart';
import 'package:mk1300_v2/hardware/services/keyboard_service.dart';

/// Pre-loaded fallback geometries to avoid rootBundle.loadString in tests.
final _testGeometries = KeyGeometry.fallbackLayout61;

/// Fake physical HID device for testing safety gate blocking without physical USB hardware.
class _FakePhysicalHidDevice implements HidDevice {
  bool _isOpen = false;
  Uint8List? lastWrittenPayload;

  @override
  bool get isOpen => _isOpen;

  @override
  int get vendorId => UsbConstants.vendorId;

  @override
  int get productId => UsbConstants.productId;

  @override
  String get productName => 'Ant Esports MK1300 V2 (Physical Mock)';

  @override
  Stream<Uint8List> get reportStream => const Stream.empty();

  @override
  Future<bool> open() async {
    _isOpen = true;
    return true;
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  Future<bool> writeReport(Uint8List payload) async {
    lastWrittenPayload = Uint8List.fromList(payload);
    return true;
  }

  @override
  Future<Uint8List?> readReport({int timeoutMs = 1000}) async {
    return Uint8List(64);
  }
}

void main() {
  group('PacketBuilder Key Remapping Serialization Tests', () {
    test('buildWriteSingleKeyPacket encodes correct 64-byte report format', () {
      // Test keyIndex 17 (W), layer 0, type 32 (Standard), code1 0, code2 82 (Up arrow), code3 0
      final packet = PacketBuilder.buildWriteSingleKeyPacket(
        keyIndex: 17,
        layer: 0,
        type: 32,
        code1: 0,
        code2: 82,
        code3: 0,
      );

      expect(packet.length, equals(64));
      expect(packet[0], equals(0x06)); // Root opcode
      expect(packet[1], equals(0x10)); // Subcommand 0x10 (Write single key)
      expect(packet[2], equals(0x07)); // Parameter length (7 bytes)

      // Little-endian byte offset = 4 * 17 = 68 (0x0044)
      expect(packet[3], equals(68));   // Offset low
      expect(packet[4], equals(0));    // Offset high
      expect(packet[5], equals(0x00)); // Reserved
      expect(packet[6], equals(0));    // Layer 0
      expect(packet[7], equals(0x00)); // Reserved

      // Key descriptor tuple [type, code1, code2, code3]
      expect(packet[8], equals(32));   // type
      expect(packet[9], equals(0));    // code1
      expect(packet[10], equals(82));  // code2
      expect(packet[11], equals(0));   // code3
    });

    test('buildWriteSingleKeyPacket encodes layer 1 correctly', () {
      // Test keyIndex 0 (Esc), layer 1, media key (type 48, code1 205 Play/Pause)
      final packet = PacketBuilder.buildWriteSingleKeyPacket(
        keyIndex: 0,
        layer: 1,
        type: 48,
        code1: 205,
        code2: 0,
        code3: 0,
      );

      expect(packet[1], equals(0x10));
      expect(packet[3], equals(0));
      expect(packet[4], equals(0));
      expect(packet[6], equals(1)); // Layer 1
      expect(packet[8], equals(48));
      expect(packet[9], equals(205));
    });

    test('buildReadKeymapChunkPacket encodes 58-byte chunk request', () {
      final packet = PacketBuilder.buildReadKeymapChunkPacket(112, 1);
      expect(packet.length, equals(64));
      expect(packet[0], equals(0x06));
      expect(packet[1], equals(0x08));
      expect(packet[2], equals(0x3A)); // 58 bytes
      expect(packet[3], equals(112));  // Offset low
      expect(packet[4], equals(0));    // Offset high
      expect(packet[6], equals(1));    // Layer 1
    });

    test('buildWriteKeymapChunkPacket encodes chunk write with length', () {
      final chunkData = List.generate(56, (i) => i);
      final packet = PacketBuilder.buildWriteKeymapChunkPacket(
        56,
        0,
        chunkData,
        false,
        244,
      );

      expect(packet.length, equals(64));
      expect(packet[0], equals(0x06));
      expect(packet[1], equals(0x09));
      expect(packet[2], equals(59));   // Standard lenParam
      expect(packet[3], equals(56));   // Offset low
      expect(packet[4], equals(0));    // Offset high
      expect(packet[6], equals(0));    // Layer 0
      expect(packet[8], equals(0));    // First data byte
      expect(packet[63], equals(55));  // 8 + 55 = 63
    });

    test('parseKeymapChunkResponse extracts 56-byte payload from valid report', () {
      final validReport = Uint8List(64);
      validReport[0] = 0x06;
      validReport[1] = 0x08;
      for (int i = 0; i < 56; i++) {
        validReport[8 + i] = i + 10;
      }

      final payload = PacketBuilder.parseKeymapChunkResponse(validReport);
      expect(payload, isNotNull);
      expect(payload!.length, equals(56));
      expect(payload[0], equals(10));
      expect(payload[55], equals(65));
    });

    test('parseKeymapChunkResponse rejects invalid reports', () {
      final shortReport = Uint8List(32);
      expect(PacketBuilder.parseKeymapChunkResponse(shortReport), isNull);

      final wrongOpcode = Uint8List(64);
      wrongOpcode[0] = 0x05;
      expect(PacketBuilder.parseKeymapChunkResponse(wrongOpcode), isNull);
    });
  });

  group('KeyMapping Model & Catalog Tests', () {
    test('KeyMapping.fromGeometry initializes Layer 0 correctly', () {
      const geo = KeyGeometry(
        row: 0,
        col: 0,
        x: 0,
        y: 0,
        w: 1,
        h: 1,
        index: 0,
        name: 'Esc',
        defaultCode: 41,
      );

      final mapping = KeyMapping.fromGeometry(geo, layer: 0);
      expect(mapping.keyIndex, equals(0));
      expect(mapping.defaultName, equals('Esc'));
      expect(mapping.defaultCode, equals(41));
      expect(mapping.newType, equals(32));
      expect(mapping.newCode2, equals(41));
      expect(mapping.newName, equals('Esc'));
      expect(mapping.isPendingChange, isFalse);
      expect(mapping.isModifiedFromDefault, isFalse);
    });

    test('KeyMapping.fromGeometry initializes Layer 1 Fn secondary defaults', () {
      const escGeo = KeyGeometry(row: 0, col: 0, x: 0, y: 0, w: 1, h: 1, index: 0, name: 'Esc', defaultCode: 41);
      const wGeo = KeyGeometry(row: 1, col: 2, x: 2.5, y: 1, w: 1, h: 1, index: 17, name: 'W', defaultCode: 26);
      const num1Geo = KeyGeometry(row: 0, col: 1, x: 1, y: 0, w: 1, h: 1, index: 1, name: '1', defaultCode: 30);

      final fnEsc = KeyMapping.fromGeometry(escGeo, layer: 1);
      final fnW = KeyMapping.fromGeometry(wGeo, layer: 1);
      final fn1 = KeyMapping.fromGeometry(num1Geo, layer: 1);

      expect(fnEsc.defaultName, equals('`'));
      expect(fnEsc.defaultCode, equals(53));
      expect(fnW.defaultName, equals('Up'));
      expect(fnW.defaultCode, equals(82));
      expect(fn1.defaultName, equals('F1'));
      expect(fn1.defaultCode, equals(58));
    });

    test('assignAction marks mapping as pending change', () {
      const geo = KeyGeometry(row: 1, col: 2, x: 2.5, y: 1, w: 1, h: 1, index: 17, name: 'W', defaultCode: 26);
      final mapping = KeyMapping.fromGeometry(geo);

      expect(mapping.isPendingChange, isFalse);

      final action = KeyCatalog.mediaActions.firstWhere((a) => a.code == 'KC_MPLY'); // Play/Pause
      mapping.assignAction(action);

      expect(mapping.isPendingChange, isTrue);
      expect(mapping.isModifiedFromDefault, isTrue);
      expect(mapping.newType, equals(action.type));
      expect(mapping.newCode1, equals(action.value1));
      expect(mapping.newName, equals(action.name));

      // Revert clears pending
      mapping.revertPending();
      expect(mapping.isPendingChange, isFalse);
      expect(mapping.newName, equals('W'));

      // Re-assign and confirm
      mapping.assignAction(action);
      mapping.confirmPending();
      expect(mapping.isPendingChange, isFalse);
      expect(mapping.confirmedName, equals(action.name));

      // Reset to default
      mapping.resetToDefault();
      expect(mapping.newName, equals('W'));
      expect(mapping.newCode2, equals(26));
    });

    test('KeyCatalog provides full action set and real-time search', () {
      expect(KeyCatalog.basicActions.isNotEmpty, isTrue);
      expect(KeyCatalog.mediaActions.isNotEmpty, isTrue);
      expect(KeyCatalog.mouseActions.isNotEmpty, isTrue);
      expect(KeyCatalog.shortcutActions.isNotEmpty, isTrue);
      expect(KeyCatalog.hardwareActions.isNotEmpty, isTrue);
      expect(KeyCatalog.macroActions.length, equals(16));

      // Search by name
      final playSearch = KeyCatalog.search('Play');
      expect(playSearch.any((a) => a.name.contains('Play')), isTrue);

      // Search by code
      final volSearch = KeyCatalog.search('VOLU');
      expect(volSearch.any((a) => a.code == 'KC_VOLU'), isTrue);

      // Search with category filter
      final macroSearch = KeyCatalog.search('M3', category: RemapCategory.macro);
      expect(macroSearch.length, equals(1));
      expect(macroSearch.first.name, equals('M3'));
    });
  });

  group('Mock HID Device Key Remap Simulation Tests', () {
    test('MockHidDevice handles CMD 0x10 single-key writes for Layer 0 and Layer 1', () async {
      final mock = MockHidDevice();
      await mock.open();

      // Write single key to Layer 0: keyIndex 17 (W) -> Up arrow (32, 0, 82, 0)
      final writePkt0 = PacketBuilder.buildWriteSingleKeyPacket(
        keyIndex: 17,
        layer: 0,
        type: 32,
        code1: 0,
        code2: 82,
        code3: 0,
      );
      final ok0 = await mock.writeReport(writePkt0);
      expect(ok0, isTrue);

      final desc0 = mock.getKeyDescriptor(0, 17);
      expect(desc0, equals([32, 0, 82, 0]));

      // Write single key to Layer 1: keyIndex 0 (Esc) -> Mute (48, 226, 0, 0)
      final writePkt1 = PacketBuilder.buildWriteSingleKeyPacket(
        keyIndex: 0,
        layer: 1,
        type: 48,
        code1: 226,
        code2: 0,
        code3: 0,
      );
      final ok1 = await mock.writeReport(writePkt1);
      expect(ok1, isTrue);

      final desc1 = mock.getKeyDescriptor(1, 0);
      expect(desc1, equals([48, 226, 0, 0]));

      await mock.close();
    });

    test('MockHidDevice handles CMD 0x09 chunk writes and reads back via CMD 0x08', () async {
      final mock = MockHidDevice();
      await mock.open();

      // Write 56 bytes to offset 0 in layer 0
      final chunkData = List.generate(56, (i) => i + 1);
      final writeChunkPkt = PacketBuilder.buildWriteKeymapChunkPacket(
        0,
        0,
        chunkData,
        false,
        244,
      );
      await mock.writeReport(writeChunkPkt);

      // Read back chunk 0
      final readReq = PacketBuilder.buildReadKeymapChunkPacket(0, 0);
      await mock.writeReport(readReq);
      final resp = await mock.readReport();

      expect(resp, isNotNull);
      final payload = PacketBuilder.parseKeymapChunkResponse(resp!);
      expect(payload, isNotNull);
      expect(payload![0], equals(1));
      expect(payload[1], equals(2));
      expect(payload[2], equals(3));
      expect(payload[3], equals(4));

      await mock.close();
    });
  });

  group('KeyboardService Safety Gating & Synchronization Tests', () {
    test('Safety gate blocks physical hardware writes when isHardwareWriteGated = true', () async {
      final fakePhysical = _FakePhysicalHidDevice();
      final service = KeyboardService(customDevice: fakePhysical);
      await service.connect();

      expect(service.isUsingMock, isFalse);
      expect(service.isHardwareWriteGated, isTrue);

      // Attempt single key write on physical keyboard
      service.assignKeyRemap(
        17,
        type: 32,
        code1: 0,
        code2: 82,
        code3: 0,
        newName: 'Up',
      );
      expect(service.hasPendingRemaps, isTrue);

      final applied = await service.applyKeyRemap(17);
      expect(applied, isFalse);
      expect(service.lastSyncError, contains('gated'));
      expect(service.hasPendingRemaps, isTrue); // Remains pending

      // Attempt all pending apply
      final allApplied = await service.applyAllPendingRemaps();
      expect(allApplied, isFalse);
      expect(service.lastSyncError, contains('gated'));

      await service.disconnect();
    });

    test('Simulated mock device allows applyAllPendingRemaps and confirms state', () async {
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      expect(service.isUsingMock, isTrue);

      // Remap 2 keys in Layer 0 locally
      final idx16 = service.currentKeys.indexWhere((k) => k.keyIndex == 16);
      final idx17 = service.currentKeys.indexWhere((k) => k.keyIndex == 17);
      service.assignKeyRemap(idx16, type: 32, code1: 0, code2: 58, code3: 0, newName: 'F1');
      service.assignKeyRemap(idx17, type: 32, code1: 0, code2: 59, code3: 0, newName: 'F2');

      expect(service.pendingRemapCount, equals(2));
      expect(service.hasPendingRemaps, isTrue);

      // Apply to mock hardware
      final success = await service.applyAllPendingRemaps();
      expect(success, isTrue);
      expect(service.hasPendingRemaps, isFalse);
      expect(service.pendingRemapCount, equals(0));

      // Verify mock hardware received changes
      expect(mock.getKeyDescriptor(0, 16), equals([32, 0, 58, 0]));
      expect(mock.getKeyDescriptor(0, 17), equals([32, 0, 59, 0]));

      await service.disconnect();
    });

    test('Layer switching toggles active layer and retains per-layer mappings', () async {
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      expect(service.activeLayer, equals(0));
      service.setActiveLayer(1);
      expect(service.activeLayer, equals(1));

      // Key 17 in Layer 1 defaults to 'Up'
      final layer1Key17 = service.currentKeys.firstWhere((k) => k.keyIndex == 17);
      expect(layer1Key17.defaultName, equals('Up'));

      service.setActiveLayer(0);
      final layer0Key17 = service.currentKeys.firstWhere((k) => k.keyIndex == 17);
      expect(layer0Key17.defaultName, equals('W'));

      await service.disconnect();
    });
  });

  group('KeyRemappingPage Widget Tests', () {
    testWidgets('Renders layer selector, key visualizer, and inspector card', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyRemappingPage(
              keyboardService: service,
              geometries: _testGeometries,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify Layer Switcher
      expect(find.text('Main Layer (0)'), findsOneWidget);
      expect(find.text('Fn Layer (1)'), findsOneWidget);

      // Verify Keyboard Visualizer presence
      expect(find.byType(KeyboardVisualizer), findsOneWidget);

      // Verify Initial Status is "Hardware In Sync"
      expect(find.text('Hardware In Sync'), findsOneWidget);

      // Verify Category Tabs
      expect(find.widgetWithText(Tab, 'Basic Keys'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Media Controls'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Mouse Actions'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Shortcuts & System'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Hardware Controls'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Macros'), findsOneWidget);
    });

    testWidgets('Tapping action in catalog assigns to selected key and shows Pending badge', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyRemappingPage(
              keyboardService: service,
              geometries: _testGeometries,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Select key 'W'
      final wIdx = service.currentKeys.indexWhere((k) => k.defaultName == 'W');
      service.selectKey(wIdx);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Physical Key: W'), findsOneWidget);

      // Tap on 'Media Controls' tab
      await tester.tap(find.widgetWithText(Tab, 'Media Controls'));
      await tester.pumpAndSettle();

      // Tap 'Play/Pause' action chip
      final playChip = find.text('Play/Pause');
      expect(playChip, findsOneWidget);
      await tester.tap(playChip);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify pending change detected
      expect(service.hasPendingRemaps, isTrue);
      expect(find.text('1 Pending'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);

      // Tap Apply to Device button
      final applyBtn = find.text('Apply to Device');
      await tester.tap(applyBtn);
      await tester.pump(const Duration(seconds: 1));

      // Status returns to "Hardware In Sync"
      expect(service.hasPendingRemaps, isFalse);
      expect(find.text('Hardware In Sync'), findsOneWidget);
    });

    testWidgets('Search query filters action items in real-time', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyRemappingPage(
              keyboardService: service,
              geometries: _testGeometries,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Enter search query 'Calculator'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Calculator');
      await tester.pump(const Duration(milliseconds: 500));

      // Search results show 'Calculator' action card
      expect(find.widgetWithText(InkWell, 'Calculator'), findsOneWidget);

      // Clear search
      final clearBtn = find.byIcon(Icons.clear);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.widgetWithText(Tab, 'Basic Keys'), findsOneWidget);
    });
  });
}
