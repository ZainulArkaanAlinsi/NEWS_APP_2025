import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  var systemTheme = true.obs; // Follow system theme by default

  final _storage = GetStorage();
  final _themeKey = 'isDarkMode';
  final _systemThemeKey = 'systemTheme';

  @override
  void onInit() {
    super.onInit();
    _loadThemePreferences();
  }

  // Load theme preferences from storage
  void _loadThemePreferences() {
    try {
      // Load dark mode preference
      final storedDarkMode = _storage.read(_themeKey);
      if (storedDarkMode != null) {
        isDarkMode.value = storedDarkMode;
      }

      // Load system theme preference
      final storedSystemTheme = _storage.read(_systemThemeKey);
      if (storedSystemTheme != null) {
        systemTheme.value = storedSystemTheme;
      }

      // Apply the theme
      _applyTheme();
    } catch (e) {
      print('Error loading theme preferences: $e');
    }
  }

  // Save theme preferences to storage
  void _saveThemePreferences() {
    try {
      _storage.write(_themeKey, isDarkMode.value);
      _storage.write(_systemThemeKey, systemTheme.value);
    } catch (e) {
      print('Error saving theme preferences: $e');
    }
  }

  // Apply the current theme
  void _applyTheme() {
    if (systemTheme.value) {
      // Follow system theme
      Get.changeThemeMode(ThemeMode.system);
    } else {
      // Use manual selection
      Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    }
  }

  // Toggle between dark and light mode
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    systemTheme.value = false; // Disable system theme when manually toggling
    _applyTheme();
    _saveThemePreferences();

    _showThemeChangeSnackbar();
  }

  // Set specific theme
  void setTheme(bool darkMode, {bool useSystemTheme = false}) {
    isDarkMode.value = darkMode;
    systemTheme.value = useSystemTheme;
    _applyTheme();
    _saveThemePreferences();
  }

  // Enable system theme
  void enableSystemTheme() {
    systemTheme.value = true;
    _applyTheme();
    _saveThemePreferences();

    Get.snackbar(
      '🌗 System Theme Enabled',
      'Following your device theme settings',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
    );
  }

  // Disable system theme and use current selection
  void disableSystemTheme() {
    systemTheme.value = false;
    _applyTheme();
    _saveThemePreferences();
  }

  // Get current theme mode for UI indicators
  ThemeMode get currentThemeMode {
    if (systemTheme.value) {
      return ThemeMode.system;
    }
    return isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }

  // Check if dark mode is active (considering system theme)
  bool get isDarkActive {
    if (systemTheme.value) {
      // Check system brightness using MediaQuery if context is available
      if (Get.context != null) {
        final mediaQuery = MediaQuery.of(Get.context!);
        return mediaQuery.platformBrightness == Brightness.dark;
      }
      // Fallback to platform brightness if context is not available
      return WidgetsBinding.instance.window.platformBrightness ==
          Brightness.dark;
    }
    return isDarkMode.value;
  }

  // Show theme change feedback
  void _showThemeChangeSnackbar() {
    final themeName = isDarkMode.value ? 'Dark' : 'Light';
    final emoji = isDarkMode.value ? '🌙' : '☀️';

    Get.snackbar(
      '$emoji $themeName Mode Activated',
      systemTheme.value
          ? 'Following system theme'
          : 'Theme changed to $themeName mode',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: isDarkActive ? Colors.grey[800] : Colors.blue.shade600,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  // Reset to default theme (system theme)
  void resetToDefault() {
    systemTheme.value = true;
    _applyTheme();
    _saveThemePreferences();

    Get.snackbar(
      '🔄 Theme Reset',
      'Theme settings restored to default',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Get theme info for settings page
  Map<String, dynamic> get themeInfo {
    return {
      'isDarkMode': isDarkMode.value,
      'systemTheme': systemTheme.value,
      'currentMode': isDarkActive ? 'Dark' : 'Light',
      'isFollowingSystem': systemTheme.value,
    };
  }

  // Clean up
  @override
  void onClose() {
    _saveThemePreferences();
    super.onClose();
  }
}
