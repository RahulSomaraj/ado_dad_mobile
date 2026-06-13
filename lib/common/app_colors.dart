import 'package:flutter/material.dart';

/// App color palette.
///
/// The brand colors (primary / red) are unchanged from the original palette.
/// The neutral "surface" and "text" colors are now *brightness-aware*: they
/// return the original light-mode values in light mode and dark equivalents in
/// dark mode. Because every existing screen already reads these via
/// `AppColors.whiteColor`, `AppColors.blackColor`, etc., the whole app gains
/// light/dark theming without touching individual widgets.
///
/// The active brightness is set once per frame by `MaterialApp.builder`
/// (see main.dart) from `Theme.of(context).brightness`, so these getters always
/// match the theme that is actually applied — including ThemeMode.system.
class AppColors {
  AppColors._();

  // ---- Active brightness (driven by the MaterialApp builder) ----
  static Brightness _brightness = Brightness.light;
  static set brightness(Brightness value) => _brightness = value;
  static Brightness get brightness => _brightness;
  static bool get isDark => _brightness == Brightness.dark;

  // ---- Brand colors (constant in both themes — existing palette) ----
  static const Color primaryColor = Color(0xFF4F48EC);
  static const Color redColor = Color(0xFFF05555);
  static const Color greyColor2 = Colors.black26;

  // ---- Original light-mode tokens (kept for reference / direct use) ----
  static const Color lightSurface = Colors.white;
  static const Color lightBlack = Color(0xFF0A0A0A);
  static const Color lightBlack1 = Color(0xFF424242);
  static const Color lightGrey = Color(0xFF959CA9);

  // ---- Dark-mode tokens (derived from the same palette, just darker) ----
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1B1F27);
  static const Color darkText = Color(0xFFECEEF3);
  static const Color darkText1 = Color(0xFFC2C7D0);
  static const Color darkGrey = Color(0xFF9AA1AF);

  // ---- Brightness-aware semantic getters (names preserved for back-compat) ----

  /// Surfaces / cards / scaffolds (was a const `Colors.white`).
  static Color get whiteColor => isDark ? darkSurface : lightSurface;

  /// Primary text / strong foreground (was a const near-black).
  static Color get blackColor => isDark ? darkText : lightBlack;

  /// Secondary text (was `0xFF424242`).
  static Color get blackColor1 => isDark ? darkText1 : lightBlack1;

  /// Muted text / borders (was `0xFF959CA9`).
  static Color get greyColor => isDark ? darkGrey : lightGrey;

  // ---- Helpers for new code ----
  static Color get scaffoldBackground =>
      isDark ? darkBackground : const Color(0xFFF6F7FB);
  static Color get cardColor => whiteColor;
  static Color get dividerColor =>
      isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EE);
  static Color get onPrimary => Colors.white; // text/icons on the purple brand
}
