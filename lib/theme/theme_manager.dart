import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const _themeKey = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else if (savedTheme == 'system') {
        themeModeNotifier.value = ThemeMode.system;
      } else {
        themeModeNotifier.value = ThemeMode.light;
      }
    } catch (_) {
      // fallback
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {}
  }

  static Future<void> toggleTheme() async {
    if (themeModeNotifier.value == ThemeMode.system) {
      await setThemeMode(ThemeMode.light);
    } else if (themeModeNotifier.value == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }

  static IconData getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  static String getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  static String getThemeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Theme: System (Switch to Light)';
      case ThemeMode.light:
        return 'Theme: Light (Switch to Dark)';
      case ThemeMode.dark:
        return 'Theme: Dark (Switch to System)';
    }
  }

  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;
}
