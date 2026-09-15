import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared text styles. These are getters (not `final` fields) so that the
/// brightness-aware `AppColors` values are re-evaluated every time a style is
/// used — that's what lets text flip correctly between light and dark themes.
class AppTextstyle {
  static TextStyle get title1 => GoogleFonts.poppins(
      textStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.blackColor));

  static TextStyle get buttonText => GoogleFonts.poppins(
      textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600));

  static TextStyle get sectionTitleTextStyle => GoogleFonts.poppins(
      fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.blackColor);

  static TextStyle get categoryLabelTextStyle => GoogleFonts.poppins(
      fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.blackColor);

  static TextStyle get appbarText => GoogleFonts.poppins(
      fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.blackColor);

  static TextStyle get sellCategoryText => GoogleFonts.poppins(
      fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.blackColor);

  static TextStyle get changeCategoryButtonTextStyle => GoogleFonts.poppins(
      fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.primaryColor);

  // ---- Detail-screen scale (sizes are phone sp; see AppSpacing.s for tablet) ----
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// ₹4,85,000 — 26/32 w700, tabular digits.
  static TextStyle get priceLarge => GoogleFonts.poppins(
      fontSize: 26,
      height: 32 / 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: AppColors.blackColor,
      fontFeatures: _tabular);

  /// Card price — 14 w700.
  static TextStyle get priceSmall => GoogleFonts.poppins(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w700,
      color: AppColors.blackColor,
      fontFeatures: _tabular);

  /// Section heading — 16/24 w600.
  static TextStyle get sectionTitle => GoogleFonts.poppins(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      color: AppColors.blackColor);

  /// Ad title under the price — 15/22 w500.
  static TextStyle get titleMedium => GoogleFonts.poppins(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w500,
      color: AppColors.blackColor);

  /// Running text — 14/22 w400.
  static TextStyle get bodyText => GoogleFonts.poppins(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w400,
      color: AppColors.blackColor1);

  /// Table value — 14 w500, tabular.
  static TextStyle get specValue => GoogleFonts.poppins(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: AppColors.blackColor,
      fontFeatures: _tabular);

  /// Table label — 13 w400 muted.
  static TextStyle get specLabel => GoogleFonts.poppins(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted);

  /// Meta line / captions — 12.5 w400 muted.
  static TextStyle get caption => GoogleFonts.poppins(
      fontSize: 12.5,
      height: 18 / 12.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted);

  /// Smallest allowed text — 11 w400 muted.
  static TextStyle get micro => GoogleFonts.poppins(
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted);

  /// Button label — 14.5 w600.
  static TextStyle get button => GoogleFonts.poppins(
      fontSize: 14.5, height: 20 / 14.5, fontWeight: FontWeight.w600);
}
