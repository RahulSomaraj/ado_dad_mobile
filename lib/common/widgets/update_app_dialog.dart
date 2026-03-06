import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/version_check_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a dialog prompting user to update the app.
/// [force] = true: no "Later" button; user must tap "Update" to go to store.
/// [force] = false: user can dismiss with "Later" or tap "Update".
void showUpdateAppDialog(
  BuildContext context, {
  required VersionCheckResult result,
}) {
  final isForce = result.requirement == UpdateRequirement.force;

  showDialog(
    context: context,
    barrierDismissible: !isForce,
    builder: (context) => PopScope(
      canPop: !isForce,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Update Available',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isForce)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Later',
                style: TextStyle(color: AppColors.primaryColor),
              ),
            ),
          FilledButton(
            style: ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll(AppColors.primaryColor)),
            onPressed: () async {
              final uri = Uri.parse(result.storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (context.mounted && !isForce) Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    ),
  );
}
