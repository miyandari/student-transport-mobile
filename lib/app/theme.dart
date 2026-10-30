import 'package:flutter/material.dart';

class HammasirTheme {
  static const Color primary = Color(0xFF087F8C);
  static const Color background = Color(0xFFF7F9FA);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
      ),
      scaffoldBackgroundColor: background,
    );
  }
}