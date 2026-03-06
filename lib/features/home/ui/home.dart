import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/common/version_check_service.dart';
import 'package:ado_dad_user/common/widgets/update_app_dialog.dart';
import 'package:ado_dad_user/features/home/ui/android_home_mobile.dart';
import 'package:ado_dad_user/features/home/ui/home_page.dart';
import 'package:ado_dad_user/features/home/ui/ios_home_mobile.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key, this.showLoginPromptForNotifications = false});

  final bool showLoginPromptForNotifications;

  @override
  Widget build(BuildContext context) {
    return _VersionCheckOnHome(
      child: DeviceChecker(
        showLoginPromptForNotifications: showLoginPromptForNotifications,
        androidTabletView: HomePage(showLoginPromptForNotifications: showLoginPromptForNotifications),
        androidMobileView: AndroidHomeMobile(showLoginPromptForNotifications: showLoginPromptForNotifications),
        iosTabletView: HomePage(showLoginPromptForNotifications: showLoginPromptForNotifications),
        iosMobileView: IosHomeMobile(showLoginPromptForNotifications: showLoginPromptForNotifications),
      ),
    );
  }
}

/// Runs version check once when home page is shown and displays update dialog if needed.
class _VersionCheckOnHome extends StatefulWidget {
  final Widget child;

  const _VersionCheckOnHome({required this.child});

  @override
  State<_VersionCheckOnHome> createState() => _VersionCheckOnHomeState();
}

class _VersionCheckOnHomeState extends State<_VersionCheckOnHome> {
  static bool _didCheckThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runVersionCheck());
  }

  Future<void> _runVersionCheck() async {
    if (_didCheckThisSession) return;
    _didCheckThisSession = true;
    try {
      final result = await VersionCheckService().check();
      if (!mounted) return;
      if (result.shouldPrompt) {
        showUpdateAppDialog(context, result: result);
      }
    } catch (_) {
      // Allow app to run on version check failure
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
