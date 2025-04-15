import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _fontSizeKey = 'fontSize';
  static const String _notificationsKey = 'notificationsEnabled';

  String _themeMode = 'light';
  String _fontSize = 'medium';
  bool _notificationsEnabled = true;

  String get themeMode => _themeMode;
  String get fontSize => _fontSize;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getString(_themeModeKey) ?? 'light';
    _fontSize = prefs.getString(_fontSizeKey) ?? 'medium';
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setFontSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, size);
    _fontSize = size;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    _notificationsEnabled = enabled;
    notifyListeners();
  }
}