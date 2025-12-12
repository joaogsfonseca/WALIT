import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

enum AppThemeType {
  light,
  dark,
  moonlitAsteroid,
  argon,
}

class ThemeProvider with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.dark;
  bool _isLoading = true;

  AppThemeType get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;

  // Background Gradient for the current theme
  LinearGradient? get backgroundGradient {
    switch (_currentTheme) {
      case AppThemeType.moonlitAsteroid:
        return AppColors.moonlitAsteroid;
      case AppThemeType.argon:
        return AppColors.argon;
      default:
        return null; // Solid color for Light/Dark
    }
  }

  // Background Color for the current theme (if no gradient)
  Color get backgroundColor {
    switch (_currentTheme) {
      case AppThemeType.light:
        return const Color(0xFFF5F5F7); // Soft light
      case AppThemeType.dark:
        return AppColors.background;
      case AppThemeType.moonlitAsteroid:
      case AppThemeType.argon:
        return Colors.transparent; // Handled by gradient wrapper
    }
  }

  // Main Text Color
  Color get textColor {
    return _currentTheme == AppThemeType.light
        ? const Color(0xFF1D1D1F)
        : AppColors.textPrimary;
  }
  
  // Secondary Text Color
  Color get textSecondaryColor {
     return _currentTheme == AppThemeType.light
        ? const Color(0xFF86868B)
        : AppColors.textSecondary;
  }

  // Surface Color (Cards, etc)
  Color get surfaceColor {
     return _currentTheme == AppThemeType.light
        ? Colors.white
        : AppColors.surface;
  }

  // Get current ThemeData
  ThemeData get themeData {
    if (_currentTheme == AppThemeType.light) {
      return AppTheme.lightTheme;
    } else {
      // For Dark, Moonlit Asteroid (Gradient), Argon (Gradient)
      // they all use the Dark Theme structure, with the main difference 
      // being the background handled by the wrapper.
      // However, we need to ensure Scaffold background is transparent for gradients
      final isGradientTheme = _currentTheme == AppThemeType.moonlitAsteroid || _currentTheme == AppThemeType.argon;
      
      final baseTheme = AppTheme.darkTheme;
      
      if (isGradientTheme) {
        // Glassmorphism effect for gradient themes
        // We use a high alpha to ensure readability while allowing the gradient to show through subtlely
        final glassColor = AppColors.surface.withOpacity(0.85);
        final glassHighlight = AppColors.surfaceLight.withOpacity(0.85);
        
        return baseTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          cardTheme: baseTheme.cardTheme.copyWith(
            color: glassColor,
          ),
          colorScheme: baseTheme.colorScheme.copyWith(
            surface: glassColor,
            surfaceContainerHighest: glassHighlight,
            // Ensure dialogs and sheets also have this effect if they use surface
            surfaceContainer: glassColor,
          ),
          dialogTheme: baseTheme.dialogTheme.copyWith(
            backgroundColor: glassColor,
          ),
          bottomSheetTheme: baseTheme.bottomSheetTheme.copyWith(
            backgroundColor: glassColor,
          ),
        );
      }
      
      return baseTheme.copyWith(
        scaffoldBackgroundColor: AppColors.background,
      );
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_preference');
    
    if (themeString != null) {
      _currentTheme = _getThemeFromString(themeString);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType theme, {String? token}) async {
    _currentTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', _getStringFromTheme(theme));

    // Sync with backend if logged in
    if (token != null) {
      try {
        await ApiService.updateSettings(
          token, 
          theme: _getStringFromTheme(theme),
        );
      } catch (e) {
        debugPrint('Failed to sync theme with backend: $e');
      }
    }
  }
  
  // Update from backend profile fetch
  void updateFromProfile(String? themeString) {
    if (themeString != null) {
      final backendTheme = _getThemeFromString(themeString);
      if (_currentTheme != backendTheme) {
        _currentTheme = backendTheme;
        notifyListeners();
      }
    }
  }

  AppThemeType _getThemeFromString(String theme) {
    switch (theme) {
      case 'LIGHT':
        return AppThemeType.light;
      case 'DARK': // Legacy or current
        return AppThemeType.dark;
      case 'MOONLIT_ASTEROID':
        return AppThemeType.moonlitAsteroid;
      case 'ARGON':
        return AppThemeType.argon;
      default:
        return AppThemeType.dark;
    }
  }

  String _getStringFromTheme(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.light:
        return 'LIGHT';
      case AppThemeType.dark:
        return 'DARK';
      case AppThemeType.moonlitAsteroid:
        return 'MOONLIT_ASTEROID';
      case AppThemeType.argon:
        return 'ARGON';
    }
  }
  
  // Helper to get display name
  String getDisplayName(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.light:
        return 'Light';
      case AppThemeType.dark:
        return 'Dark';
      case AppThemeType.moonlitAsteroid:
        return 'Moonlit Asteroid';
      case AppThemeType.argon:
        return 'Argon';
    }
  }
}
