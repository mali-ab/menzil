import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF0F172A);
  static const green = Color(0xFF0F766E);
  static const greenSoft = Color(0xFFE8F5F1);
  static const orange = Color(0xFFF59E0B);
  static const surface = Color(0xFFF7FAF9);

  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      secondary: orange,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE5EEEC))),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFBFDFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE9E5)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: greenSoft, labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 54), backgroundColor: green, foregroundColor: Colors.white, elevation: 0, textStyle: const TextStyle(fontWeight: FontWeight.w800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(primary: Color(0xFF34D399), secondary: orange, surface: Color(0xFF1D2430), onSurface: Color(0xFFF4F7FB)),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212), foregroundColor: Color(0xFFF4F7FB), elevation: 0),
    cardTheme: CardThemeData(color: const Color(0xFF1D2430), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), margin: EdgeInsets.zero),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF1D2430), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 52), backgroundColor: const Color(0xFF34D399), foregroundColor: ink, textStyle: const TextStyle(fontWeight: FontWeight.w800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
  );
}
