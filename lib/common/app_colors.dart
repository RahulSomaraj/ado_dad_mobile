import 'package:flutter/material.dart';

/// App color palette — Theme 1 "Trust Blue · Action Orange".
///
/// Roles (see docs/theme1_colour_checklist.md):
/// * brand blue — identity, fills of primary controls, selected states;
/// * action orange ([ctaColor]) — every primary action button, so actions
///   always stand apart from the blue brand surfaces;
/// * highlight amber ([highlight]) — Premium / Featured / Price-drop tags.
///
/// Surface and text colors are *brightness-aware*: they return light values in
/// light mode and dark equivalents in dark mode. Every screen already reads
/// them via `AppColors.whiteColor`, `AppColors.blackColor`, etc., so the whole
/// app follows the theme without touching individual widgets.
///
/// The active brightness is set once per frame by `MaterialApp.builder`
/// (see main.dart) from `Theme.of(context).brightness`, so these getters always
/// match the theme that is actually applied — including ThemeMode.system.
class AppColors {
  AppColors._();

  // ---- Active brightness (driven by the MaterialApp builder) ----
  static Brightness brightness = Brightness.light;
  static bool get isDark => brightness == Brightness.dark;

  // ---- Brand colors (constant in both themes) ----
  /// Brand blue used as a FILL (buttons, selected chips, badges) with white
  /// content on top — 6.7:1, passes AA in both themes. For brand-coloured
  /// text or icons on a surface use [brandText], which lightens on dark.
  static const Color primaryColor = Color(0xFF1D4ED8);
  static const Color redColor = Color(0xFFC62828);
  static const Color greyColor2 = Colors.black26;

  // ---- Theme 1 raw tokens (light / dark) ----
  static const Color brandTextDark = Color(0xFF9DBBFF);
  static const Color ctaLight = Color(0xFFCC4409);
  static const Color ctaDark = Color(0xFFFF7A3D);
  static const Color highlightLight = Color(0xFFFFC53D);
  static const Color highlightDark = Color(0xFFFFD166);
  static const Color navy = Color(0xFF0B1F44);

  // ---- Light-mode tokens (kept for reference / direct use) ----
  static const Color lightSurface = Colors.white;
  static const Color lightBlack = Color(0xFF0B1F44);
  static const Color lightBlack1 = Color(0xFF1E2A44);
  static const Color lightGrey = Color(0xFF5B6478);

  // ---- Dark-mode tokens ----
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF151D30);
  static const Color darkText = Color(0xFFE8EDF7);
  static const Color darkText1 = Color(0xFFD6DDEB);
  static const Color darkGrey = Color(0xFFC2CBDB);

  // ---- Brightness-aware semantic getters (names preserved for back-compat) ----

  /// Surfaces / cards / scaffolds (was a const `Colors.white`).
  static Color get whiteColor => isDark ? darkSurface : lightSurface;

  /// Primary text / strong foreground — navy ink in light mode.
  static Color get blackColor => isDark ? darkText : lightBlack;

  /// Secondary text.
  static Color get blackColor1 => isDark ? darkText1 : lightBlack1;

  /// Borders / icons / de-emphasised text.
  static Color get greyColor => isDark ? darkGrey : lightGrey;

  // ---- Helpers for new code ----
  static Color get scaffoldBackground =>
      isDark ? darkBackground : const Color(0xFFF5F7FB);
  static Color get cardColor => whiteColor;
  static Color get dividerColor =>
      isDark ? const Color(0xFF263049) : const Color(0xFFE3E7F0);
  static Color get onPrimary => Colors.white; // text/icons on the blue brand

  /// Brand-coloured TEXT and ICONS on a surface: #1D4ED8 in light (6.7:1 on
  /// white), #9DBBFF in dark (8.8:1 on the dark card).
  static Color get brandText => isDark ? brandTextDark : primaryColor;

  /// Action orange — the fill of every primary action button (Sell, Call,
  /// Post ad, Login, Save, Apply filters, Retry…). Brand blue stays for
  /// identity surfaces, selection and links.
  static Color get ctaColor => isDark ? ctaDark : ctaLight;

  /// Content on [ctaColor]: white in light (4.8:1), near-black in dark (7.2:1).
  static Color get onCta => isDark ? const Color(0xFF121212) : Colors.white;

  /// Amber for Premium / Featured / Price-drop tags.
  static Color get highlight => isDark ? highlightDark : highlightLight;

  /// Text on [highlight].
  static Color get onHighlight => isDark ? const Color(0xFF121212) : navy;

  /// Small meta text (place, "12 km away", "3w ago", chat times) — darker
  /// than [textMuted] so tiny text stays clearly readable. 9.8:1 on white.
  static Color get textMeta =>
      isDark ? const Color(0xFFD0D7E5) : const Color(0xFF334061);

  /// Muted text that passes WCAG AA on the card in both themes.
  static Color get textMuted => isDark ? darkGrey : const Color(0xFF3F4A63);

  /// Green for positive *text* (document checks, price drop).
  static Color get positiveText =>
      isDark ? const Color(0xFF4ADE9A) : const Color(0xFF12805A);

  /// Soft chip / tile fill on a section surface.
  static Color get chipFill =>
      isDark ? const Color(0xFF1C2538) : const Color(0xFFEEF2F8);

  /// Tint behind brand-coloured notes (safety tip, avatar initial).
  static Color get primarySoft =>
      isDark ? const Color(0xFF1C2A4A) : const Color(0xFFE3ECFB);

  /// Status green (Live pill, call icon).
  static const Color successColor = Color(0xFF12805A);
}
