import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF258CF4);
  static const Color backgroundColor = Color(0xFFF5F8FF);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A2340);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color goodAqi = Color(0xFF4CAF50);
  static const Color warningAqi = Color(0xFFFFC107);
  static const Color dangerAqi = Color(0xFFF44336);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textPrimary,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
