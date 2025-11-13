import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class SectionTitleWidget extends StatelessWidget {
  final String title;

  const SectionTitleWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextstyle.sectionTitleTextStyle.copyWith(
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: AppTextstyle.sectionTitleTextStyle.fontSize ?? 18,
          tablet: 22,
          largeTablet: 26,
          desktop: 30,
        ),
      ),
    );
  }
}
