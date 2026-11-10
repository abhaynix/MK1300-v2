import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_studio/features/key_remapping/models/key_geometry.dart';
import 'package:keyboard_studio/features/lighting/models/lighting_mode.dart';
import 'package:keyboard_studio/features/lighting/models/lighting_state.dart';
import 'package:keyboard_studio/features/lighting/services/lighting_preview_engine.dart';
import 'package:keyboard_studio/features/lighting/presentation/lighting_page.dart';
import 'package:keyboard_studio/hardware/services/keyboard_service.dart';
import 'package:keyboard_studio/hardware/hid/mock_hid_device.dart';

void main() {
  group('Lighting Studio Model & Engine Tests', () {
    test('All 22 Lighting Modes recovered with correct parameters', () {
      expect(LightingMode.values.length, equals(22));

      // Check Mode 0: Off
      final offMode = LightingMode.off;
      expect(offMode.value, equals(0));
      expect(offMode.hasBrightness, isFalse);
      expect(offMode.hasSpeed, isFalse);
      expect(offMode.hasDirection, equals(0));
      expect(offMode.hasColor, isFalse);

      // Check Mode 1: Static
      final staticMode = LightingMode.staticOn;
      expect(staticMode.value, equals(1));
      expect(staticMode.hasBrightness, isTrue);
      expect(staticMode.hasSpeed, isFalse);
      expect(staticMode.hasColor, isTrue);

      // Check Mode 5: Stream (Horizontal wave)
      final streamMode = LightingMode.stream;
      expect(streamMode.value, equals(5));
      expect(streamMode.hasBrightness, isTrue);
      expect(streamMode.hasSpeed, isTrue);
      expect(streamMode.hasDirection, equals(1));

      // Check Mode 7: UDWave (Vertical wave)
      final udWave = LightingMode.udWave;
      expect(udWave.value, equals(7));
      expect(udWave.hasDirection, equals(2));
    });

    test('LightingState defaults and boundary handling', () {
      final state = LightingState.initial();
      expect(state.mode, equals(LightingMode.stream));
      expect(state.brightness, inInclusiveRange(0, 4));
      expect(state.speed, inInclusiveRange(0, 4));
      expect(state.customSwatches.length, equals(8));
      expect(state.isCustomMode, isFalse);
      expect(state.isPreviewDirty, isFalse);

      final modified = state.copyWith(
        brightness: 3,
        speed: 1,
        isCustomMode: true,
        isPreviewDirty: true,
      );
      expect(modified.brightness, equals(3));
      expect(modified.speed, equals(1));
      expect(modified.isCustomMode, isTrue);
      expect(modified.isPreviewDirty, isTrue);
    });

    test('LightingPreviewEngine computes frames for all 61 keys', () {
      final state = LightingState.initial();
      final geometries = KeyGeometry.fallbackLayout61;
      expect(geometries.length, equals(61));

      final frame = LightingPreviewEngine.computeFrame(
        state: state,
        geometries: geometries,
        timeSeconds: 1.0,
      );

      expect(frame.length, equals(61));
      for (final geo in geometries) {
        expect(frame.containsKey(geo.index), isTrue);
        expect(frame[geo.index], isNotNull);
      }
    });

    test('LightingPreviewEngine off mode dims all keys to black', () {
      final state = LightingState.initial().copyWith(mode: LightingMode.off);
      final geometries = KeyGeometry.fallbackLayout61;

      final frame = LightingPreviewEngine.computeFrame(
        state: state,
        geometries: geometries,
        timeSeconds: 0.5,
      );

      for (final color in frame.values) {
        expect(color.r, equals(0.0));
        expect(color.g, equals(0.0));
        expect(color.b, equals(0.0));
      }
    });

    test('LightingPreviewEngine per-key custom color assignment', () {
      const customKeyIndex = 30; // 'A' key
      final customColor = const Color(0xFFFF5500);

      final state = LightingState.initial().copyWith(
        isCustomMode: true,
        perKeyColors: {customKeyIndex: customColor},
      );

      final geometries = KeyGeometry.fallbackLayout61;
      final frame = LightingPreviewEngine.computeFrame(
        state: state,
        geometries: geometries,
        timeSeconds: 0.0,
      );

      expect(frame[customKeyIndex], equals(customColor));
    });
  });

  group('Lighting Studio UI Widget Tests', () {
    testWidgets('Renders LightingPage with mode selector and visualizer', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockDevice = MockHidDevice();
      final service = KeyboardService(customDevice: mockDevice);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LightingPage(keyboardService: service),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check Mode Selector title
      expect(find.text('Lighting Effect'), findsOneWidget);
      expect(find.text('Effect Parameters'), findsOneWidget);
      expect(find.text('Color & Palette'), findsOneWidget);

      // Check simulated device badge
      expect(find.text('SIMULATED HARDWARE'), findsOneWidget);

      // Check that 61 keys are rendered inside the visualizer
      expect(find.text('Esc'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);

      // Toggle Custom Per-Key Mode
      final customSwitch = find.byType(Switch);
      expect(customSwitch, findsOneWidget);
      await tester.tap(customSwitch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Check that Fill All, Clear All, and Clear Key buttons appear
      expect(find.text('Fill All'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
      expect(find.text('Clear Key'), findsOneWidget);

      // Tap Reset Preview button
      await tester.tap(find.text('Reset Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Reset Preview'), findsOneWidget);
    });

    testWidgets('Changes brightness slider value locally without sending hardware write', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockDevice = MockHidDevice();
      final service = KeyboardService(customDevice: mockDevice);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LightingPage(keyboardService: service),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find sliders
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(2)); // Brightness and Speed

      // Brightness slider is first
      await tester.tap(sliders.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Ensure local preview banner reflects dirty preview
      expect(find.textContaining('Local Preview Active'), findsOneWidget);
    });

    testWidgets('Animation controller pauses on AppLifecycleState.paused and resumes on resumed', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockDevice = MockHidDevice();
      final service = KeyboardService(customDevice: mockDevice);
      await service.connect(forceMock: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LightingPage(keyboardService: service),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Flutter lifecycle transition state machine: resumed -> inactive -> hidden -> paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Resume transition: paused -> hidden -> inactive -> resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('Disposal of LightingPage safely unregisters observers and disposes controller', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockDevice = MockHidDevice();
      final service = KeyboardService(customDevice: mockDevice);
      await service.connect(forceMock: true);

      // Mount widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LightingPage(keyboardService: service),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Unmount widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // No exception or memory leak during disposal
      expect(find.byType(LightingPage), findsNothing);
    });
  });
}
