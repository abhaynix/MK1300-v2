// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:keyboard_studio/hardware/hid/linux_hid_device.dart';
import 'package:keyboard_studio/hardware/protocol/command_queue.dart';
import 'package:keyboard_studio/hardware/protocol/packet_builder.dart';

void main() {
  test('Physical Keyboard In-Vivo Communication & Lighting Query', () async {
    print('\n======================================================');
    print('PHYSICAL KEYBOARD HARDWARE VERIFICATION & TELEMETRY');
    print('======================================================');

    final devices = LinuxHidDevice.enumerateDevices();
    if (devices.isEmpty) {
      print('Physical MK1300 V2 not connected - skipping in-vivo test.');
      return;
    }

    final controlDevice = devices.first;
    print('Using Primary Control Device: ${controlDevice.devicePath}');
    final opened = await controlDevice.open();
    if (!opened) {
      print('Could not open device handle - skipping in-vivo test.');
      return;
    }

    try {
      final queue = CommandQueue(controlDevice);
      
      // 1. Get Device Configuration
      print('\n[TX] CMD 0x06, 0x05 (Get Device Configuration)...');
      final reqCfg = PacketBuilder.buildGetConfigPacket();
      final respCfg = await queue.writeAndReadCommand(reqCfg, timeoutMs: 2000);
      expect(respCfg, isNotNull);
      
      final cfg = PacketBuilder.parseConfigResponse(respCfg!);
      print('Config parsed: Firmware v${cfg?.firmwareVersion}, Battery ${cfg?.battery}%, Profile ${cfg?.currentProfile}');

      // 2. Query Lighting Configuration (CMD 0x06, 0x0A)
      print('\n[TX] CMD 0x06, 0x0A (Query Lighting State)...');
      final reqLight = PacketBuilder.buildGetLightingPacket();
      final respLight = await queue.writeAndReadCommand(reqLight, timeoutMs: 2000);
      print('[RX] Lighting Response received: ${respLight != null ? "${respLight.length} bytes" : "null"}');
      if (respLight != null) {
        final hexDump = respLight.take(24).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        print('Lighting Hex (first 24 bytes): $hexDump');
        final lightCfg = PacketBuilder.parseLightingResponse(respLight);
        if (lightCfg != null) {
          print('\n*** CURRENT HARDWARE LIGHTING STATE ***');
          print('Effect Mode: ${lightCfg.mode.value} (${lightCfg.mode.label})');
          print('Brightness:  ${lightCfg.brightness} / 4');
          print('Speed:       ${lightCfg.speed} / 4');
          print('Direction:   ${lightCfg.direction}');
          print('Color Mode:  ${lightCfg.colorMode}');
          print('HSV:         (H: ${lightCfg.hue.toStringAsFixed(1)}°, S: ${lightCfg.saturation.toStringAsFixed(1)}%, V: ${lightCfg.value.toStringAsFixed(1)}%)');
          print('Color:       ${lightCfg.color}');
          print('**************************************\n');
        }
      }
    } finally {
      await controlDevice.close();
    }
  });
}
