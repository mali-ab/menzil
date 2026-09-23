import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _ink = Color(0xFF16213E);
  static const _indigo = Color(0xFF4F46E5);
  static const _mint = Color(0xFF11B981);
  static const _surface = Color(0xFFF7F8FC);

  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _indigo,
      primary: _indigo,
      secondary: _mint,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _surface,
      foregroundColor: _ink,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
