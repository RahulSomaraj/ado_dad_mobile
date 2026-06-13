import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Flat floating bottom navigation: Home · Favorites · Sell (raised) · Chat ·
/// Profile. Active tab is detected from the current route and highlighted in
/// the brand colour. Placed as the screen's floatingActionButton (centerDocked).
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - 24;
    String current = '';
    try {
      current = GoRouterState.of(context).uri.path;
    } catch (_) {}
    return Container(
      width: width,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(context, current,
              icon: Icons.home_rounded, label: 'Home', route: '/home'),
          _navItem(context, current,
              icon: Icons.favorite_border,
              label: 'Favorites',
              route: '/wishlist'),
          _sellButton(context),
          _navItem(context, current,
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              route: '/chat-rooms?from=profile'),
          _navItem(context, current,
              icon: Icons.person_outline,
              label: 'Profile',
              route: '/profile'),
        ],
      ),
    );
  }

  bool _isActive(String current, String route) =>
      current == route.split('?').first;

  Widget _navItem(
    BuildContext context,
    String current, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final bool active = _isActive(current, route);
    final Color color = active ? AppColors.primaryColor : AppColors.greyColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(context, route),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sellButton(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(context, '/seller'),
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _go(BuildContext context, String route) async {
    final publicRoutes = ['/home', '/search'];
    final isPublicRoute = publicRoutes.any((r) => route.startsWith(r));
    if (isPublicRoute) {
      if (route.contains('/chat-rooms')) {
        context.go(route);
      } else {
        context.push(route);
      }
      return;
    }
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!context.mounted) return;
    if (isAuthenticated) {
      if (route.contains('/chat-rooms')) {
        context.go(route);
      } else {
        context.push(route);
      }
    } else {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to access this feature.",
        redirectPath: route.split('?').first,
      );
    }
  }
}
