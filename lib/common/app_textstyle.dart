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

  // ---------------------------------------------------------------------------
  // Content roles (added for the ad-detail rebuild).
  //
  // Same conventions as the styles above: static getters (never `final`) so the
  // brightness-aware `AppColors` values are re-read on every use, Poppins via
  // `GoogleFonts`, and no `BuildContext` — this file intentionally does not use
  // `GetResponsiveSize`; call sites that need responsive sizing should
  // `.copyWith(fontSize: ...)` on top of these.
  // ---------------------------------------------------------------------------

  /// Hero price on the ad-detail page. Tabular figures keep the digits from
  /// shifting when a price animates or is swapped between listings.
  static TextStyle get priceLarge => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.5,
          color: AppColors.blackColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  /// Price on a listing card.
  static TextStyle get priceMedium => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.blackColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  /// Price in a dense context — similar-ads rail, compact list rows.
  static TextStyle get priceSmall => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.blackColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  /// Listing / card title.
  static TextStyle get titleMedium => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: AppColors.blackColor,
        ),
      );

  /// Default running text — descriptions, paragraphs, sheet bodies.
  static TextStyle get bodyText => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: AppColors.blackColor1,
        ),
      );

  /// Secondary metadata — posted date, location, view count.
  static TextStyle get caption => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          color: AppColors.greyColor,
        ),
      );

  /// Micro-label, intended for UPPERCASE section eyebrows and badges.
  /// The tracking is ~0.05em at this size.
  static TextStyle get label => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.greyColor,
        ),
      );

  /// The value half of a spec row ("Petrol", "42,300 km").
  static TextStyle get specValue => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.blackColor,
        ),
      );

  /// The label half of a spec row ("Fuel type", "Kms driven").
  static TextStyle get specLabel => GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.greyColor,
        ),
      );
}
