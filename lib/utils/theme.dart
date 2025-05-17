// lib/utils/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color accentColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFFE5E7EB);
  
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: cardColor,
        onSurface: textColor,
        onBackground: textColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: secondaryTextColor),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: secondaryTextColor),
      ),
    );
  }
}