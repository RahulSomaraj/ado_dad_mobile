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
}
