import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final String image;
  final String title;
  final bool isLogout;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    super.key,
    required this.image,
    required this.title,
    this.isLogout = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 10,
              tablet: 24,
              largeTablet: 28,
              desktop: 32,
            ),
          ),
          child: ListTile(
            leading: Builder(builder: (context) {
              final double boxSize = GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 44,
                tablet: 70,
                largeTablet: 75,
                desktop: 80,
              );
              return SizedBox(
                width: boxSize,
                height: boxSize,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isLogout ? Colors.red[50] : Colors.grey[200],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 24,
                        tablet: 38,
                        largeTablet: 42,
                        desktop: 46,
                      ),
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 24,
                        tablet: 38,
                        largeTablet: 42,
                        desktop: 46,
                      ),
                      child: Image.asset(
                        image,
                        color: isLogout
                            ? AppColors.redColor
                            : AppColors.primaryColor,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLogout ? Colors.red : Colors.black,
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 24,
                  largeTablet: 26,
                  desktop: 26,
                ),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 18,
                tablet: 24,
                largeTablet: 26,
                desktop: 28,
              ),
              color: Colors.grey,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
