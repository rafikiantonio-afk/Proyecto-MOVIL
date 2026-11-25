import 'package:flutter/material.dart';

// colores parecidos a la interfaz de la usm
class AppTheme {
  static const Color primaryBlue = Color(0xFF005B9A);
  static const Color backgroundLight = Color(0xFFF5F7FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}