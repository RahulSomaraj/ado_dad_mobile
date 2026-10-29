import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

/// A single account-menu row in the Home card style: white rounded card, a
/// tinted round icon, a label and a chevron. [showDivider] is kept for
/// compatibility; cards are separated by spacing instead of hairlines.
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
    final Color accent = isLogout ? AppColors.redColor : AppColors.brandText;
    final Color tint = isLogout
        ? AppColors.redColor.withValues(alpha: 0.10)
        : AppColors.primarySoft;

    // Home-style card row: white rounded card, tinted round icon, chevron.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerColor),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 11,
                tablet: 16,
                largeTablet: 18,
                desktop: 20,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
                  child: Center(
                    child: SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: Image.asset(image, color: accent, fit: BoxFit.contain),
                    ),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isLogout ? AppColors.redColor : AppColors.blackColor,
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 14.5,
                        tablet: 20,
                        largeTablet: 24,
                        desktop: 26,
                      ),
                    ),
                  ),
                ),
                if (!isLogout)
                  Icon(
                    Icons.chevron_right_rounded,
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
          ),
        ),
      ),
    );
  }
}
