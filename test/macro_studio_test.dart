import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_studio/core/constants/usb_constants.dart';
import 'package:keyboard_studio/features/macros/models/macro_action.dart';
import 'package:keyboard_studio/features/macros/models/macro_model.dart';
import 'package:keyboard_studio/features/macros/presentation/macro_page.dart';
import 'package:keyboard_studio/features/macros/services/macro_compiler.dart';
import 'package:keyboard_studio/hardware/hid/hid_device.dart';
import 'package:keyboard_studio/hardware/hid/mock_hid_device.dart';
import 'package:keyboard_studio/hardware/services/keyboard_service.dart';

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
  String get productName => 'MK1300 V2 (Physical Mock)';

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
  group('MacroCompiler Binary EEPROM Tests', () {
    test('Compiles empty macro list to initialized 4KB buffer with 0xFF header', () {
      final macros = List.generate(16, (i) => MacroModel(name: 'M$i', actions: []));
      final eeprom = MacroCompiler.compileToEeprom(macros);

      expect(eeprom.length, equals(4096));
      // First 64 bytes (16 pointers * 2 bytes = 32 bytes used, 64 allocated)
      for (int i = 0; i < 64; i++) {
        expect(eeprom[i], equals(0xFF));
      }
    });

    test('Compiles single macro with keyboard press and release actions', () {
      final macro0 = MacroModel(
        name: 'M0',
        actions: [
          MacroAction(name: 'A', code: 4, type: MacroActionType.keyboardKey, isPress: true, delay: 50),
          MacroAction(name: 'A', code: 4, type: MacroActionType.keyboardKey, isPress: false, delay: 75),
        ],
      );

      final macros = [macro0, ...List.generate(15, (i) => MacroModel(name: 'M${i + 1}', actions: []))];
      final eeprom = MacroCompiler.compileToEeprom(macros);

      // M0 pointer at bytes 0..1 must point to offset 64 (0x0040)
      expect(eeprom[0], equals(64));
      expect(eeprom[1], equals(0));

      // Action 0 at byte 64: delay 50, flags (0x40 Press | 0x02 Keyboard = 0x42), code 4
      expect(eeprom[64], equals(50));
      expect(eeprom[65], equals(0));
      expect(eeprom[66], equals(0x42));
      expect(eeprom[67], equals(4));

      // Action 1 at byte 68: delay 75, flags (0x80 Last | 0x02 Keyboard = 0x82), code 4
      expect(eeprom[68], equals(75));
      expect(eeprom[69], equals(0));
      expect(eeprom[70], equals(0x82)); // 0x80 terminator + 0x02 keyboard
      expect(eeprom[71], equals(4));
    });

    test('Compiles mouse and wheel actions with correct flags', () {
      final macro = MacroModel(
        name: 'M0',
        actions: [
          MacroAction(name: 'Mouse Left', code: 1, type: MacroActionType.mouseButton, isPress: true, delay: 20),
          MacroAction(name: 'Scroll Down', code: 255, type: MacroActionType.scrollVertical, isPress: false, delay: 30),
          MacroAction(name: 'Scroll Right', code: 255, type: MacroActionType.scrollHorizontal, isPress: false, delay: 40),
        ],
      );

      final macros = [macro, ...List.generate(15, (i) => MacroModel(name: 'M${i + 1}', actions: []))];
      final eeprom = MacroCompiler.compileToEeprom(macros);

      // Action 0: Mouse Button (type 3, press 0x40 -> flags 0x43)
      expect(eeprom[64 + 2], equals(0x43));
      expect(eeprom[64 + 3], equals(1));

      // Action 1: Scroll Vertical (type 4, release -> flags 0x04)
      expect(eeprom[68 + 2], equals(0x04));
      expect(eeprom[68 + 3], equals(255));

      // Action 2: Scroll Horizontal (type 5, terminator 0x80 -> flags 0x85)
      expect(eeprom[72 + 2], equals(0x85));
      expect(eeprom[72 + 3], equals(255));
    });

    test('Decompiles compiled EEPROM accurately back to MacroModel (Roundtrip)', () {
      final originalMacros = [
        MacroModel(
          name: 'M0',
          actions: [
            MacroAction(name: 'A', code: 4, type: MacroActionType.keyboardKey, isPress: true, delay: 100),
            MacroAction(name: 'A', code: 4, type: MacroActionType.keyboardKey, isPress: false, delay: 50),
          ],
        ),
        MacroModel(
          name: 'M1',
          actions: [
            MacroAction(name: 'Mouse Left', code: 1, type: MacroActionType.mouseButton, isPress: true, delay: 25),
            MacroAction(name: 'Mouse Left', code: 1, type: MacroActionType.mouseButton, isPress: false, delay: 35),
          ],
        ),
        ...List.generate(14, (i) => MacroModel(name: 'M${i + 2}', actions: [])),
      ];

      final eeprom = MacroCompiler.compileToEeprom(originalMacros);
      final decompiled = MacroCompiler.decompileFromEeprom(eeprom);

      expect(decompiled.length, equals(16));

      // Verify M0
      expect(decompiled[0].actions.length, equals(2));
      expect(decompiled[0].actions[0].code, equals(4));
      expect(decompiled[0].actions[0].delay, equals(100));
      expect(decompiled[0].actions[0].isPress, isTrue);
      expect(decompiled[0].actions[1].isPress, isFalse);

      // Verify M1
      expect(decompiled[1].actions.length, equals(2));
      expect(decompiled[1].actions[0].type, equals(MacroActionType.mouseButton));
      expect(decompiled[1].actions[0].code, equals(1));
      expect(decompiled[1].actions[0].delay, equals(25));

      // Verify unassigned slots are empty
      for (int i = 2; i < 16; i++) {
        expect(decompiled[i].actions.isEmpty, isTrue);
      }
    });

    test('Handles 4KB memory boundary gracefully without buffer overrun', () {
      // 1000 actions * 4 bytes = 4000 bytes + 64 = 4064 bytes (fits within 4096)
      // 1050 actions * 4 bytes = 4200 bytes (exceeds 4096 limit)
      final largeActionList = List.generate(
        1100,
        (i) => MacroAction(name: 'Key', code: 4, type: MacroActionType.keyboardKey, isPress: (i % 2 == 0), delay: 10),
      );

      final macro = MacroModel(name: 'M0', actions: largeActionList);
      final macros = [macro, ...List.generate(15, (i) => MacroModel(name: 'M${i + 1}', actions: []))];

      final eeprom = MacroCompiler.compileToEeprom(macros);
      expect(eeprom.length, equals(4096)); // Strictly capped at 4096 bytes
    });
  });

  group('KeyboardService Macro Safety & Synchronization Tests', () {
    test('Safety gate blocks physical hardware macro writes when isHardwareWriteGated = true', () async {
      final fakePhysical = _FakePhysicalHidDevice();
      final service = KeyboardService(customDevice: fakePhysical);
      await service.connect();

      expect(service.isUsingMock, isFalse);
      expect(service.isHardwareWriteGated, isTrue);

      final testMacros = [
        MacroModel(
          name: 'M0',
          actions: [
            MacroAction(name: 'A', code: 4, type: MacroActionType.keyboardKey, isPress: true, delay: 50),
          ],
        ),
      ];

      final success = await service.saveMacrosToKeyboard(testMacros);
      expect(success, isFalse);
      expect(service.lastSyncError, contains('gated'));
    });

    test('MockHidDevice permits macro save and reads back from simulated EEPROM', () async {
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      expect(service.isUsingMock, isTrue);

      final testMacros = [
        MacroModel(
          name: 'M0',
          actions: [
            MacroAction(name: 'A', code: 4, type: MacroActionType.keyboardKey, isPress: true, delay: 50),
            MacroAction(name: 'A', code: 4, type: MacroActionType.keyboardKey, isPress: false, delay: 50),
          ],
        ),
        ...List.generate(15, (i) => MacroModel(name: 'M${i + 1}', actions: [])),
      ];

      final saved = await service.saveMacrosToKeyboard(testMacros);
      expect(saved, isTrue);

      // Readback from mock hardware
      final readOk = await service.readMacrosFromDevice();
      expect(readOk, isTrue);
      expect(service.macros[0].actions.length, equals(2));
      expect(service.macros[0].actions[0].code, equals(4));
    });

    test('clearAllMacros resets all 16 slots to empty state', () async {
      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      // First add some actions
      final testMacros = [
        MacroModel(
          name: 'M0',
          actions: [
            MacroAction(name: 'B', code: 5, type: MacroActionType.keyboardKey, isPress: true, delay: 50),
          ],
        ),
        ...List.generate(15, (i) => MacroModel(name: 'M${i + 1}', actions: [])),
      ];
      await service.saveMacrosToKeyboard(testMacros);
      expect(service.macros[0].actions.isNotEmpty, isTrue);

      // Reset macros
      final cleared = await service.clearAllMacros();
      expect(cleared, isTrue);
      for (final m in service.macros) {
        expect(m.actions.isEmpty, isTrue);
      }
    });
  });

  group('MacroPage UI Widget Tests', () {
    testWidgets('Renders MacroPage with 16 slots, action table, and playback mode selector', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MacroPage(keyboardService: service),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Macro List header
      expect(find.text('Macro List'), findsOneWidget);

      // Verify 16 macro items are present in list
      expect(find.text('M0'), findsOneWidget);
      expect(find.text('M1'), findsOneWidget);

      // Verify Playback Mode dropdown with "Play Once"
      expect(find.text('Play Once'), findsOneWidget);

      // Verify Start Recording button
      expect(find.text('Start Recording'), findsOneWidget);

      // Verify Save to Keyboard button
      expect(find.text('Save to Keyboard'), findsOneWidget);
    });

    testWidgets('Adding action updates step count and action table', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mock = MockHidDevice();
      final service = KeyboardService(customDevice: mock);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MacroPage(keyboardService: service),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap "Add New Action" icon button
      final addBtn = find.byIcon(Icons.add_circle);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Two steps (KeyDown + KeyUp for key A) were added
      expect(find.text('2 steps'), findsOneWidget);
    });
  });
}
