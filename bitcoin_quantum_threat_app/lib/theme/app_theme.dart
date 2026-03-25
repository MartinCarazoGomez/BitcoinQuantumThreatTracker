import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0a0f1a);
  static const surface = Color(0xFF111827);
  static const surface2 = Color(0xFF1e293b);
  static const amber = Color(0xFFf59e0b);
  static const amberLight = Color(0xFFfbbf24);
  static const text = Color(0xFFf1f5f9);
  static const muted = Color(0xFF94a3b8);
  static const quantum = Color(0xFF38bdf8);
  static const migration = Color(0xFF4ade80);
  static const risk = Color(0xFFf87171);
  static const accent = Color(0xFFa78bfa);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.amber,
      secondary: AppColors.amberLight,
      onSurface: AppColors.text,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface2.withValues(alpha: 0.6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.amber,
      inactiveTrackColor: AppColors.muted.withValues(alpha: 0.3),
      thumbColor: AppColors.amberLight,
      overlayColor: AppColors.amber.withValues(alpha: 0.2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface.withValues(alpha: 0.95),
      indicatorColor: AppColors.amber.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
      }),
    ),
  );
  return base;
}
