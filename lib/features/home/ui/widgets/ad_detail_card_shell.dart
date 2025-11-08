import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class AdDetailCardShell extends StatelessWidget {
  final Widget child;

  const AdDetailCardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: GetResponsiveSize.getResponsiveSize(context,
            mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          GetResponsiveSize.getResponsiveBorderRadius(context,
              mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: GetResponsiveSize.getResponsiveSize(context,
                mobile: 10, tablet: 12, largeTablet: 14, desktop: 16),
            offset: Offset(
              0,
              GetResponsiveSize.getResponsiveSize(context,
                  mobile: 4, tablet: 5, largeTablet: 6, desktop: 7),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
