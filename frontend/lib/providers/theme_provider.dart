import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

enum AppThemeType {
  light,
  dark,
}

class ThemeProvider with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.dark;
  bool _isLoading = true;

  AppThemeType get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;

  // No gradient themes — kept for the global background wrapper in main.dart.
  LinearGradient? get backgroundGradient => null;

  // Background Color for the current theme
  Color get backgroundColor {
    return _currentTheme == AppThemeType.light
        ? const Color(0xFFF5F5F7) // Soft light
        : AppColors.background;
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
    return _currentTheme == AppThemeType.light
        ? AppTheme.lightTheme
        : AppTheme.darkTheme;
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
      case 'DARK':
        return AppThemeType.dark;
      default:
        // Legacy values (e.g. MOONLIT_ASTEROID, ARGON) fall back to Dark.
        return AppThemeType.dark;
    }
  }

  String _getStringFromTheme(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.light:
        return 'LIGHT';
      case AppThemeType.dark:
        return 'DARK';
    }
  }

  // Helper to get display name
  String getDisplayName(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.light:
        return 'Light';
      case AppThemeType.dark:
        return 'Dark';
    }
  }
}
