import 'package:flutter/material.dart';

/// WALIT App Color Palette
/// Centralized color definitions for consistent theming
class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════════════════════════════
  // PRIMARY BRAND COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Premium gold accent color
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE5C76B);
  static const Color goldDark = Color(0xFFB8962E);
  
  // ══════════════════════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Primary background (pure black)
  static const Color background = Color(0xFF000000);
  
  /// Surface color for cards, inputs, etc.
  static const Color surface = Color(0xFF1E1E1E);
  
  /// Elevated surface (slightly lighter)
  static const Color surfaceLight = Color(0xFF2A2A2A);
  
  /// Card/container backgrounds
  static const Color cardBackground = Color(0xFF121212);
  
  // ══════════════════════════════════════════════════════════════════════════
  // GREY SCALE
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color grey900 = Color(0xFF1A1A1A);
  static const Color grey800 = Color(0xFF2D2D2D);
  static const Color grey700 = Color(0xFF404040);
  static const Color grey600 = Color(0xFF525252);
  static const Color grey500 = Color(0xFF737373);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey100 = Color(0xFFF3F4F6);
  
  // ══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Primary text (white)
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Secondary text (light grey)
  static const Color textSecondary = Color(0xFF9CA3AF);
  
  /// Tertiary/hint text
  static const Color textHint = Color(0xFF6B7280);
  
  /// Disabled text
  static const Color textDisabled = Color(0xFF4B5563);
  
  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Error/danger color
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  
  /// Success color
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF86EFAC);
  
  /// Warning color
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  
  /// Info color
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF93C5FD);
  
  // ══════════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Gold gradient for premium elements
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Subtle gold background gradient
  static LinearGradient get goldBackgroundGradient => LinearGradient(
    colors: [
      gold.withAlpha(51), // 0.2 * 255
      gold.withAlpha(13), // 0.05 * 255
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// White gradient for FAB
  static const LinearGradient whiteGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // BORDERS
  // ══════════════════════════════════════════════════════════════════════════
  
  static const Color borderDefault = grey800;
  static const Color borderFocus = gold;
  static const Color borderError = error;
  
  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Get gold with custom opacity (using withAlpha for Flutter 3.27+ compatibility)
  static Color goldWithOpacity(double opacity) {
    return gold.withAlpha((opacity * 255).round());
  }
  
  /// Get white with custom opacity
  static Color whiteWithOpacity(double opacity) {
    return Colors.white.withAlpha((opacity * 255).round());
  }
  
  /// Get black with custom opacity
  static Color blackWithOpacity(double opacity) {
    return Colors.black.withAlpha((opacity * 255).round());
  }
}
