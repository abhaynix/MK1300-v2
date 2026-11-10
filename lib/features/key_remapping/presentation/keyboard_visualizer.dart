import 'package:flutter/material.dart';
import '../../../app/theme/theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../key_remapping/models/key_geometry.dart';
import '../../key_remapping/models/key_mapping.dart';

/// Enhanced 61-Key Keyboard Visualizer Widget supporting dynamic animated previews
/// and multi-key / per-key custom color assignment.
class KeyboardVisualizer extends StatefulWidget {
  final List<KeyMapping> keys;
  final int selectedIndex;
  final ValueChanged<int> onKeySelected;
  final bool isCustomRgbMode;
  final ValueChanged<int>? onKeyColorPainted;
  final Map<int, Color>? animatedColors; // Dynamic preview colors (key index -> Color)

  /// Optional pre-loaded geometries. When provided, skips async asset loading
  /// (useful for tests where rootBundle is not available).
  final List<KeyGeometry>? geometries;

  const KeyboardVisualizer({
    super.key,
    required this.keys,
    required this.selectedIndex,
    required this.onKeySelected,
    this.isCustomRgbMode = false,
    this.onKeyColorPainted,
    this.animatedColors,
    this.geometries,
  });

  @override
  State<KeyboardVisualizer> createState() => _KeyboardVisualizerState();
}

class _KeyboardVisualizerState extends State<KeyboardVisualizer> {
  List<KeyGeometry> _geometries = KeyGeometry.fallbackLayout61;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    if (widget.geometries != null && widget.geometries!.isNotEmpty) {
      _geometries = widget.geometries!;
    } else {
      _loadLayoutData();
    }
  }

  Future<void> _loadLayoutData() async {
    final loaded = await KeyGeometry.loadFromAsset();
    if (mounted && loaded.isNotEmpty) {
      setState(() {
        _geometries = loaded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Base dimensions from 36ae_fe12.json: 15.02 units wide, 5.03 units high
        const double totalUnitsW = 15.02;
        const double totalUnitsH = 5.03;

        final double availableW = constraints.maxWidth - 32;
        final double availableH = constraints.maxHeight - 32;

        final double unitSizeW = availableW / totalUnitsW;
        final double unitSizeH = availableH / totalUnitsH;
        final double unit = (unitSizeW < unitSizeH ? unitSizeW : unitSizeH).clamp(30.0, 75.0);

        final double boardW = totalUnitsW * unit + 16;
        final double boardH = totalUnitsH * unit + 16;

        return Center(
          child: Container(
            width: boardW,
            height: boardH,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF14161F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.panelBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: _geometries.map((geo) {
                final keyData = widget.keys.firstWhere(
                  (k) => k.keyIndex == geo.index,
                  orElse: () => KeyMapping.fromGeometry(geo),
                );
                final isSelected = (geo.index == widget.selectedIndex);
                final isHovered = (geo.index == _hoveredIndex);
                final dynamicColor = widget.animatedColors?[geo.index];

                return Positioned(
                  left: geo.x * unit,
                  top: geo.y * unit,
                  width: geo.w * unit - 4,
                  height: geo.h * unit - 4,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = geo.index),
                    onExit: (_) => setState(() {
                      if (_hoveredIndex == geo.index) _hoveredIndex = null;
                    }),
                    child: _KeyCapWidget(
                      geometry: geo,
                      mapping: keyData,
                      isSelected: isSelected,
                      isHovered: isHovered,
                      overrideColor: dynamicColor,
                      onTap: () {
                        if (widget.isCustomRgbMode && widget.onKeyColorPainted != null) {
                          widget.onKeyColorPainted!(geo.index);
                        } else {
                          widget.onKeySelected(geo.index);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _KeyCapWidget extends StatelessWidget {
  final KeyGeometry geometry;
  final KeyMapping mapping;
  final bool isSelected;
  final bool isHovered;
  final Color? overrideColor;
  final VoidCallback onTap;

  const _KeyCapWidget({
    required this.geometry,
    required this.mapping,
    required this.isSelected,
    required this.isHovered,
    this.overrideColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final keyColor = overrideColor ?? ColorUtils.fromHex(mapping.colorHex);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentCyan.withValues(alpha: 0.25)
              : (isHovered
                  ? AppTheme.keycapNormal.withValues(alpha: 0.8)
                  : AppTheme.keycapNormal),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentCyan
                : (isHovered ? AppTheme.accentCyan.withValues(alpha: 0.5) : AppTheme.keycapBorder),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.accentCyan.withValues(alpha: 0.45),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            // RGB backlighting glow indicator
            BoxShadow(
              color: keyColor.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top indicator light line
                Container(
                  height: 3,
                  width: 16,
                  decoration: BoxDecoration(
                    color: keyColor,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: [
                      BoxShadow(
                        color: keyColor.withValues(alpha: 0.8),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    mapping.newName.isNotEmpty ? mapping.newName : geometry.name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.accentCyan : AppTheme.keycapLegend,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (mapping.newName != geometry.name && mapping.newName.isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      geometry.name,
                      style: TextStyle(
                        color: AppTheme.keycapSubLegend.withValues(alpha: 0.6),
                        fontSize: 8,
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),
            if (mapping.isPendingChange)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB300),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xAAFFB300),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
