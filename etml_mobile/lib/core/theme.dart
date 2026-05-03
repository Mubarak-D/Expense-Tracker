import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EtmlColors {
  static const background = Color(0xFF070B16);
  static const backgroundAlt = Color(0xFF0B1020);
  static const surface = Color(0xFF111827);
  static const surfaceLight = Color(0xFF182238);
  static const text = Color(0xFFF6F8FF);
  static const muted = Color(0xFFA7B0C4);
  static const blue = Color(0xFF75A7FF);
  static const violet = Color(0xFF9A8CFF);
  static const cyan = Color(0xFF57E0D3);
  static const warning = Color(0xFFFFB86B);
  static const danger = Color(0xFFFF6B86);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, violet],
  );
}

class EtmlTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.outfitTextTheme(
      base.textTheme,
    ).apply(bodyColor: EtmlColors.text, displayColor: EtmlColors.text);

    return base.copyWith(
      scaffoldBackgroundColor: EtmlColors.background,
      colorScheme: const ColorScheme.dark(
        primary: EtmlColors.blue,
        secondary: EtmlColors.cyan,
        surface: EtmlColors.surface,
        error: EtmlColors.danger,
      ),
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: EtmlColors.muted,
          height: 1.45,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        labelStyle: const TextStyle(color: EtmlColors.muted),
        hintStyle: TextStyle(color: EtmlColors.muted.withValues(alpha: 0.7)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: _fieldBorder(Colors.white.withValues(alpha: 0.08)),
        enabledBorder: _fieldBorder(Colors.white.withValues(alpha: 0.08)),
        focusedBorder: _fieldBorder(EtmlColors.blue.withValues(alpha: 0.85)),
        errorBorder: _fieldBorder(EtmlColors.danger),
        focusedErrorBorder: _fieldBorder(EtmlColors.danger),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: EtmlColors.surfaceLight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: EtmlColors.text,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: EtmlColors.cyan,
        linearTrackColor: EtmlColors.surfaceLight,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color),
    );
  }
}
