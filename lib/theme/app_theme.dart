import 'package:flutter/material.dart';

/// Colors copied 1:1 from the original site's `:root` CSS variables,
/// so the Flutter app keeps the same "paper & ink" DSP-lab look.
class AppColors {
  AppColors._();
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A2430);
  static const ink2 = Color(0xFF4A5666);
  static const ink3 = Color(0xFF7A8594);
  static const rule = Color(0xFFE2E7ED);
  static const grid = Color(0xFFEDF1F5);
  static const panel = Color(0xFFF7F9FB);

  static const blue = Color(0xFF1D5FD1);
  static const blueSoft = Color(0xFFE7EFFC);
  static const rasp = Color(0xFFB0305C);
  static const raspSoft = Color(0xFFF8E8EE);
  static const green = Color(0xFF0B7F62);
  static const greenSoft = Color(0xFFE3F3EE);
  static const amber = Color(0xFFD99A0B);
  static const amberSoft = Color(0xFFFDF4DD);
  static const teal = Color(0xFF1F7A8C);
  static const gray = Color(0xFF9AA5B1);
  static const errorRed = Color(0xFFB3261E);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.blue,
        secondary: AppColors.rasp,
        surface: AppColors.paper,
        error: AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.rule),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.rule, thickness: 1),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.blue,
        thumbColor: AppColors.blue,
        overlayColor: AppColors.blue.withValues(alpha: 0.15),
        inactiveTrackColor: AppColors.grid,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCDD5DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCDD5DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.paper;
            return const Color(0xFFE9EDF2);
          }),
          foregroundColor: WidgetStateProperty.all(AppColors.ink),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.ink3,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  /// Monospace style used for numeric readouts (mirrors --num font stack).
  static const numStyle = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
    fontFamily: 'monospace',
  );

  /// Italic serif-ish style used for math (mirrors --math font stack).
  static const mathStyle = TextStyle(fontStyle: FontStyle.italic);
}
