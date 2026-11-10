import 'package:flutter/material.dart';

/// ChaiUI design tokens and dark gaming theme for MK1300 V2 software.
/// 
/// Follows the chaicode.com aesthetic (ChaiUI):
/// - Near-black warm background (#0a0a0a, oklch(0.145 0 0))
/// - Warm hairline borders (orange-50/15, #FFF7ED with 15% opacity)
/// - Quiet highlight cream (orange-100, #FFEDD5) for emphasized phrases/accents
/// - Asymmetric corner radius on buttons (solid: top-right & bottom-left; outline: top-left & bottom-right)
/// - No drop shadows (depth achieved through hairline borders and subtle fills)
/// - Pure neutral greys and clean sentence-case typography
class AppTheme {
  AppTheme._();

  // Core ChaiUI Palette
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceLight = Color(0xFF1E1E1E);

  // ChaiUI Card & Panel Tokens
  static const Color cardFill = Color(0xFF141414);
  static const Color cardEdge = Color(0x26FFF7ED); // orange-50 / 15% opacity
  static const Color cardEdgeHover = Color(0x4DFFF7ED); // orange-50 / 30% opacity
  static const Color panelBackground = Color(0xFF141414);
  static const Color panelBorder = Color(0x26FFF7ED);

  // ChaiUI Accent & Meaning Colors
  static const Color highlightCream = Color(0xFFFFEDD5); // orange-100
  static const Color accentCyan = Color(0xFFFFEDD5); // Aliased to ChaiUI highlight cream
  static const Color accentBlue = Color(0xFFFAFAFA); // ChaiUI solid white on dark
  static const Color accentGreen = Color(0xFF4ADE80); // Thin stroke / text indicator
  static const Color accentRed = Color(0xFFEF4444); // Error / destructive indicator
  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color brand = Color(0xFFF97316); // Only for logo & glints

  // Keycap Colors (Warm neutral dark with hairline borders)
  static const Color keycapNormal = Color(0xFF181818);
  static const Color keycapBorder = Color(0x26FFF7ED);
  static const Color keycapSelected = Color(0xFF262626);
  static const Color keycapLegend = Color(0xFFFAFAFA);
  static const Color keycapSubLegend = Color(0xFF737373);
  static const Color textMuted = Color(0xFFA3A3A3);
  static const Color textPrimary = Color(0xFFFAFAFA);

  // Asymmetric Button Corner Radii
  static const BorderRadius asymmetricSolid = BorderRadius.only(
    topRight: Radius.circular(10),
    bottomLeft: Radius.circular(10),
  );

  static const BorderRadius asymmetricOutline = BorderRadius.only(
    topLeft: Radius.circular(10),
    bottomRight: Radius.circular(10),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: Color(0xFFFAFAFA),
        onPrimary: Color(0xFF0A0A0A),
        secondary: highlightCream,
        error: accentRed,
        onSurface: textPrimary,
      ),
      fontFamily: 'Manrope',
      fontFamilyFallback: const ['Montserrat', 'Segoe UI', 'Ubuntu', 'Cantarell', 'sans-serif'],
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: panelBorder, width: 1.0),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: highlightCream,
        inactiveTrackColor: surfaceLight,
        thumbColor: Color(0xFFFAFAFA),
        overlayColor: highlightCream.withValues(alpha: 0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFAFAFA),
          foregroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: asymmetricSolid),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: panelBorder, width: 1.0),
          shape: const RoundedRectangleBorder(borderRadius: asymmetricOutline),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: panelBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
