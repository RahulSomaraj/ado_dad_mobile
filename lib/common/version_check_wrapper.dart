import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/version_check_service.dart';
import 'package:ado_dad_user/common/widgets/update_app_dialog.dart';
import 'package:flutter/material.dart';

/// Runs a version check when the app is online and shows update dialog if needed.
/// Place inside [StartupConnectivityGate] so it runs only when internet is available.
class VersionCheckWrapper extends StatefulWidget {
  final Widget child;

  const VersionCheckWrapper({super.key, required this.child});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
  }

  Future<void> _runCheck() async {
    if (_checked) return;
    final service = VersionCheckService();
    try {
      final result = await service.check();
      _checked = true;
      if (!mounted) return;
      if (result.shouldPrompt) {
        void showIfReady() {
          final navigatorContext = AppRoutes.rootNavigatorKey.currentContext;
          if (navigatorContext != null) {
            print('📌 Version check: showing update dialog (${result.requirement.name})');
            showUpdateAppDialog(navigatorContext, result: result);
          }
        }
        showIfReady();
        if (AppRoutes.rootNavigatorKey.currentContext == null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            showIfReady();
          });
        }
      } else {
        print('📌 Version check: no prompt (up to date or no config)');
      }
    } catch (e, st) {
      _checked = true;
      print('📌 Version check failed: $e');
      debugPrint('$st');
      // On failure (e.g. no network, backend error), allow app to run
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
