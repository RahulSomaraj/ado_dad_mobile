/// Spacing and corner-radius tokens.
///
/// A single small scale so screens stop inventing one-off `SizedBox(height: 7)`
/// and `EdgeInsets.all(13)` values. Everything is a plain `const double`, so
/// these can be used in `const` constructors:
///
/// ```dart
/// const SizedBox(height: AppSpacing.md);
/// const EdgeInsets.symmetric(horizontal: AppSpacing.lg);
/// BorderRadius.circular(AppRadius.card);
/// ```
///
/// Pure Dart — no Flutter imports.
library;

/// The 4-point spacing scale used for gaps, padding and margins.
class AppSpacing {
  AppSpacing._();

  /// 4 — hairline gaps, icon-to-label spacing inside a chip.
  static const double xs = 4;

  /// 8 — tight gaps between closely related elements.
  static const double sm = 8;

  /// 12 — default inner padding of small surfaces (chips, list tiles).
  static const double md = 12;

  /// 16 — default screen/card padding and the gap between siblings.
  static const double lg = 16;

  /// 24 — gap between distinct sections.
  static const double xl = 24;

  /// 32 — page-level breathing room, e.g. above a trailing CTA.
  static const double xxl = 32;
}

/// Corner radii. These mirror the values already declared in
/// `app_theme.dart`, so widgets that build their own container instead of
/// using `Card`/`ElevatedButton` still match the theme.
class AppRadius {
  AppRadius._();

  /// 16 — cards and surfaces (matches `cardTheme.shape` in `app_theme.dart`).
  static const double card = 16;

  /// 12 — text fields (matches `inputDecorationTheme` borders).
  static const double input = 12;

  /// 12 — elevated / outlined buttons (matches both button themes).
  static const double button = 12;

  /// 20 — pill-shaped chips (matches `chipTheme.shape`).
  static const double chip = 20;

  /// 20 — top corners of a bottom sheet (matches `bottomSheetTheme`).
  static const double sheet = 20;

  /// 16 — dialogs (matches `dialogTheme.shape`).
  static const double dialog = 16;

  /// 8 — small inner elements such as thumbnails and badges.
  static const double small = 8;
}
