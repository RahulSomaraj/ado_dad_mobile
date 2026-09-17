import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/version_check_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// How the update dialog was closed.
enum UpdateDialogOutcome {
  /// User tapped "Later" or pressed back (optional update only).
  later,

  /// User tapped "Update" on an optional update (store opened).
  update,

  /// Dialog was removed without a user choice — e.g. go_router replaced the
  /// page underneath it (splash → home). Caller should show it again.
  removed,
}

/// Shows a dialog prompting the user to update the app.
///
/// Force: no "Later", back button is swallowed, dialog stays after "Update"
/// so the user can't continue on the unsupported build.
/// Optional: "Later" / back closes it.
Future<UpdateDialogOutcome> showUpdateAppDialog(
  BuildContext context, {
  required VersionCheckResult result,
}) async {
  final isForce = result.isForce;

  final outcome = await showDialog<UpdateDialogOutcome>(
    context: context,
    // Outside taps never close it: an explicit choice lets us tell a user
    // "Later" apart from the dialog being torn down by a route change.
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || isForce) return;
        Navigator.of(dialogContext).pop(UpdateDialogOutcome.later);
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isForce ? 'Update required' : 'Update available',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isForce
                    ? 'This version of Ado-dad is no longer supported. '
                        'Please update to keep using the app.'
                    : 'A new version of Ado-dad '
                        '(${result.latestVersion}) is available with the '
                        'latest improvements.',
              ),
              if (result.releaseNotes != null) ...[
                const SizedBox(height: 12),
                const Text(
                  "What's new",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(result.releaseNotes!),
              ],
            ],
          ),
        ),
        actions: [
          if (!isForce)
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(UpdateDialogOutcome.later),
              child: const Text(
                'Later',
                style: TextStyle(color: AppColors.primaryColor),
              ),
            ),
          FilledButton(
            style: const ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll(AppColors.primaryColor)),
            onPressed: () async {
              await openStoreListing(result.storeUrl);
              if (!isForce && dialogContext.mounted) {
                Navigator.of(dialogContext).pop(UpdateDialogOutcome.update);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    ),
  );

  return outcome ?? UpdateDialogOutcome.removed;
}

/// Opens the store page. Skips canLaunchUrl: on Android 11+ it returns false
/// for https unless `<queries>` is declared, which silently broke the button.
Future<void> openStoreListing(String url) async {
  if (url.isEmpty) return;
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Nothing useful to show; the dialog stays so the user can retry.
  }
}
