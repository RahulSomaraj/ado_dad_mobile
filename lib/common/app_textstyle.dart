import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextstyle {
  static TextStyle title1 = GoogleFonts.poppins(
      textStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.blackColor));

  static TextStyle buttonText = GoogleFonts.poppins(
      textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600));

  static TextStyle sectionTitleTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.blackColor);

  static TextStyle categoryLabelTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.blackColor);

  static TextStyle appbarText = GoogleFonts.poppins(
      fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.blackColor);

  static TextStyle sellCategoryText = GoogleFonts.poppins(
      fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.blackColor);

  static TextStyle changeCategoryButtonTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.primaryColor);
}
