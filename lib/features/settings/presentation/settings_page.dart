import 'package:flutter/material.dart';
import '../../../app/theme/theme.dart';
import '../../../hardware/services/keyboard_service.dart';

class SettingsPage extends StatefulWidget {
  final KeyboardService keyboardService;

  const SettingsPage({super.key, required this.keyboardService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.keyboardService;
    final config = service.config;
    final currentSleep = config?.autoSleepTime ?? 300;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildPowerManagementCard(service, currentSleep),
                    const SizedBox(height: 20),
                    _buildDeviceInformationCard(config),
                    const SizedBox(height: 20),
                    _buildDangerZoneCard(service),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildConnectionDiagnosticsCard(service),
                    const SizedBox(height: 20),
                    _buildSoftwareInfoCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DEVICE SETTINGS & PREFERENCES',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure keyboard hardware parameters, power saving, diagnostics, and factory restoration.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPowerManagementCard(KeyboardService service, int currentSleep) {
    final sleepOptions = [
      {'label': 'Never (Always On)', 'value': 0},
      {'label': '2 Minutes (120s)', 'value': 120},
      {'label': '5 Minutes (300s)', 'value': 300},
      {'label': '10 Minutes (600s)', 'value': 600},
      {'label': '30 Minutes (1800s)', 'value': 1800},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.power_settings_new, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Power Saving & Inactivity Timeout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sets the inactivity threshold after which keyboard backlighting automatically dims or sleeps to conserve battery.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: sleepOptions.map((opt) {
                final val = opt['value'] as int;
                final isSelected = currentSleep == val;
                return ChoiceChip(
                  label: Text(opt['label'] as String),
                  selected: isSelected,
                  selectedColor: AppTheme.accentCyan.withValues(alpha: 0.25),
                  backgroundColor: AppTheme.surfaceLight,
                  side: BorderSide(
                    color: isSelected ? AppTheme.accentCyan : AppTheme.panelBorder,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      service.setAutoSleepTime(val);
                      setState(() {});
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInformationCard(dynamic config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Hardware & Controller Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device Name', 'Ant Esports MK1300 V2 ARGB'),
            _buildInfoRow('Microcontroller', 'Vision 9520 (High-Speed USB HID)'),
            _buildInfoRow('Vendor ID (VID)', '0x36AE (13998)'),
            _buildInfoRow('Product ID (PID)', '0xFE12 (65042)'),
            _buildInfoRow('HID Usage Page / Usage', '0xFF00 / 0x0002 (Vendor Defined)'),
            _buildInfoRow('Firmware Version', config != null ? 'v${config.firmwareVersionMajor}.${config.firmwareVersionMinor}' : 'v1.0 (Vision)'),
            _buildInfoRow('Active Profile', config != null ? 'Profile ${config.currentProfile + 1} of 3' : 'Profile 1'),
            _buildInfoRow('Active Layer', config != null ? (config.activeLayer == 1 ? 'Fn Layer' : 'Main Layer') : 'Main Layer'),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard(KeyboardService service) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.accentRed.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Factory Reset & Memory Clearing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentRed),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Restores factory lighting patterns, clears all customized key remaps across profiles, and re-initializes macro memory on the keyboard EEPROM.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _isResetting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.restore, size: 18),
              label: Text(_isResetting ? 'Resetting Device...' : 'Restore Factory Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
              ),
              onPressed: _isResetting
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Factory Reset'),
                          content: const Text(
                            'Are you sure you want to restore the MK1300 V2 keyboard to factory default settings? All custom lighting, macros, and key remaps will be reset.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Reset Everything'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        setState(() => _isResetting = true);
                        try {
                          await service.restoreFactoryDefaults();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Keyboard restored to factory defaults!')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isResetting = false);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDiagnosticsCard(KeyboardService service) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cable, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Interface Diagnostics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('HID Connection', service.isConnected ? 'Connected & Verified' : 'Disconnected / Emulation'),
            _buildInfoRow('Device Mode', service.device.productName),
            _buildInfoRow('Driver Engine', 'hidapi C-FFI / Native IO'),
            _buildInfoRow('Report Framing', '64 Bytes Fixed LE Payload'),
            _buildInfoRow('Control Endpoint', 'Interface 1, Endpoint 0x01'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reconnect / Rescan Bus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceLight,
                foregroundColor: AppTheme.accentCyan,
              ),
              onPressed: () async {
                await service.connect();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftwareInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.laptop_chromebook, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Application Architecture',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Application', 'Ant Esports MK1300 V2 Desktop'),
            _buildInfoRow('Framework', 'Flutter Desktop (Dart 3.x)'),
            _buildInfoRow('Reconstruction', 'Clean-room native reverse engineering'),
            _buildInfoRow('Original Stack', 'Electron + Next.js + WebHID (Retired)'),
            _buildInfoRow('License / Status', 'Antigravity Verified Native Build'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
