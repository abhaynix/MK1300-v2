import 'package:flutter/material.dart';
import '../../../app/theme/theme.dart';
import '../../../hardware/services/keyboard_service.dart';
import '../models/key_geometry.dart';
import '../models/key_mapping.dart';
import 'keyboard_visualizer.dart';

/// Full-featured Key Remapping and Layer Controller interface for MK1300 V2.
/// Supports Layer 0 (Main) and Layer 1 (Fn), category browsing, search filtering,
/// local pending state tracking, explicit Apply/Revert commits, and safety gating.
class KeyRemappingPage extends StatefulWidget {
  final KeyboardService keyboardService;

  /// Optional pre-loaded geometries for the keyboard visualizer.
  /// When provided, skips async asset loading (useful in tests).
  final List<KeyGeometry>? geometries;

  const KeyRemappingPage({super.key, required this.keyboardService, this.geometries});

  @override
  State<KeyRemappingPage> createState() => _KeyRemappingPageState();
}

class _KeyRemappingPageState extends State<KeyRemappingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isApplying = false;

  final List<RemapCategory> _categories = [
    RemapCategory.basic,
    RemapCategory.media,
    RemapCategory.mouse,
    RemapCategory.shortcut,
    RemapCategory.hardware,
    RemapCategory.macro,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.keyboardService,
      builder: (context, _) {
        final service = widget.keyboardService;
        final selectedKey = service.selectedKey;
        final hasPending = service.hasPendingRemaps;
        final pendingCount = service.pendingRemapCount;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action & Layer Navigation Bar
              _buildTopBar(service, hasPending, pendingCount),
              const SizedBox(height: 12),

              // Visualizer Section
              Expanded(
                flex: 4,
                child: KeyboardVisualizer(
                  keys: service.currentKeys,
                  selectedIndex: service.selectedKeyIndex,
                  onKeySelected: service.selectKey,
                  geometries: widget.geometries,
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Section: Selected Key Detail + Action Drawer
              Expanded(
                flex: 5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Panel: Selected Key Inspection Card
                    SizedBox(
                      width: 280,
                      child: _buildKeyInspectorCard(selectedKey, service),
                    ),
                    const SizedBox(width: 16),

                    // Right Panel: Action Catalog & Search
                    Expanded(
                      child: _buildActionCatalogPanel(service),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Top Bar containing Layer Switcher, Sync status, Safety pill, and Action buttons.
  Widget _buildTopBar(KeyboardService service, bool hasPending, int pendingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: [
          // Layer Switcher
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('Main Layer (0)'),
                icon: Icon(Icons.keyboard_outlined, size: 16),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Fn Layer (1)'),
                icon: Icon(Icons.alt_route_outlined, size: 16),
              ),
            ],
            selected: {service.activeLayer},
            onSelectionChanged: (set) {
              service.setActiveLayer(set.first);
            },
          ),
          const SizedBox(width: 16),

          // Pending / Sync Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hasPending
                  ? const Color(0x22FFB300)
                  : const Color(0x2200E5FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasPending
                    ? const Color(0xFFFFB300)
                    : AppTheme.accentCyan,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPending ? Icons.pending_actions : Icons.check_circle_outline,
                  size: 14,
                  color: hasPending ? const Color(0xFFFFB300) : AppTheme.accentCyan,
                ),
                const SizedBox(width: 6),
                Text(
                  hasPending ? '$pendingCount Pending' : 'Hardware In Sync',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasPending ? const Color(0xFFFFB300) : AppTheme.accentCyan,
                  ),
                ),
              ],
            ),
          ),

          // Hardware Write Safety Gate Pill
          if (!service.isUsingMock && service.isHardwareWriteGated) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 13, color: Colors.redAccent),
                  SizedBox(width: 4),
                  Text(
                    'Write Gate Active',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(width: 24),

          // Readback Refresh Button
          IconButton(
            tooltip: 'Read layer keymap from device (CMD 0x06, 0x08)',
            icon: const Icon(Icons.sync, size: 18),
            onPressed: () async {
              final ok = await service.readKeymapLayer(service.activeLayer);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Successfully read keymap from device'
                        : (service.lastSyncError ?? 'Failed to read keymap')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 6),

          // Reset Layer Button
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt, size: 16),
            label: const Text('Reset Layer', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: () {
              service.resetLayerToDefault();
            },
          ),
          const SizedBox(width: 6),

          // Revert Pending Button
          OutlinedButton.icon(
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('Revert', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: hasPending
                ? () {
                    service.revertPendingRemaps();
                  }
                : null,
          ),
          const SizedBox(width: 8),

          // Explicit Apply Button
          ElevatedButton.icon(
            icon: _isApplying
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 16),
            label: const Text('Apply to Device', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: (hasPending && !_isApplying)
                ? () async {
                    setState(() => _isApplying = true);
                    final success = await service.applyAllPendingRemaps();
                    setState(() => _isApplying = false);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Key remappings applied successfully!'
                              : (service.lastSyncError ?? 'Failed to apply remappings')),
                          backgroundColor: success ? Colors.teal : Colors.redAccent,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      ),
    );
  }

  /// Left Inspector Card showing physical and assigned properties for the selected key.
  Widget _buildKeyInspectorCard(KeyMapping? key, KeyboardService service) {
    if (key == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.panelBorder),
        ),
        alignment: Alignment.center,
        child: const Text('No key selected', style: TextStyle(color: Colors.grey)),
      );
    }

    final isPending = key.isPendingChange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Key Title and Index
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentCyan),
                ),
                alignment: Alignment.center,
                child: Text(
                  key.defaultName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.accentCyan),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Physical Key: ${key.defaultName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Matrix Index ${key.keyIndex} (Layer ${service.activeLayer})',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppTheme.panelBorder),

          // Key Function Status Details
          _buildDetailRow('Default:', key.defaultName, isEmphasized: false),
          const SizedBox(height: 6),
          _buildDetailRow('Confirmed:', key.confirmedName, isEmphasized: false),
          const SizedBox(height: 6),
          _buildDetailRow(
            'Assigned:',
            key.newName,
            isEmphasized: true,
            trailing: isPending
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFB300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('PENDING', style: TextStyle(color: Color(0xFFFFB300), fontSize: 9, fontWeight: FontWeight.bold)),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          _buildDetailRow('Category:', key.category.label, isEmphasized: false),
          const SizedBox(height: 6),
          _buildDetailRow('Tuple (Wire):', '[${key.newType}, ${key.newCode1}, ${key.newCode2}, ${key.newCode3}]', isEmphasized: false),

          const Spacer(),

          // Key Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt, size: 14),
                  label: const Text('Reset Key', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    service.resetSelectedKeyToDefault();
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (isPending)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Apply Key', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () async {
                      final ok = await service.applyKeyRemap(service.selectedKeyIndex);
                      if (mounted && !ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(service.lastSyncError ?? 'Failed to apply key remap'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isEmphasized = false, Widget? trailing}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isEmphasized ? FontWeight.bold : FontWeight.normal,
              color: isEmphasized ? AppTheme.accentCyan : Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }

  /// Right Panel with Category TabBar, Search Field, and Grid of assignable actions.
  Widget _buildActionCatalogPanel(KeyboardService service) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Column(
        children: [
          // Search & Category Tab Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Category Tabs
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppTheme.accentCyan,
                    labelColor: AppTheme.accentCyan,
                    unselectedLabelColor: Colors.grey,
                    tabAlignment: TabAlignment.start,
                    tabs: _categories.map((c) => Tab(text: c.label)).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                // Search Input Field
                SizedBox(
                  width: 220,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search action...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.panelBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.panelBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.accentCyan),
                      ),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.panelBorder),

          // Action Grid Views
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResultsGrid(service)
                : TabBarView(
                    controller: _tabController,
                    children: _categories.map((category) {
                      final actions = KeyCatalog.search('', category: category);
                      return _buildActionsGrid(actions, service);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsGrid(KeyboardService service) {
    final results = KeyCatalog.search(_searchQuery);
    if (results.isEmpty) {
      return const Center(
        child: Text('No actions matching search query', style: TextStyle(color: Colors.grey)),
      );
    }
    return _buildActionsGrid(results, service);
  }

  Widget _buildActionsGrid(List<KeyRemapAction> actions, KeyboardService service) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisExtent: 42,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final isAssigned = (service.selectedKey?.newName == action.name);

        return InkWell(
          onTap: () {
            if (service.selectedKeyIndex >= 0) {
              service.assignKeyAction(service.selectedKeyIndex, action);
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAssigned
                  ? AppTheme.accentCyan.withValues(alpha: 0.2)
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isAssigned ? AppTheme.accentCyan : AppTheme.panelBorder,
                width: isAssigned ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              action.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isAssigned ? FontWeight.bold : FontWeight.w500,
                color: isAssigned ? AppTheme.accentCyan : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
