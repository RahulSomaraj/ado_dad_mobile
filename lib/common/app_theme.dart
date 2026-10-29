import 'package:ado_dad_user/common/app_fonts.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';

/// Centralized light & dark themes built from Theme 1 "Trust Blue · Action
/// Orange" (brand #1D4ED8, CTA #CC4409, danger #C62828) plus Plus Jakarta Sans type (see app_fonts.dart). Component themes here give
/// every screen a consistent, less "awkward" look: rounded cards, soft inputs,
/// pill buttons, themed app bar and bottom navigation — in both modes.
class AppTheme {
  AppTheme._();

  static const Color _primary = AppColors.primaryColor;
  static const Color _danger = AppColors.redColor;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color scaffold =
        isDark ? AppColors.darkBackground : const Color(0xFFF5F7FB);
    final Color surface = isDark ? AppColors.darkSurface : Colors.white;
    final Color textPrimary =
        isDark ? AppColors.darkText : AppColors.lightBlack;
    final Color textSecondary =
        isDark ? AppColors.darkText1 : AppColors.lightBlack1;
    final Color border =
        isDark ? const Color(0xFF263049) : const Color(0xFFE3E7F0);
    final Color muted = isDark ? AppColors.darkGrey : AppColors.lightGrey;
    // Brand-coloured text/icons/focus rings lighten on dark so they stay readable.
    final Color brandText = isDark ? AppColors.brandTextDark : _primary;
    final Color cta = isDark ? AppColors.ctaDark : AppColors.ctaLight;
    final Color onCta = isDark ? const Color(0xFF121212) : Colors.white;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: brightness,
    ).copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _primary,
      onSecondary: Colors.white,
      error: _danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    );

    final TextTheme baseText = appFontTextTheme(
            isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
        .apply(bodyColor: textPrimary, displayColor: textPrimary);

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: surface,
      dividerColor: border,
      primaryColor: _primary,
      fontFamily: appFont().fontFamily,
      textTheme: baseText,
      iconTheme: IconThemeData(color: textSecondary),
      splashColor: _primary.withValues(alpha: 0.08),
      highlightColor: _primary.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: appFont(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: textSecondary),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(brandText, 1.5),
        errorBorder: inputBorder(_danger),
        focusedErrorBorder: inputBorder(_danger, 1.5),
      ),
      // Every filled action button (Login, Save, Apply, Post, Retry…) uses the
      // action orange so actions stand apart from the blue brand surfaces.
      // Outlined = secondary, text buttons = links (brand blue).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cta,
          foregroundColor: onCta,
          disabledBackgroundColor: border,
          disabledForegroundColor: muted,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          textStyle:
              appFont(fontSize: 15, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cta,
          foregroundColor: onCta,
          minimumSize: const Size.fromHeight(50),
          textStyle: appFont(fontSize: 15, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        // Secondary actions: action-orange outline + label. (Cancel /
        // dismiss buttons that set a grey border keep it.)
        style: OutlinedButton.styleFrom(
          foregroundColor: cta,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: cta, width: 1.4),
          textStyle:
              appFont(fontSize: 15, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        // Text buttons (dialog actions, "Retry", "Clear"…) in action orange.
        style: TextButton.styleFrom(foregroundColor: cta),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: _primary,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: brandText,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // The only FAB is Sell, which is an action (orange) control.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cta,
        foregroundColor: onCta,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
      ),
    );
  }
}
