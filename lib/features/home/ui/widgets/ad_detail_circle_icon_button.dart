import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class AdDetailCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const AdDetailCircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 36,
          tablet: 48,
          largeTablet: 56,
          desktop: 64,
        ),
        width: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 36,
          tablet: 48,
          largeTablet: 56,
          desktop: 64,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 20,
            tablet: 26,
            largeTablet: 30,
            desktop: 34,
          ),
        ),
      ),
    );
  }
}
