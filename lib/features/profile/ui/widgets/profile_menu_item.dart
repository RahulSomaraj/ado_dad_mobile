import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

/// A single account-menu row styled to the wireframe: a rounded square icon
/// box, a label, and a chevron, with a hairline divider beneath.
class ProfileMenuItem extends StatelessWidget {
  final String image;
  final String title;
  final bool isLogout;
  final bool showDivider;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.image,
    required this.title,
    this.isLogout = false,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double boxSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 40,
      tablet: 60,
      largeTablet: 68,
      desktop: 74,
    );
    final double iconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 20,
      tablet: 32,
      largeTablet: 36,
      desktop: 40,
    );
    final double gap = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 12,
      tablet: 16,
      largeTablet: 18,
      desktop: 20,
    );
    final Color accent =
        isLogout ? AppColors.redColor : AppColors.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 9,
              tablet: 16,
              largeTablet: 20,
              desktop: 22,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: boxSize,
                    height: boxSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isLogout
                          ? AppColors.redColor.withOpacity(0.10)
                          : (AppColors.isDark
                              ? Colors.white10
                              : const Color(0xFFF1F2F6)),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: Image.asset(
                          image,
                          color: accent,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isLogout
                            ? AppColors.redColor
                            : AppColors.blackColor,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 20,
                          largeTablet: 24,
                          desktop: 26,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 22,
                      tablet: 28,
                      largeTablet: 32,
                      desktop: 34,
                    ),
                    color: AppColors.greyColor,
                  ),
                ],
              ),
              if (showDivider)
                Padding(
                  padding: EdgeInsets.only(
                    top: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 9,
                      tablet: 16,
                      largeTablet: 20,
                      desktop: 22,
                    ),
                  ),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.dividerColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
