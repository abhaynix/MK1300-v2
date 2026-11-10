import 'package:flutter/material.dart';
import '../../../app/theme/theme.dart';
import '../../../hardware/hid/device_connection_state.dart';
import '../../../hardware/services/keyboard_service.dart';
import '../../key_remapping/presentation/keyboard_visualizer.dart';

class DashboardPage extends StatelessWidget {
  final KeyboardService keyboardService;
  final ValueChanged<int> onNavigateTab;

  const DashboardPage({
    super.key,
    required this.keyboardService,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final service = keyboardService;
    final cfg = service.config;
    final state = service.connectionState;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner for simulated device or error state
          if (service.isUsingMock || state != DeviceConnectionState.connected)
            _buildNotificationBanner(context, service),

          // Top Status Cards
          Row(
            children: [
              // Device Status Card
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.keyboard,
                  title: 'Ant Esports MK1300 V2',
                  subtitle: service.isUsingMock
                      ? 'Simulated Device (Offline)'
                      : (service.isConnected ? 'Physical Keyboard (USB)' : 'Disconnected'),
                  badgeColor: service.isConnected
                      ? (service.isUsingMock ? AppTheme.accentCyan : AppTheme.accentGreen)
                      : AppTheme.accentRed,
                  badgeText: service.isUsingMock ? 'SIMULATOR' : (service.isConnected ? 'ONLINE' : 'OFFLINE'),
                ),
              ),
              const SizedBox(width: 16),
              // Battery & Power Card
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.battery_charging_full,
                  title: 'Battery & Power',
                  subtitle: '${cfg?.battery ?? 92}% (USB Powered)',
                  badgeColor: AppTheme.accentCyan,
                  badgeText: '${cfg?.battery ?? 92}%',
                ),
              ),
              const SizedBox(width: 16),
              // Firmware & Controller Card
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.memory,
                  title: 'Vision 9520 MCU',
                  subtitle: 'Firmware v${cfg?.firmwareVersion ?? 102} (61K ARGB)',
                  badgeColor: AppTheme.accentPurple,
                  badgeText: 'VISION',
                ),
              ),
              const SizedBox(width: 16),
              // Active Profile Card
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.layers,
                  title: 'Active Profile',
                  subtitle: 'Profile ${(cfg?.currentProfile ?? 0) + 1} (${service.activeLayer == 0 ? "Main" : "Fn"} Layer)',
                  badgeColor: Colors.orangeAccent,
                  badgeText: 'P${(cfg?.currentProfile ?? 0) + 1}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Center: Interactive Visualizer
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.panelBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Interactive 61-Key Keyboard Visualizer',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.panelBorder),
                            ),
                            child: Text(
                              'ANSI 60% • 61 Keys',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.palette_outlined, size: 14),
                            label: const Text('Lighting Studio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentCyan,
                              side: const BorderSide(color: AppTheme.panelBorder),
                            ),
                            onPressed: () => onNavigateTab(1),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.tune, size: 14),
                            label: const Text('Key Remapping'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentCyan,
                              side: const BorderSide(color: AppTheme.panelBorder),
                            ),
                            onPressed: () => onNavigateTab(2),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.smart_toy_outlined, size: 14),
                            label: const Text('Macro Studio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentCyan,
                              side: const BorderSide(color: AppTheme.panelBorder),
                            ),
                            onPressed: () => onNavigateTab(3),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: KeyboardVisualizer(
                      keys: service.currentKeys,
                      selectedIndex: service.selectedKeyIndex,
                      onKeySelected: service.selectKey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner(BuildContext context, KeyboardService service) {
    final isMock = service.isUsingMock;
    final isDenied = service.connectionState == DeviceConnectionState.permissionDenied;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDenied
            ? AppTheme.accentRed.withValues(alpha: 0.15)
            : AppTheme.accentCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDenied ? AppTheme.accentRed : AppTheme.accentCyan,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDenied ? Icons.gpp_bad_outlined : Icons.info_outline,
            color: isDenied ? AppTheme.accentRed : AppTheme.accentCyan,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDenied
                  ? 'Access denied to /dev/hidraw. Linux udev permissions rule required for non-root USB access.'
                  : (isMock
                      ? 'Simulated Device Mode Active: Physical keyboard is not connected. All visualizer, lighting, and macro features are fully functional in simulation.'
                      : 'Connecting to USB HID keyboard...'),
              style: TextStyle(
                fontSize: 12,
                color: isDenied ? AppTheme.accentRed : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isDenied || isMock)
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Rescan USB'),
              style: TextButton.styleFrom(
                foregroundColor: isDenied ? AppTheme.accentRed : AppTheme.accentCyan,
              ),
              onPressed: () => service.connect(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.panelBorder),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
