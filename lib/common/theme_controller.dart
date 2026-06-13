import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:flutter/material.dart';

/// Holds the user's selected ThemeMode (light / dark / system) and persists it
/// across launches via SharedPrefs. A single global instance is listened to by
/// MaterialApp so toggling rebuilds the whole app.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const String _prefKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Load the saved preference. Call once in main() after SharedPrefs().init().
  Future<void> load() async {
    final saved = SharedPrefs().getString(_prefKey);
    _mode = _decode(saved);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await SharedPrefs().setString(_prefKey, _encode(mode));
    notifyListeners();
  }

  String label() {
    switch (_mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  static ThemeMode _decode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
