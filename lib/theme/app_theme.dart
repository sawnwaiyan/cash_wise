import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────────
  static const Color navy        = Color(0xFF0D1B2A);
  static const Color navyCard    = Color(0xFF1A2D42);
  static const Color navyLight   = Color(0xFF243B55);
  static const Color amber       = Color(0xFFFFC107);
  static const Color amberLight  = Color(0xFFFFD54F);
  static const Color textPrimary = Color(0xFFECEFF1);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color danger      = Color(0xFFEF5350);
  static const Color warning     = Color(0xFFFFB300);
  static const Color success     = Color(0xFF66BB6A);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy,
      colorScheme: const ColorScheme.dark(
        primary:    amber,
        secondary:  amberLight,
        surface:    navyCard,
        onPrimary:  Colors.black,
        onSecondary: Colors.black,
        onSurface:  textPrimary,
        error:      danger,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor:  navy,
        foregroundColor:  textPrimary,
        elevation:        0,
        centerTitle:      false,
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),

      // BottomNav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      navyCard,
        selectedItemColor:    amber,
        unselectedItemColor:  textSecondary,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Cards
      cardTheme: CardThemeData(
        color:        navyCard,
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor:   amber,
        foregroundColor:   Colors.black,
        elevation:         6,
        shape: CircleBorder(),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   navyLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: amber, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle:  const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: Colors.black,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize:   15,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: amber),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor:        navyLight,
        selectedColor:          amber,
        labelStyle:             const TextStyle(color: textPrimary, fontSize: 13),
        secondaryLabelStyle:    const TextStyle(color: Colors.black, fontSize: 13),
        padding:                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color:     navyLight,
        thickness: 1,
        space:     1,
      ),

      // Text
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textPrimary,   fontWeight: FontWeight.w700),
        titleLarge:     TextStyle(color: textPrimary,   fontWeight: FontWeight.w600),
        titleMedium:    TextStyle(color: textPrimary,   fontWeight: FontWeight.w500),
        bodyLarge:      TextStyle(color: textPrimary),
        bodyMedium:     TextStyle(color: textSecondary),
        labelSmall:     TextStyle(color: textSecondary, fontSize: 11),
      ),
    );
  }
}