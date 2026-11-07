import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/theme.dart';
import '../../hardware/services/keyboard_service.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/lighting/presentation/lighting_page.dart';
import '../../features/key_remapping/presentation/key_remapping_page.dart';
import '../../features/macros/presentation/macro_page.dart';
import '../../features/settings/presentation/settings_page.dart';

class AppShell extends StatefulWidget {
  final KeyboardService keyboardService;

  const AppShell({super.key, required this.keyboardService});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final service = widget.keyboardService;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final pages = [
          DashboardPage(
            keyboardService: service,
            onNavigateTab: (index) => setState(() => _selectedNavIndex = index),
          ),
          LightingPage(keyboardService: service),
          KeyRemappingPage(keyboardService: service),
          MacroPage(keyboardService: service),
          SettingsPage(keyboardService: service),
        ];

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
                opacity: 0.15,
              ),
            ),
            child: Column(
              children: [
                _buildTopBar(service),
                Expanded(
                  child: Row(
                    children: [
                      _buildSidebar(),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: pages[_selectedNavIndex],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(KeyboardService service) {
    final isConnected = service.isConnected;
    final config = service.config;
    final currentProfile = config?.currentProfile ?? 0;
    final battery = service.batteryLevel;
    final isFn = (config?.activeLayer ?? 0) == 1;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.panelBorder)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Image.asset('assets/images/app_icon.ico', width: 28, height: 28, errorBuilder: (c, e, s) {
                return const Icon(Icons.keyboard, color: AppTheme.accentCyan, size: 28);
              }),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ANT ESPORTS MK1300 V2',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '61-Key ARGB Mechanical Gaming Software',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Connection status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? (service.isUsingMock
                      ? AppTheme.accentCyan.withValues(alpha: 0.15)
                      : AppTheme.accentGreen.withValues(alpha: 0.15))
                  : AppTheme.accentRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected
                    ? (service.isUsingMock ? AppTheme.accentCyan : AppTheme.accentGreen)
                    : AppTheme.accentRed,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isConnected
                      ? (service.isUsingMock ? AppTheme.accentCyan : AppTheme.accentGreen)
                      : AppTheme.accentRed,
                ),
                const SizedBox(width: 6),
                Text(
                  service.isUsingMock
                      ? 'SIMULATED DEVICE (OFFLINE)'
                      : (isConnected ? 'PHYSICAL KEYBOARD (USB)' : 'DISCONNECTED'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConnected
                        ? (service.isUsingMock ? AppTheme.accentCyan : AppTheme.accentGreen)
                        : AppTheme.accentRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Battery badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.panelBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  battery > 50
                      ? Icons.battery_full
                      : (battery > 20 ? Icons.battery_3_bar : Icons.battery_alert),
                  size: 14,
                  color: battery > 20 ? AppTheme.accentCyan : AppTheme.accentRed,
                ),
                const SizedBox(width: 4),
                Text(
                  '$battery%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Layer Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isFn ? AppTheme.accentCyan.withValues(alpha: 0.2) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isFn ? AppTheme.accentCyan : AppTheme.panelBorder,
              ),
            ),
            child: Text(
              isFn ? 'FN LAYER' : 'MAIN LAYER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isFn ? AppTheme.accentCyan : AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Profile Selector Buttons (1, 2, 3)
          Row(
            children: List.generate(3, (idx) {
              final isProfileSelected = currentProfile == idx;
              return Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: InkWell(
                  onTap: () => service.switchProfile(idx),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 30,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isProfileSelected
                          ? AppTheme.accentCyan
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isProfileSelected ? AppTheme.accentCyan : AppTheme.panelBorder,
                      ),
                    ),
                    child: Text(
                      'P${idx + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isProfileSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final navItems = [
      {'title': 'Dashboard', 'asset': 'assets/images/performce.svg', 'icon': Icons.dashboard},
      {'title': 'Lighting', 'asset': 'assets/images/light.svg', 'icon': Icons.lightbulb_outline},
      {'title': 'Key Remap', 'asset': 'assets/images/keyboard.svg', 'icon': Icons.keyboard},
      {'title': 'Macro Studio', 'asset': 'assets/images/macro.svg', 'icon': Icons.smart_toy_outlined},
      {'title': 'Settings', 'asset': 'assets/images/config.svg', 'icon': Icons.settings},
    ];

    return Container(
      width: 180,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.panelBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          for (int i = 0; i < navItems.length; i++)
            _buildNavTile(
              index: i,
              title: navItems[i]['title'] as String,
              assetPath: navItems[i]['asset'] as String,
              fallbackIcon: navItems[i]['icon'] as IconData,
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'MK1300 V2.0\nNative Flutter',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required int index,
    required String title,
    required String assetPath,
    required IconData fallbackIcon,
  }) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedNavIndex = index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.6) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                assetPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
                  BlendMode.srcIn,
                ),
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: 18,
                  color: isSelected ? AppTheme.accentCyan : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
