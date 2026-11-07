import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/hsv_color.dart';
import '../../key_remapping/models/key_geometry.dart';
import '../models/lighting_mode.dart';
import '../models/lighting_state.dart';

/// Pure computation engine for calculating 61-key animation frames based on
/// recovered lighting effects from the original Ant Esports MK1300 V2 software.
///
/// NOTE: Previews are approximate visual simulations designed for responsive local desktop rendering.
/// Real firmware timing and LED driver PWM response may vary slightly.
class LightingPreviewEngine {
  LightingPreviewEngine._();

  /// Computes simulated per-key colors for a given point in time ([timeSeconds]).
  /// Returns a map of key index (0-73) -> [Color].
  static Map<int, Color> computeFrame({
    required LightingState state,
    required List<KeyGeometry> geometries,
    required double timeSeconds,
    Map<int, Color>? customPerKeyOverrides,
  }) {
    // If in custom mode, return explicit per-key colors
    if (state.isCustomMode) {
      final result = <int, Color>{};
      for (final geo in geometries) {
        final override = customPerKeyOverrides?[geo.index] ?? state.perKeyColors[geo.index];
        result[geo.index] = override ?? const Color(0x00000000);
      }
      return result;
    }

    // Effect Off
    if (state.mode == LightingMode.off || state.brightness == 0) {
      return {for (final g in geometries) g.index: const Color(0xFF000000)};
    }

    final double brightnessScale = (state.brightness / 4.0).clamp(0.0, 1.0);
    final double speedFactor = 0.5 + (state.speed * 0.5); // 0.5x to 2.5x speed
    final double phase = timeSeconds * speedFactor;

    final result = <int, Color>{};

    switch (state.mode) {
      case LightingMode.off:
        for (final g in geometries) {
          result[g.index] = const Color(0xFF000000);
        }
        break;

      case LightingMode.staticOn:
        final baseColor = state.color;
        final dimmed = _applyBrightness(baseColor, brightnessScale);
        for (final g in geometries) {
          result[g.index] = dimmed;
        }
        break;

      case LightingMode.breathing:
        final baseColor = state.color;
        // Cosine pulsation between 0.1 and 1.0
        final wave = (math.cos(phase * 2 * math.pi) + 1.0) / 2.0;
        final dimmed = _applyBrightness(baseColor, wave * brightnessScale);
        for (final g in geometries) {
          result[g.index] = dimmed;
        }
        break;

      case LightingMode.colorLoop:
        // Global rainbow hue shifting
        final hue = (phase * 60.0) % 360.0;
        final hsv = HsvColor(hue: hue, saturation: 1.0, value: brightnessScale);
        final color = ColorUtils.fromHsv(hsv);
        for (final g in geometries) {
          result[g.index] = color;
        }
        break;

      case LightingMode.stream:
        // Horizontal wave (Direction 1: L->R, Direction 2: R->L)
        final dir = (state.direction == 2) ? -1.0 : 1.0;
        for (final g in geometries) {
          final normX = g.x / 15.0; // 0.0 to 1.0
          if (state.colorMode == 0) {
            // Rainbow wave
            final hue = (normX * 360.0 * dir + phase * 180.0) % 360.0;
            final hsv = HsvColor.fromNormalized(hue: hue, saturation: 1.0, value: brightnessScale);
            result[g.index] = ColorUtils.fromHsv(hsv);
          } else {
            // Monochromatic traveling wave
            final sinVal = (math.sin(normX * math.pi * 2 * dir + phase * 4) + 1.0) / 2.0;
            result[g.index] = _applyBrightness(state.color, sinVal * brightnessScale);
          }
        }
        break;

      case LightingMode.udWave:
        // Vertical wave (Direction 1: Up->Down, Direction 2: Down->Up)
        final dir = (state.direction == 2) ? -1.0 : 1.0;
        for (final g in geometries) {
          final normY = g.y / 5.0; // 0.0 to 1.0
          if (state.colorMode == 0) {
            final hue = (normY * 360.0 * dir + phase * 180.0) % 360.0;
            final hsv = HsvColor.fromNormalized(hue: hue, saturation: 1.0, value: brightnessScale);
            result[g.index] = ColorUtils.fromHsv(hsv);
          } else {
            final sinVal = (math.sin(normY * math.pi * 2 * dir + phase * 4) + 1.0) / 2.0;
            result[g.index] = _applyBrightness(state.color, sinVal * brightnessScale);
          }
        }
        break;

      case LightingMode.bloom:
        // Circular ripple expanding from center (x: 7.5, y: 2.5)
        const centerX = 7.5;
        const centerY = 2.5;
        for (final g in geometries) {
          final dist = math.sqrt(math.pow(g.x - centerX, 2) + math.pow(g.y - centerY, 2));
          if (state.colorMode == 0) {
            final hue = (dist * 40.0 - phase * 150.0) % 360.0;
            final hsv = HsvColor.fromNormalized(hue: hue, saturation: 1.0, value: brightnessScale);
            result[g.index] = ColorUtils.fromHsv(hsv);
          } else {
            final wave = (math.sin(dist * 1.5 - phase * 5.0) + 1.0) / 2.0;
            result[g.index] = _applyBrightness(state.color, wave * brightnessScale);
          }
        }
        break;

      case LightingMode.sineWave:
      case LightingMode.spin:
      case LightingMode.wheel:
        // Radial/angular sweep
        const centerX = 7.5;
        const centerY = 2.5;
        for (final g in geometries) {
          final angle = math.atan2(g.y - centerY, g.x - centerX); // -pi to +pi
          final normAngle = (angle + math.pi) / (2 * math.pi); // 0.0 to 1.0
          if (state.colorMode == 0) {
            final hue = (normAngle * 360.0 + phase * 180.0) % 360.0;
            final hsv = HsvColor.fromNormalized(hue: hue, saturation: 1.0, value: brightnessScale);
            result[g.index] = ColorUtils.fromHsv(hsv);
          } else {
            final wave = (math.sin(normAngle * 2 * math.pi + phase * 4) + 1.0) / 2.0;
            result[g.index] = _applyBrightness(state.color, wave * brightnessScale);
          }
        }
        break;

      case LightingMode.tide:
      case LightingMode.twinFlowers:
      case LightingMode.chase:
      case LightingMode.shrink:
        // Center collision / inward ripple
        for (final g in geometries) {
          final distFromEdge = (g.x - 7.5).abs() / 7.5;
          final wave = (math.cos(distFromEdge * math.pi * 2 - phase * 4) + 1.0) / 2.0;
          if (state.colorMode == 0) {
            final hue = (distFromEdge * 360.0 + phase * 120.0) % 360.0;
            final hsv = HsvColor.fromNormalized(hue: hue, saturation: 1.0, value: wave * brightnessScale);
            result[g.index] = ColorUtils.fromHsv(hsv);
          } else {
            result[g.index] = _applyBrightness(state.color, wave * brightnessScale);
          }
        }
        break;

      default:
        // Default generic pulse for other reactive/complex modes
        final baseColor = state.colorMode == 0 ? const Color(0xFF00E5FF) : state.color;
        final pulse = (math.sin(phase * 3.0) + 1.0) / 2.0;
        final col = _applyBrightness(baseColor, (0.3 + 0.7 * pulse) * brightnessScale);
        for (final g in geometries) {
          result[g.index] = col;
        }
        break;
    }

    return result;
  }

  static Color _applyBrightness(Color c, double factor) {
    final clampedFactor = factor.clamp(0.0, 1.0);
    return Color.fromARGB(
      255,
      (c.r * 255.0 * clampedFactor).round().clamp(0, 255),
      (c.g * 255.0 * clampedFactor).round().clamp(0, 255),
      (c.b * 255.0 * clampedFactor).round().clamp(0, 255),
    );
  }
}
