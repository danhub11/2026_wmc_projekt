import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'http://localhost:3000/api';

  // Farben
  static const Color primaryOrange = Color(0xFFF27A4D);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Theme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryOrange,
    colorScheme: const ColorScheme.dark(
      primary: primaryOrange,
      surface: cardDark,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundDark,
      selectedItemColor: primaryOrange,
      unselectedItemColor: Colors.grey,
    ),
  );
}
