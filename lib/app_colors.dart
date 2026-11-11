import 'package:flutter/material.dart';

/// Starts on the phone's own setting; the toggle button changes it.
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

/// True when the app is currently showing dark mode.
/// Reads the same switch the toggle button changes.
bool isDarkNow(BuildContext context) {
  switch (themeMode.value) {
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
      return false;
    case ThemeMode.system:
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}

class AppColors {
  final Color base; // the plain color behind the flowing bands
  final List<Color> bands; // the three flowing S-shaped bands
  final Color textPrimary;
  final Color textSecondary;
  final List<Shadow> textShadows; // makes text easier to read

  const AppColors._({
    required this.base,
    required this.bands,
    required this.textPrimary,
    required this.textSecondary,
    required this.textShadows,
  });

  static const light = AppColors._(
    base: Color(0xFFEAF5FF),
    bands: [Color(0xFF8EC5FF), Color(0xFFB3C6FF), Color(0xFFD6ECFF)],
    textPrimary: Color(0xFF2E5C9A),
    textSecondary: Color(0xFF5079AD),
    textShadows: [
      Shadow(color: Color(0x33081C3D), blurRadius: 6, offset: Offset(0, 1)),
    ],
  );

  static const dark = AppColors._(
    base: Color(0xFF050B1A),
    bands: [Color(0xFF123A9A), Color(0xFF1F5FD6), Color(0xFF0B2A6B)],
    textPrimary: Color(0xFFEAF3FF),
    textSecondary: Color(0xFFA8BEE0),
    textShadows: [],
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
