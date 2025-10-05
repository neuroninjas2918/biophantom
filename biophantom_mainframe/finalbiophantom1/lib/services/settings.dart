import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  // Singleton
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  // Settings state
  bool _darkMode = false;
  bool _notifications = true;
  bool _haptics = true;
  double _textScale = 1.0; // 0.9 - 1.4
  MaterialColor _primaryColor = Colors.blue;

  // Getters
  bool get darkMode => _darkMode;
  bool get notifications => _notifications;
  bool get haptics => _haptics;
  double get textScale => _textScale;
  MaterialColor get primaryColor => _primaryColor;

  // Mutators
  set darkMode(bool v) { if (_darkMode != v) { _darkMode = v; _saveBool('darkMode', v); notifyListeners(); } }
  set notifications(bool v) { if (_notifications != v) { _notifications = v; _saveBool('notifications', v); notifyListeners(); } }
  set haptics(bool v) { if (_haptics != v) { _haptics = v; _saveBool('haptics', v); notifyListeners(); } }
  set textScale(double v) {
    final double nv = v.clamp(0.9, 1.4).toDouble();
    if (_textScale != nv) {
      _textScale = nv;
      _saveDouble('textScale', _textScale);
      notifyListeners();
    }
  }
  set primaryColor(MaterialColor c) { if (_primaryColor != c) { _primaryColor = c; _saveString('primaryColor', _materialColorToName(c)); notifyListeners(); } }

  void reset() {
    _darkMode = false;
    _notifications = true;
    _haptics = true;
    _textScale = 1.0;
    _primaryColor = Colors.blue;
    _persistAll();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? _darkMode;
    _notifications = prefs.getBool('notifications') ?? _notifications;
    _haptics = prefs.getBool('haptics') ?? _haptics;
    _textScale = prefs.getDouble('textScale') ?? _textScale;
    final colorName = prefs.getString('primaryColor');
    if (colorName != null) {
      _primaryColor = _nameToMaterialColor(colorName) ?? _primaryColor;
    }
    notifyListeners();
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notifications', _notifications);
    await prefs.setBool('haptics', _haptics);
    await prefs.setDouble('textScale', _textScale);
    await prefs.setString('primaryColor', _materialColorToName(_primaryColor));
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  String _materialColorToName(MaterialColor c) {
    if (c == Colors.green) return 'green';
    if (c == Colors.purple) return 'purple';
    if (c == Colors.orange) return 'orange';
    if (c == Colors.red) return 'red';
    return 'blue';
  }

  MaterialColor? _nameToMaterialColor(String name) {
    switch (name) {
      case 'green': return Colors.green;
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
    }
    return null;
  }
}
