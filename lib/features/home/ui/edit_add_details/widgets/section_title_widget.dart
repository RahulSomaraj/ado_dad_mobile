import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

/// Uppercase section label (wireframe: docs/ado_dad_wireframes_missing_pages.html
/// → "Edit ad" grouped sections).
class SectionTitleWidget extends StatelessWidget {
  final String title;

  const SectionTitleWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 11.5,
          tablet: 14,
          largeTablet: 16,
          desktop: 18,
        ),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.greyColor,
      ),
    );
  }
}
