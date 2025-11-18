import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
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

class AdDetailTitlePrice extends StatelessWidget {
  final AddModel ad;

  const AdDetailTitlePrice({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    // Only show title if it exists and is not empty - no auto-generation
    final title =
        (ad.title != null && ad.title!.trim().isNotEmpty) ? ad.title! : '';

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isIOS ? 3 : 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    toTitleCase(title),
                    style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: isIOS ? 14 : 16,
                            tablet: 25,
                            largeTablet: 29,
                            desktop: 33),
                        fontWeight: FontWeight.bold),
                    maxLines: isIOS ? null : 2,
                    overflow:
                        isIOS ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
              width: GetResponsiveSize.getResponsiveSize(context,
                  mobile: isIOS ? 8 : 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28)),
          Container(
            height: GetResponsiveSize.getResponsiveSize(context,
                mobile: 40, tablet: 60, largeTablet: 70, desktop: 80),
            child: const VerticalDivider(
              thickness: 1,
              color: Colors.grey,
            ),
          ),
          SizedBox(
              width: GetResponsiveSize.getResponsiveSize(context,
                  mobile: isIOS ? 8 : 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28)),
          Flexible(
            flex: isIOS ? 2 : 1,
            child: Text(
              '₹ ${(ad.price)}',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: isIOS ? 13 : 16,
                    tablet: 25,
                    largeTablet: 29,
                    desktop: 33),
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
