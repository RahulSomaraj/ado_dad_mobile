import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized light & dark themes built from the existing brand palette
/// (primary #4F48EC, red #F05555) plus Poppins type. Component themes here give
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
        isDark ? AppColors.darkBackground : const Color(0xFFF6F7FB);
    final Color surface = isDark ? AppColors.darkSurface : Colors.white;
    final Color textPrimary = isDark ? AppColors.darkText : AppColors.lightBlack;
    final Color textSecondary =
        isDark ? AppColors.darkText1 : AppColors.lightBlack1;
    final Color border =
        isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE6E8EE);
    final Color muted = isDark ? AppColors.darkGrey : AppColors.lightGrey;

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

    final TextTheme baseText =
        GoogleFonts.poppinsTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
            .apply(bodyColor: textPrimary, displayColor: textPrimary);

    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
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
      textTheme: baseText,
      iconTheme: IconThemeData(color: textSecondary),
      splashColor: _primary.withOpacity(0.08),
      highlightColor: _primary.withOpacity(0.05),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
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
        focusedBorder: inputBorder(_primary, 1.5),
        errorBorder: inputBorder(_danger),
        focusedErrorBorder: inputBorder(_danger, 1.5),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: border),
          textStyle:
              GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _primary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: _primary,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: _primary,
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
      ),
    );
  }
}
