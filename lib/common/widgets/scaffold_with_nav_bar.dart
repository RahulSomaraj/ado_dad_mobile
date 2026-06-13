import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent shell that hosts the four primary tabs (Home · My Activity ·
/// Chat · Profile) with a floating pill nav and a raised centre Sell action.
/// The nav stays mounted while branches switch, preserving each tab's state.
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SafeArea(
        child: _ShellNavBar(navigationShell: navigationShell),
      ),
    );
  }
}

class _ShellNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _ShellNavBar({required this.navigationShell});

  // Branch order must match the StatefulShellRoute branches:
  // 0 = Home, 1 = My Activity, 2 = Chat, 3 = Profile.
  String _pathFor(int branchIndex) {
    switch (branchIndex) {
      case 1:
        return '/my-activity';
      case 2:
        return '/chat-rooms';
      case 3:
        return '/profile';
      default:
        return '/home';
    }
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again returns it to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _select(BuildContext context, int branchIndex,
      {required bool protected}) async {
    if (!protected) {
      _goBranch(branchIndex);
      return;
    }
    final authed = await AuthGuard.isAuthenticated();
    if (!context.mounted) return;
    if (authed) {
      _goBranch(branchIndex);
    } else {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to access this feature.",
        redirectPath: _pathFor(branchIndex),
      );
    }
  }

  Future<void> _openSeller(BuildContext context) async {
    final authed = await AuthGuard.isAuthenticated();
    if (!context.mounted) return;
    if (authed) {
      context.push('/seller');
    } else {
      DialogUtil.showLoginPromptDialog(
        context,
        message: "Please login to post an ad.",
        redirectPath: '/seller',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - 24;
    final int current = navigationShell.currentIndex;
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
          _navItem(context,
              icon: Icons.home_rounded,
              label: 'Home',
              branchIndex: 0,
              current: current,
              protected: false),
          _navItem(context,
              icon: Icons.dashboard_customize_outlined,
              label: 'My Activity',
              branchIndex: 1,
              current: current,
              protected: true),
          _sellButton(context),
          _navItem(context,
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              branchIndex: 2,
              current: current,
              protected: true),
          _navItem(context,
              icon: Icons.person_outline,
              label: 'Profile',
              branchIndex: 3,
              current: current,
              protected: true),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int branchIndex,
    required int current,
    required bool protected,
  }) {
    final bool active = current == branchIndex;
    final Color color = active ? AppColors.primaryColor : AppColors.greyColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(context, branchIndex, protected: protected),
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
        onTap: () => _openSeller(context),
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
}
