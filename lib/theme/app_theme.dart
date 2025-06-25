import 'package:flutter/material.dart';

class AppTheme {
  static const gradient = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFBF360C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'SF Pro',   // o il tuo font
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE64A19)),
      inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x33FFFFFF),
      hintStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    ),
  );
}
