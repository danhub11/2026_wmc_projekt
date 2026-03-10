import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager extends ChangeNotifier {
  bool isDarkMode = true;
  bool useKg = true;
  bool notificationsEnabled = false;
  int restTimerSeconds = 90;
  int themeColorIndex = 0;

  SettingsManager() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? true;
    useKg = prefs.getBool('useKg') ?? true;
    notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    restTimerSeconds = prefs.getInt('restTimerSeconds') ?? 90;
    themeColorIndex = prefs.getInt('themeColorIndex') ?? 0;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> setUnit(bool isKg) async {
    useKg = isKg;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useKg', isKg);
  }

  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  Future<void> setRestTimer(int seconds) async {
    restTimerSeconds = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('restTimerSeconds', seconds);
  }

  Future<void> setThemeColor(int index) async {
    themeColorIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColorIndex', index);
  }
}

// Globale Instanz für den einfachen Zugriff
final settingsManager = SettingsManager();