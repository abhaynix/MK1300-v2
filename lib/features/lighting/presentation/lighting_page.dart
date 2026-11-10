import 'package:flutter/material.dart';
import '../../../app/theme/theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/hsv_color.dart';
import '../../../hardware/services/keyboard_service.dart';
import '../../key_remapping/models/key_geometry.dart';
import '../../key_remapping/presentation/keyboard_visualizer.dart';
import '../models/lighting_mode.dart';
import '../models/lighting_state.dart';
import '../services/lighting_preview_engine.dart';
import 'widgets/hsv_color_picker.dart';

class LightingPage extends StatefulWidget {
  final KeyboardService keyboardService;

  const LightingPage({super.key, required this.keyboardService});

  @override
  State<LightingPage> createState() => _LightingPageState();
}

class _LightingPageState extends State<LightingPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late LightingState _localState;
  late AnimationController _animController;
  Map<int, Color> _animatedColors = {};
  List<KeyGeometry> _geometries = KeyGeometry.fallbackLayout61;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocalState();
    _loadGeometries();

    // Responsive animation ticker for local visualizer preview
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onTick);
    _animController.repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    // Stop animations when minimized or hidden to prevent unnecessary CPU usage
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_animController.isAnimating) {
        _animController.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_animController.isAnimating) {
        _animController.repeat();
      }
    }
  }

  void _initLocalState() {
    final cfg = widget.keyboardService.lightingConfig;
    if (cfg != null) {
      _localState = LightingState(
        mode: cfg.mode,
        brightness: cfg.brightness,
        speed: cfg.speed,
        direction: cfg.direction,
        colorMode: cfg.colorMode,
        selectedColor: HsvColor.fromNormalized(
          hue: cfg.hue,
          saturation: cfg.saturation / 100.0,
          value: cfg.value / 100.0,
        ),
        customSwatches: List<Color>.from(ColorUtils.presetPalette),
        perKeyColors: {},
        isCustomMode: false,
        isPreviewDirty: false,
      );
    } else {
      _localState = LightingState.initial();
    }
  }

  Future<void> _loadGeometries() async {
    final loaded = await KeyGeometry.loadFromAsset();
    if (mounted && loaded.isNotEmpty) {
      setState(() {
        _geometries = loaded;
      });
    }
  }

  void _onTick() {
    if (!mounted) return;
    final timeSeconds = _animController.value * 10.0;
    final frame = LightingPreviewEngine.computeFrame(
      state: _localState,
      geometries: _geometries,
      timeSeconds: timeSeconds,
    );
    setState(() {
      _animatedColors = frame;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.removeListener(_onTick);
    _animController.dispose();
    super.dispose();
  }

  void _updateMode(LightingMode newMode) {
    setState(() {
      _localState = _localState.copyWith(
        mode: newMode,
        isPreviewDirty: true,
      );
    });
  }

  void _updateBrightness(int val) {
    setState(() {
      _localState = _localState.copyWith(
        brightness: val.clamp(0, 4),
        isPreviewDirty: true,
      );
    });
  }

  void _updateSpeed(int val) {
    setState(() {
      _localState = _localState.copyWith(
        speed: val.clamp(0, 4),
        isPreviewDirty: true,
      );
    });
  }

  void _updateDirection(int val) {
    setState(() {
      _localState = _localState.copyWith(
        direction: val,
        isPreviewDirty: true,
      );
    });
  }

  void _updateColor(HsvColor newColor) {
    setState(() {
      _localState = _localState.copyWith(
        selectedColor: newColor,
        colorMode: 1, // Single/palette color mode
        isPreviewDirty: true,
      );
    });
  }

  void _paintSingleKey(int keyIndex) {
    final updated = Map<int, Color>.from(_localState.perKeyColors);
    updated[keyIndex] = _localState.color;
    setState(() {
      _localState = _localState.copyWith(
        perKeyColors: updated,
        isPreviewDirty: true,
      );
    });
  }

  void _clearSingleKeyColor(int keyIndex) {
    final updated = Map<int, Color>.from(_localState.perKeyColors);
    updated.remove(keyIndex);
    setState(() {
      _localState = _localState.copyWith(
        perKeyColors: updated,
        isPreviewDirty: true,
      );
    });
  }

  void _clearAllPerKeyColors() {
    setState(() {
      _localState = _localState.copyWith(
        perKeyColors: {},
        isPreviewDirty: true,
      );
    });
  }

  void _applySelectedColorToAllKeys() {
    final updated = <int, Color>{};
    for (final geo in _geometries) {
      updated[geo.index] = _localState.color;
    }
    setState(() {
      _localState = _localState.copyWith(
        perKeyColors: updated,
        isPreviewDirty: true,
      );
    });
  }

  Future<void> _applyToHardware() async {
    final service = widget.keyboardService;
    if (!service.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot apply: Keyboard is disconnected'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final success = await service.applyLightingState(_localState);
    if (!mounted) return;

    if (success) {
      setState(() {
        _localState = _localState.copyWith(isPreviewDirty: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service.isUsingMock
                ? 'Applied to Simulated Hardware (Readback confirmed)'
                : 'Applied to Physical Hardware',
          ),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.lastSyncError ?? 'Failed to synchronize with hardware'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  void _resetToDefaultPreview() {
    setState(() {
      _initLocalState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.keyboardService;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Preview Status Banner & Mode Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.panelBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: _localState.isPreviewDirty ? AppTheme.accentCyan : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _localState.isPreviewDirty
                      ? 'Local Preview Active (Uncommitted changes)'
                      : 'Live Hardware Synchronization Ready',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _localState.isPreviewDirty ? AppTheme.accentCyan : Colors.white70,
                  ),
                ),
                const Spacer(),
                if (service.isUsingMock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.accentPurple),
                    ),
                    child: const Text(
                      'SIMULATED HARDWARE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentPurple),
                    ),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Apply to Device', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _localState.isPreviewDirty
                        ? AppTheme.accentCyan
                        : AppTheme.surfaceLight,
                    foregroundColor: _localState.isPreviewDirty ? Colors.black : Colors.white60,
                  ),
                  onPressed: _applyToHardware,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Reset Preview', style: TextStyle(fontSize: 12)),
                  onPressed: _resetToDefaultPreview,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Visualizer Top Section
          Expanded(
            flex: 5,
            child: KeyboardVisualizer(
              keys: service.currentKeys,
              selectedIndex: service.selectedKeyIndex,
              onKeySelected: service.selectKey,
              isCustomRgbMode: _localState.isCustomMode,
              animatedColors: _animatedColors,
              onKeyColorPainted: (index) {
                if (_localState.isCustomMode) {
                  _paintSingleKey(index);
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // Lighting Controls Bottom Panel
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.panelBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: Mode Selector & Custom Mode Toggle
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lighting Effect',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<LightingMode>(
                            initialValue: _localState.mode,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surfaceLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: AppTheme.surfaceLight,
                            items: LightingMode.values.map((mode) {
                              return DropdownMenuItem(
                                value: mode,
                                child: Text(
                                  '${mode.value}. ${mode.label} (${mode.originalName})',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (newMode) {
                              if (newMode != null) _updateMode(newMode);
                            },
                          ),
                          const SizedBox(height: 12),

                          // Custom Mode Switch wrapped in transparent Material
                          Material(
                            type: MaterialType.transparency,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Custom Per-Key RGB',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Paint individual keys using active color',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              value: _localState.isCustomMode,
                              activeThumbColor: AppTheme.accentCyan,
                              onChanged: (val) {
                                setState(() {
                                  _localState = _localState.copyWith(
                                    isCustomMode: val,
                                    isPreviewDirty: true,
                                  );
                                });
                              },
                            ),
                          ),

                          if (_localState.isCustomMode) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.format_color_fill, size: 14),
                                  label: const Text('Fill All', style: TextStyle(fontSize: 11)),
                                  onPressed: _applySelectedColorToAllKeys,
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.clear, size: 14),
                                  label: const Text('Clear All', style: TextStyle(fontSize: 11)),
                                  onPressed: _clearAllPerKeyColors,
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.backspace, size: 14),
                                  label: const Text('Clear Key', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _clearSingleKeyColor(service.selectedKeyIndex),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),
                  const VerticalDivider(color: AppTheme.panelBorder),
                  const SizedBox(width: 16),

                  // Column 2: Effect Sliders (Brightness, Speed, Direction)
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Effect Parameters',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Brightness
                          Row(
                            children: [
                              const Icon(Icons.brightness_6, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              const Text('Brightness', style: TextStyle(fontSize: 12)),
                              const Spacer(),
                              Text('${_localState.brightness}/4', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          Slider(
                            value: _localState.brightness.toDouble(),
                            min: 0,
                            max: 4,
                            divisions: 4,
                            onChanged: _localState.mode.hasBrightness
                                ? (val) => _updateBrightness(val.round())
                                : null,
                          ),

                          // Speed
                          Row(
                            children: [
                              const Icon(Icons.speed, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              const Text('Speed', style: TextStyle(fontSize: 12)),
                              const Spacer(),
                              Text('${_localState.speed}/4', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          Slider(
                            value: _localState.speed.toDouble(),
                            min: 0,
                            max: 4,
                            divisions: 4,
                            onChanged: _localState.mode.hasSpeed
                                ? (val) => _updateSpeed(val.round())
                                : null,
                          ),

                          // Direction Control
                          if (_localState.mode.hasDirection > 0) ...[
                            const SizedBox(height: 4),
                            const Text('Direction', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    _localState.mode.hasDirection == 1 ? 'Left ➔ Right' : 'Top ➔ Bottom',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected: _localState.direction == 1,
                                  onSelected: (sel) {
                                    if (sel) _updateDirection(1);
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(
                                    _localState.mode.hasDirection == 1 ? 'Right ➔ Left' : 'Bottom ➔ Top',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected: _localState.direction == 2,
                                  onSelected: (sel) {
                                    if (sel) _updateDirection(2);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),
                  const VerticalDivider(color: AppTheme.panelBorder),
                  const SizedBox(width: 16),

                  // Column 3: HSV Color Picker & 8 Swatches
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Color & Palette',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentCyan,
                                ),
                              ),
                              const Spacer(),
                              if (!_localState.isCustomMode)
                                TextButton.icon(
                                  icon: const Icon(Icons.auto_awesome, size: 14),
                                  label: Text(
                                    _localState.colorMode == 0 ? 'Rainbow (Active)' : 'Enable Rainbow',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _localState.colorMode == 0 ? AppTheme.accentCyan : Colors.grey,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _localState = _localState.copyWith(
                                        colorMode: 0,
                                        isPreviewDirty: true,
                                      );
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 8 Configurable Swatches
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _localState.customSwatches.map((color) {
                              final isCurrent = (_localState.color == color);
                              return InkWell(
                                onTap: () {
                                  _updateColor(ColorUtils.toHsv(color));
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isCurrent ? Colors.white : Colors.white24,
                                      width: isCurrent ? 2 : 1,
                                    ),
                                    boxShadow: isCurrent
                                        ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)]
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // HSV Color Picker & RGB inputs
                          HsvColorPicker(
                            initialColor: _localState.selectedColor,
                            onColorChanged: _updateColor,
                          ),
                        ],
                      ),
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
}
