import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk1300_v2/features/dashboard/presentation/dashboard_page.dart';
import 'package:mk1300_v2/features/key_remapping/models/key_geometry.dart';
import 'package:mk1300_v2/features/key_remapping/presentation/keyboard_visualizer.dart';
import 'package:mk1300_v2/hardware/hid/mock_hid_device.dart';
import 'package:mk1300_v2/hardware/services/keyboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Keyboard Layout JSON & Geometry Parsing Tests', () {
    test('Parses recovered layout JSON correctly', () {
      final jsonFile = File('assets/data/36ae_fe12.json');
      expect(jsonFile.existsSync(), isTrue);

      final jsonContent = jsonFile.readAsStringSync();
      final keys = KeyGeometry.parseLayout(jsonContent);

      // Must have exactly 61 active physical keys
      expect(keys.length, equals(61));

      // Validate key 0 is Esc
      expect(keys[0].index, equals(0));
      expect(keys[0].name, equals('Esc'));
      expect(keys[0].w, equals(1.0));
      expect(keys[0].h, equals(1.0));

      // Validate special keys dimensions
      final backspace = keys.firstWhere((k) => k.index == 13);
      expect(backspace.name, equals('Back'));
      expect(backspace.w, equals(2.0));

      final tab = keys.firstWhere((k) => k.index == 15);
      expect(tab.name, equals('Tab'));
      expect(tab.w, equals(1.5));

      final caps = keys.firstWhere((k) => k.index == 30);
      expect(caps.name, equals('Caps'));
      expect(caps.w, equals(1.75));

      final enter = keys.firstWhere((k) => k.index == 43);
      expect(enter.name, equals('Enter'));
      expect(enter.w, equals(2.25));

      final leftShift = keys.firstWhere((k) => k.index == 45);
      expect(leftShift.name, equals('Shift'));
      expect(leftShift.w, equals(2.25));

      final rightShift = keys.firstWhere((k) => k.index == 58);
      expect(rightShift.name, equals('Shift'));
      expect(rightShift.w, equals(2.75));

      final space = keys.firstWhere((k) => k.index == 66);
      expect(space.name, equals('Space'));
      expect(space.w, equals(6.25));
    });

    test('Gracefully falls back to fallbackLayout61 on invalid JSON', () {
      final badResult = KeyGeometry.parseLayout('{"layouts": {"keys": []}}');
      expect(badResult.length, equals(61));

      final malformedResult = KeyGeometry.parseLayout('not a json');
      expect(malformedResult.length, equals(61));
    });
  });

  group('Keyboard Visualizer Widget Tests', () {
    testWidgets('Renders all 61 keys and responds to taps', (tester) async {
      final service = KeyboardService(customDevice: MockHidDevice());
      await service.connect(forceMock: true);

      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: KeyboardVisualizer(
                keys: service.currentKeys,
                selectedIndex: service.selectedKeyIndex,
                onKeySelected: (idx) {
                  tappedIndex = idx;
                  service.selectKey(idx);
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Esc key and click it
      final escFinder = find.text('Esc');
      expect(escFinder, findsOneWidget);

      await tester.tap(escFinder);
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(0));
      expect(service.selectedKeyIndex, equals(0));
    });
  });

  group('Dashboard Page Widget Tests', () {
    testWidgets('Renders dashboard status cards and simulated indicator', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = KeyboardService(customDevice: MockHidDevice());
      await service.connect(forceMock: true);

      int navigatedTab = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              height: 900,
              child: DashboardPage(
                keyboardService: service,
                onNavigateTab: (tab) => navigatedTab = tab,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dashboard headers & status
      expect(find.text('Ant Esports MK1300 V2'), findsOneWidget);
      expect(find.text('Interactive 61-Key Keyboard Visualizer'), findsOneWidget);
      expect(find.text('Simulated Device Mode Active: Physical keyboard is not connected. All visualizer, lighting, and macro features are fully functional in simulation.'), findsOneWidget);
      expect(find.text('SIMULATOR'), findsOneWidget);

      // Test navigation buttons
      final lightingBtn = find.text('Lighting Studio');
      expect(lightingBtn, findsOneWidget);
      await tester.tap(lightingBtn);
      await tester.pumpAndSettle();

      expect(navigatedTab, equals(1));
    });
  });
}
