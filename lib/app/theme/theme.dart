import 'package:flutter/material.dart';

/// Design tokens and dark gaming theme for MK1300 V2 software.
class AppTheme {
  AppTheme._();

  // Core Palette
  static const Color background = Color(0xFF12141A);
  static const Color surface = Color(0xFF181B24);
  static const Color surfaceLight = Color(0xFF222634);
  
  // Glassmorphic panel colors
  static const Color panelBackground = Color(0xCC1A2333);
  static const Color panelBorder = Color(0x336BC4FF);

  // Accents
  static const Color accentCyan = Color(0xFF6BC4FF);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPurple = Color(0xFFA855F7);

  // Keycap colors
  static const Color keycapNormal = Color(0xFF282C37);
  static const Color keycapBorder = Color(0xFF383E4E);
  static const Color keycapSelected = Color(0xFF0284C7);
  static const Color keycapLegend = Color(0xFFE2E8F0);
  static const Color keycapSubLegend = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accentCyan,
        secondary: accentGreen,
        error: accentRed,
        onSurface: Colors.white,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: panelBorder),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentCyan,
        inactiveTrackColor: surfaceLight,
        thumbColor: accentCyan,
        overlayColor: accentCyan.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
