import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const emerald50 = Color(0xFFEDFDF5);
  static const emerald100 = Color(0xFFD3F9E2);
  static const emerald200 = Color(0xFFAAF0CE);
  static const emerald500 = Color(0xFF1FB578);
  static const emerald600 = Color(0xFF0E7C5A);
  static const emerald700 = Color(0xFF0A6147);
  static const emerald800 = Color(0xFF074D38);
  static const emerald900 = Color(0xFF053A2A);
  static const emerald950 = Color(0xFF022B1F);

  static const cream50 = Color(0xFFFEFDFB);
  static const cream100 = Color(0xFFFDF9F0);

  // Rich gold, not the lighter website amber — this is the luxury accent
  static const gold500 = Color(0xFFC9A227);
  static const gold600 = Color(0xFFAB8A1F);

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: emerald800,
      onPrimary: Colors.white,
      secondary: gold500,
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: cream50,
      onSurface: emerald950,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cream50,
      textTheme: GoogleFonts.interTextTheme(),
      primaryColor: emerald800,

      appBarTheme: AppBarTheme(
        backgroundColor: cream50,
        foregroundColor: emerald950,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: emerald950,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: emerald800),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: emerald800, width: 1.5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cream100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emerald700, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold500, width: 2),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: emerald800,
          side: const BorderSide(color: emerald800, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: emerald950,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emerald800,
        foregroundColor: Colors.white,
        extendedTextStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: emerald800,
        unselectedLabelColor: Colors.grey,
        indicatorColor: gold500,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: emerald800,
          selectedForegroundColor: Colors.white,
        ),
      ),

      iconTheme: const IconThemeData(color: emerald800),
    );
  }
}
