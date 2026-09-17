import 'dart:io' show Platform;

import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/version_check_service.dart';
import 'package:ado_dad_user/common/widgets/update_app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Checks for a newer store build and prompts the user.
///
/// * Runs on first frame and again whenever the app returns to foreground
///   (throttled by [_minRecheckInterval]; always rechecks while a forced
///   update is pending).
/// * Android: tries Google Play's native in-app update first (immediate for
///   forced, flexible for optional). Falls back to our dialog if Play isn't
///   available (debug/sideloaded builds).
/// * Optional prompts can be snoozed with "Later" for [_snoozeDuration] per
///   target build; a newer release prompts again.
///
/// Place inside [StartupConnectivityGate] so it only runs once online.
class VersionCheckWrapper extends StatefulWidget {
  final Widget child;

  /// Injected for tests.
  final VersionCheckService? service;

  const VersionCheckWrapper({super.key, required this.child, this.service});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper>
    with WidgetsBindingObserver {
  static const _minRecheckInterval = Duration(minutes: 30);
  static const _snoozeDuration = Duration(hours: 24);
  static const _snoozeKeyPref = 'update_prompt_snooze_key';
  static const _snoozeAtPref = 'update_prompt_snooze_at';

  late final VersionCheckService _service =
      widget.service ?? VersionCheckService();

  bool _running = false;
  bool _dialogOpen = false;
  bool _forcePending = false;
  DateTime? _lastCheckAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCheck());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastCheckAt;
    final due = _forcePending ||
        last == null ||
        DateTime.now().difference(last) >= _minRecheckInterval;
    if (due) _runCheck();
  }

  Future<void> _runCheck() async {
    if (_running || _dialogOpen || !mounted) return;
    _running = true;
    try {
      final result = await _service.check();
      _lastCheckAt = DateTime.now();
      _forcePending = result.isForce;
      if (!mounted || !result.shouldPrompt) return;

      if (!result.isForce && await _isSnoozed(result)) return;

      if (Platform.isAndroid) {
        final handled = await _tryPlayInAppUpdate(result);
        if (handled || !mounted) return;
      }

      await _showDialog(result);
    } catch (_) {
      // Offline / backend error: never block the app. _lastCheckAt stays
      // unset so the next resume retries.
    } finally {
      _running = false;
    }
  }

  /// Returns true when Play handled the prompt (or said there is nothing to
  /// install yet for an optional update), false to fall back to the dialog.
  Future<bool> _tryPlayInAppUpdate(VersionCheckResult result) async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (_) {
      return false; // Not installed from Play (debug, sideload, emulator).
    }

    if (info.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress) {
      // An immediate update was interrupted; resume it.
      if (result.isForce) {
        return _runImmediate();
      }
      return true;
    }

    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      // Play doesn't offer the build to this user yet (staged rollout / cache).
      // Optional: stay quiet rather than open a store page with no Update
      // button. Forced: still block via the dialog.
      return !result.isForce;
    }

    try {
      if (result.isForce) {
        if (!info.immediateUpdateAllowed) return false;
        return _runImmediate();
      }

      if (!info.flexibleUpdateAllowed) return false;
      final r = await InAppUpdate.startFlexibleUpdate();
      if (r == AppUpdateResult.success) {
        await _promptRestartAfterDownload();
      } else if (r == AppUpdateResult.userDeniedUpdate) {
        await _snooze(result);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Immediate (full-screen Play) update. If the user backs out we still
  /// show our blocking dialog.
  Future<bool> _runImmediate() async {
    try {
      final r = await InAppUpdate.performImmediateUpdate();
      return r == AppUpdateResult.success;
    } catch (_) {
      return false;
    }
  }

  Future<void> _promptRestartAfterDownload() async {
    final ctx = await _navigatorContext();
    if (ctx == null || !ctx.mounted) return;
    _dialogOpen = true;
    try {
      final restart = await showDialog<bool>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: const Text('Update ready'),
          content: const Text('Restart Ado-dad to finish installing the update.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Restart'),
            ),
          ],
        ),
      );
      // "Later": Play installs the downloaded update the next time the app
      // is in the background.
      if (restart == true) await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _showDialog(VersionCheckResult result) async {
    // go_router can tear the dialog down when it replaces the page below it
    // (e.g. splash → home). Re-show a few times in that case.
    for (var attempt = 0; attempt < 5; attempt++) {
      final ctx = await _navigatorContext();
      if (ctx == null || !ctx.mounted || !mounted) return;

      _dialogOpen = true;
      var outcome = UpdateDialogOutcome.removed;
      try {
        outcome = await showUpdateAppDialog(ctx, result: result);
      } finally {
        _dialogOpen = false;
      }

      switch (outcome) {
        case UpdateDialogOutcome.later:
          await _snooze(result);
          return;
        case UpdateDialogOutcome.update:
          return;
        case UpdateDialogOutcome.removed:
          await Future<void>.delayed(const Duration(milliseconds: 600));
          continue;
      }
    }
  }

  Future<BuildContext?> _navigatorContext() async {
    for (var i = 0; i < 10; i++) {
      final ctx = AppRoutes.rootNavigatorKey.currentContext;
      if (ctx != null) return ctx;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return null;
  }

  Future<bool> _isSnoozed(VersionCheckResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_snoozeKeyPref) != result.snoozeKey) return false;
      final at = prefs.getInt(_snoozeAtPref);
      if (at == null) return false;
      final since = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(at));
      return since < _snoozeDuration;
    } catch (_) {
      return false;
    }
  }

  Future<void> _snooze(VersionCheckResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_snoozeKeyPref, result.snoozeKey);
      await prefs.setInt(
          _snoozeAtPref, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
