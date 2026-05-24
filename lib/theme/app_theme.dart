import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark(Color accent, double fontSizeScale) {
    final textTheme = GoogleFonts.dmMonoTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF141414),
        primary: accent,
        secondary: accent,
      ),
      textTheme: textTheme.apply(fontSizeFactor: fontSizeScale),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A0A),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF141414),
        selectedItemColor: accent,
        unselectedItemColor: const Color(0xFF666666),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141414),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ThemeData light(Color accent, double fontSizeScale) {
    final textTheme = GoogleFonts.dmMonoTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F0),
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFFFFFFF),
        primary: accent,
        secondary: accent,
      ),
      textTheme: textTheme.apply(fontSizeFactor: fontSizeScale),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F0),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF0A0A0A),
        unselectedItemColor: const Color(0xFF999999),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
