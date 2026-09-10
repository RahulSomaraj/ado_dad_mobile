import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_action_buttons.dart';
import 'package:flutter/material.dart';

String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

String _formatInr(num n) {
  final s = n.round().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final buf = <String>[];
  while (rest.length > 2) {
    buf.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) buf.insert(0, rest);
  return '${buf.join(',')},$last3';
}

String _niceDate(String iso) {
  try {
    final dt = DateTime.tryParse(iso) ?? DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    return '${dt.day} $month ${dt.year}';
  } catch (_) {
    return '';
  }
}

class AdDetailTitlePrice extends StatelessWidget {
  final AddModel ad;
  final Future<bool> Function(AddModel) isCurrentUserOwner;

  const AdDetailTitlePrice({
    super.key,
    required this.ad,
    required this.isCurrentUserOwner,
  });

  @override
  Widget build(BuildContext context) {
    // Only show title if it exists and is not empty - no auto-generation
    final title =
        (ad.title != null && ad.title!.trim().isNotEmpty) ? ad.title! : '';

    final postedAt = (ad.postedAt ?? '').trim();

    // Check if running on iPhone
    final isIOS = !kIsWeb && Platform.isIOS;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 6, tablet: 8, largeTablet: 10, desktop: 12),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: title.isNotEmpty
                    ? Text(
                        toTitleCase(title),
                        style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: isIOS ? 13.5 : 14.5,
                                tablet: 20,
                                largeTablet: 23,
                                desktop: 26),
                            fontWeight: FontWeight.w500),
                        maxLines: isIOS ? null : 2,
                        overflow: isIOS
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
              FutureBuilder<bool>(
                future: isCurrentUserOwner(ad),
                builder: (context, snapshot) {
                  final isOwner = snapshot.data ?? false;
                  if (!isOwner) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      left: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 8,
                        tablet: 12,
                        largeTablet: 14,
                        desktop: 16,
                      ),
                    ),
                    child: AdDetailShareButton(ad: ad),
                  );
                },
              ),
            ],
          ),
          if (title.isNotEmpty)
            SizedBox(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: isIOS ? 6 : 8,
                tablet: 12,
                largeTablet: 14,
                desktop: 16,
              ),
            ),
          if (postedAt.isNotEmpty)
            Text(
              'Posted On ${_niceDate(postedAt)}',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: isIOS ? 11 : 13,
                  tablet: 18,
                  largeTablet: 20,
                  desktop: 22,
                ),
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          if (postedAt.isNotEmpty)
            SizedBox(
              height: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: isIOS ? 6 : 8,
                tablet: 12,
                largeTablet: 14,
                desktop: 16,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '₹ ${_formatInr(ad.price)}',
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: isIOS ? 23 : 25,
                        tablet: 30,
                        largeTablet: 34,
                        desktop: 38),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (ad.distance != null && ad.distance! > 0) ...[
            SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: isIOS ? 6 : 8,
                  tablet: 12,
                  largeTablet: 14,
                  desktop: 16),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 14, tablet: 18, largeTablet: 20, desktop: 22),
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 3),
                Text(
                  '${ad.distance!.toStringAsFixed(ad.distance! < 10 ? 1 : 0)} km away',
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: isIOS ? 11 : 13,
                        tablet: 18,
                        largeTablet: 20,
                        desktop: 22),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}