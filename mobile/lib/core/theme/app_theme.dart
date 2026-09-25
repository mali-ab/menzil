import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _ink = Color(0xFF101B32);
  static const _indigo = Color(0xFF182B4D);
  static const _mint = Color(0xFF20E38A);
  static const _surface = Color(0xFFF8F9FA);

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
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 52), backgroundColor: _mint, foregroundColor: _ink, textStyle: const TextStyle(fontWeight: FontWeight.w800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(primary: _mint, secondary: _mint, surface: Color(0xFF1D2430), onSurface: Color(0xFFF4F7FB)),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212), foregroundColor: Color(0xFFF4F7FB), elevation: 0),
    cardTheme: CardThemeData(color: const Color(0xFF1D2430), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), margin: EdgeInsets.zero),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF1D2430), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 52), backgroundColor: _mint, foregroundColor: _ink, textStyle: const TextStyle(fontWeight: FontWeight.w800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
  );
}
