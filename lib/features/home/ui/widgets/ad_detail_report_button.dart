import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/ui/report_ad_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdDetailReportButton extends StatelessWidget {
  final AddModel ad;
  final Future<bool> Function(AddModel) isCurrentUserOwner;

  const AdDetailReportButton({
    super.key,
    required this.ad,
    required this.isCurrentUserOwner,
  });

  void _showReportDialog(BuildContext context) {
    final reportedUserId = ad.user?.id;
    if (reportedUserId == null || reportedUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to report: User information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!kIsWeb && Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => ReportAdDialog(
          reportedUserId: reportedUserId,
          adId: ad.id,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => ReportAdDialog(
          reportedUserId: reportedUserId,
          adId: ad.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isCurrentUserOwner(ad),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;

        if (isOwner) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showReportDialog(context),
                icon: Icon(
                  Icons.report_problem,
                  size: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 18, tablet: 25, largeTablet: 29, desktop: 33),
                  color: Colors.red.shade600,
                ),
                label: Text(
                  'Report Ad',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 22, largeTablet: 25, desktop: 30),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                    vertical: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
