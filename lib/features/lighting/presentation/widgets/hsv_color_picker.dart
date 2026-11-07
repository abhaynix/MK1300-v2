import 'package:flutter/material.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/hsv_color.dart';

/// Interactive HSV color picker and RGB channel input widget.
class HsvColorPicker extends StatefulWidget {
  final HsvColor initialColor;
  final ValueChanged<HsvColor> onColorChanged;

  const HsvColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<HsvColorPicker> createState() => _HsvColorPickerState();
}

class _HsvColorPickerState extends State<HsvColorPicker> {
  late double _hue;
  late double _saturation;
  late double _value;
  late TextEditingController _hexController;
  late TextEditingController _rController;
  late TextEditingController _gController;
  late TextEditingController _bController;

  @override
  void initState() {
    super.initState();
    _hue = widget.initialColor.hue;
    _saturation = widget.initialColor.saturation;
    _value = widget.initialColor.value;

    final rgb = widget.initialColor.toRGB();
    _hexController = TextEditingController(text: widget.initialColor.toHex());
    _rController = TextEditingController(text: rgb[0].toString());
    _gController = TextEditingController(text: rgb[1].toString());
    _bController = TextEditingController(text: rgb[2].toString());
  }

  @override
  void didUpdateWidget(covariant HsvColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialColor != oldWidget.initialColor) {
      _hue = widget.initialColor.hue;
      _saturation = widget.initialColor.saturation;
      _value = widget.initialColor.value;
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final current = HsvColor(hue: _hue, saturation: _saturation, value: _value);
    final rgb = current.toRGB();
    if (_hexController.text != current.toHex()) {
      _hexController.text = current.toHex();
    }
    _rController.text = rgb[0].toString();
    _gController.text = rgb[1].toString();
    _bController.text = rgb[2].toString();
  }

  void _notifyChange() {
    final updated = HsvColor.fromNormalized(
      hue: _hue,
      saturation: _saturation,
      value: _value,
    );
    _syncControllers();
    widget.onColorChanged(updated);
  }

  void _onRgbInputChanged() {
    final r = int.tryParse(_rController.text) ?? 0;
    final g = int.tryParse(_gController.text) ?? 0;
    final b = int.tryParse(_bController.text) ?? 0;
    final hsv = HsvColor.fromRGB(r, g, b);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
      _hexController.text = hsv.toHex();
    });
    widget.onColorChanged(hsv);
  }

  void _onHexSubmitted(String text) {
    final hsv = HsvColor.fromHex(text, fallback: HsvColor(hue: _hue, saturation: _saturation, value: _value));
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
      _syncControllers();
    });
    widget.onColorChanged(hsv);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = ColorUtils.fromHsv(HsvColor(hue: _hue, saturation: _saturation, value: _value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 2D Saturation / Value Gradient Box
        SizedBox(
          height: 120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (details) => _handleSatValGesture(details.localPosition, constraints.biggest),
                onPanUpdate: (details) => _handleSatValGesture(details.localPosition, constraints.biggest),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Base Hue Layer
                      Container(
                        color: ColorUtils.fromHsv(HsvColor(hue: _hue, saturation: 1.0, value: 1.0)),
                      ),
                      // White Horizontal Gradient (Saturation: left=0, right=1)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.white, Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                      // Black Vertical Gradient (Value: top=1, bottom=0)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Colors.black],
                          ),
                        ),
                      ),
                      // Thumb indicator
                      Positioned(
                        left: (_saturation * constraints.maxWidth - 7).clamp(0.0, constraints.maxWidth - 14),
                        top: ((1.0 - _value) * constraints.maxHeight - 7).clamp(0.0, constraints.maxHeight - 14),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentColor,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // 1D Hue Spectrum Bar
        SizedBox(
          height: 18,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (details) => _handleHueGesture(details.localPosition.dx, constraints.maxWidth),
                onPanUpdate: (details) => _handleHueGesture(details.localPosition.dx, constraints.maxWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF0000),
                              Color(0xFFFFFF00),
                              Color(0xFF00FF00),
                              Color(0xFF00FFFF),
                              Color(0xFF0000FF),
                              Color(0xFFFF00FF),
                              Color(0xFFFF0000),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: ((_hue / 360.0) * constraints.maxWidth - 4).clamp(0.0, constraints.maxWidth - 8),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black26),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Hex and RGB inputs
        Row(
          children: [
            // Color preview swatch
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 8),

            // Hex input
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _hexController,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    labelText: 'HEX',
                    labelStyle: const TextStyle(fontSize: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onSubmitted: _onHexSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // R
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _rController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    labelText: 'R',
                    labelStyle: const TextStyle(fontSize: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onChanged: (_) => _onRgbInputChanged(),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // G
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _gController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    labelText: 'G',
                    labelStyle: const TextStyle(fontSize: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onChanged: (_) => _onRgbInputChanged(),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // B
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _bController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    labelText: 'B',
                    labelStyle: const TextStyle(fontSize: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onChanged: (_) => _onRgbInputChanged(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSatValGesture(Offset localPos, Size size) {
    final s = (localPos.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - (localPos.dy / size.height)).clamp(0.0, 1.0);
    setState(() {
      _saturation = s;
      _value = v;
    });
    _notifyChange();
  }

  void _handleHueGesture(double localX, double width) {
    final h = ((localX / width).clamp(0.0, 1.0) * 360.0) % 360.0;
    setState(() {
      _hue = h;
    });
    _notifyChange();
  }
}
