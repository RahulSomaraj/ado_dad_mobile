import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const double _vPad = 10;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalMargin = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 0,
      tablet: 24,
      largeTablet: 32,
      desktop: 40,
    );
    final double barWidth = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 300,
      tablet: screenWidth - (horizontalMargin * 2),
      largeTablet: screenWidth - (horizontalMargin * 2),
      desktop: screenWidth - (horizontalMargin * 2),
    );
    final double barHeight = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 60,
      tablet: 80,
      largeTablet: 85,
      desktop: 90,
    );
    final double baseIconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 20,
      tablet: 35,
      largeTablet: 40,
      desktop: 40,
    );
    final double addIconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 36,
      tablet: 50,
      largeTablet: 50,
      desktop: 54,
    );
    return Container(
      height: barHeight,
      width: barWidth,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: _vPad,
            tablet: 15,
            largeTablet: 17,
            desktop: 17,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, 'assets/images/home-icon.png', '/home',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/search-icon.png',
                '/search?from=/profile',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/seller-icon.png', '/seller',
                iconSize: addIconSize),
            _navItem(context, 'assets/images/chat-icon.png',
                '/chat-rooms?from=profile',
                iconSize: baseIconSize),
            _navItem(context, 'assets/images/profile-icon.png', '/profile',
                iconSize: baseIconSize),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String image,
    String? route, {
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: () async {
        if (route == null) return;

        // Routes that don't require authentication
        final publicRoutes = ['/home', '/search'];
        final isPublicRoute = publicRoutes.any((r) => route.startsWith(r));

        if (isPublicRoute) {
          // Allow navigation without authentication
          if (route.contains('/chat-rooms')) {
            context.go(route);
          } else {
            context.push(route);
          }
        } else {
          // Protected routes - check authentication
          final isAuthenticated = await AuthGuard.isAuthenticated();
          if (isAuthenticated) {
            // User is authenticated, allow navigation
            if (route.contains('/chat-rooms')) {
              context.go(route);
            } else {
              context.push(route);
            }
          } else {
            // User is not authenticated, show login prompt
            final routePath =
                route.split('?').first; // Remove query params for redirect
            DialogUtil.showLoginPromptDialog(
              context,
              message: "Please login to access this feature.",
              redirectPath: routePath,
            );
          }
        }
      },
      child: Center(
        // Fix the rendered size exactly
        child: SizedBox.square(
          dimension: iconSize,
          child: Image.asset(
            image,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
