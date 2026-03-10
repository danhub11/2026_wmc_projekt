import 'package:flutter/material.dart';

class AppConstants {
  // API Base URL
  static const String baseUrl = 'http://localhost:3000/api';

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Light Mode Colors
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color cardLight = Color(0xFFFFFFFF);

  // 5 Theme Colors
  static const Color themeOrange = Color(0xFFF27A4D);
  static const Color themeBlue = Color(0xFF4D94F2);
  static const Color themeGreen = Color(0xFF34C759);
  static const Color themePurple = Color(0xFF944DF2);
  static const Color themeRed = Color(0xFFF24D4D);

  // Fallback für alte Referenzen im Code
  static const Color primaryOrange = themeOrange;

  static const List<Color> themeColors = [
    themeOrange,
    themeBlue,
    themeGreen,
    themePurple,
    themeRed,
  ];

  static const List<String> themeNames = [
    'Sunset',
    'Ocean',
    'Forest',
    'Royal',
    'Ruby',
  ];

  static const List<IconData> themeIcons = [
    Icons.wb_sunny_outlined,
    Icons.water_outlined,
    Icons.forest_outlined,
    Icons.auto_awesome_outlined,
    Icons.favorite_outline,
  ];

  static ThemeData getTheme({
    required Color primaryColor,
    required bool isDarkMode,
  }) {
    if (isDarkMode) {
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundDark,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: primaryColor,
          surface: cardDark,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.grey),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
        dividerColor: Colors.white10,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: backgroundDark,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardDark,
          labelStyle: const TextStyle(color: Colors.grey),
          selectedColor: primaryColor.withValues(alpha: 0.2),
          side: BorderSide.none,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: backgroundDark,
          textStyle: TextStyle(color: Colors.white),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(backgroundDark),
          ),
        ),
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundLight,
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundLight,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
          titleTextStyle: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: primaryColor,
          surface: cardLight,
          onSurface: const Color(0xFF1C1C1E),
          onBackground: const Color(0xFF1C1C1E),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1C1C1E)),
          bodyMedium: TextStyle(color: Color(0xFF3C3C43)),
          bodySmall: TextStyle(color: Color(0xFF8E8E93)),
          titleLarge: TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(color: Color(0xFF1C1C1E)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE5E5EA),
          hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
          labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFC7C7CC)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
        dividerColor: const Color(0xFFE5E5EA),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: cardLight,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF8E8E93),
          elevation: 8,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE5E5EA),
          labelStyle: const TextStyle(color: Color(0xFF3C3C43)),
          selectedColor: primaryColor.withValues(alpha: 0.15),
          side: BorderSide.none,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: cardLight,
          textStyle: TextStyle(color: Color(0xFF1C1C1E)),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(cardLight),
          ),
        ),
        cardColor: cardLight,
        dialogTheme: const DialogThemeData(backgroundColor: cardLight),
      );
    }
  }
}
