import 'package:flutter/material.dart';
import '../../../app/theme/theme.dart';
import '../../../core/constants/key_codes.dart';
import '../../../hardware/services/keyboard_service.dart';
import 'keyboard_visualizer.dart';

class KeyRemappingPage extends StatefulWidget {
  final KeyboardService keyboardService;

  const KeyRemappingPage({super.key, required this.keyboardService});

  @override
  State<KeyRemappingPage> createState() => _KeyRemappingPageState();
}

class _KeyRemappingPageState extends State<KeyRemappingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.keyboardService;
    final selectedKey = service.selectedKey;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Visualizer Top Section with Layer Toggle
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Layer Selector (Main Layer vs Fn Layer)
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Main Layer (0)')),
                        ButtonSegment(value: 1, label: Text('Fn Layer (1)')),
                      ],
                      selected: {service.activeLayer},
                      onSelectionChanged: (set) {
                        service.setActiveLayer(set.first);
                      },
                    ),
                    // Selected Key Info Badge
                    if (selectedKey != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.accentCyan),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Selected Key: ${selectedKey.defaultName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Text('→', style: TextStyle(color: AppTheme.accentCyan)),
                            const SizedBox(width: 8),
                            Text(
                              selectedKey.newName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          // Key Category Drawer Bottom Section
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.panelBorder),
              ),
              child: Column(
                children: [
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.accentCyan,
                    labelColor: AppTheme.accentCyan,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Basic Keys'),
                      Tab(text: 'Media Controls'),
                      Tab(text: 'Mouse Actions'),
                      Tab(text: 'Shortcuts'),
                      Tab(text: 'Hardware Controls'),
                    ],
                  ),
                  const Divider(height: 1, color: AppTheme.panelBorder),
                  // Tab Views with Key Pickers
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildKeyGrid(KeyCodes.basicKeys, service),
                        _buildKeyGrid(KeyCodes.mediaKeys, service),
                        _buildKeyGrid(KeyCodes.mouseKeys, service),
                        _buildKeyGrid(KeyCodes.shortcutKeys, service),
                        _buildKeyGrid(KeyCodes.hardwareKeys, service),
                      ],
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

  Widget _buildKeyGrid(List<KeyCodeItem> items, KeyboardService service) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisExtent: 44,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            if (service.selectedKeyIndex >= 0) {
              service.remapKey(
                service.selectedKeyIndex,
                type: item.type,
                code1: item.value1,
                code2: item.value2,
                code3: item.value3,
                newName: item.name,
              );
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.panelBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}
