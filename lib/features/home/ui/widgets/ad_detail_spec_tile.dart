import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class AdDetailSpec {
  final String label;
  final String value;
  final IconData icon;
  const AdDetailSpec(this.label, this.value, {required this.icon});
}

class AdDetailSpecTile extends StatelessWidget {
  final AdDetailSpec spec;

  const AdDetailSpecTile({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    // For Description, align to top to allow proper text wrapping
    final isDescription = spec.label == 'Description';

    return Row(
      crossAxisAlignment:
          isDescription ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          height: GetResponsiveSize.getResponsiveSize(context,
              mobile: 36, tablet: 56, largeTablet: 68, desktop: 80),
          width: GetResponsiveSize.getResponsiveSize(context,
              mobile: 36, tablet: 56, largeTablet: 68, desktop: 80),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(context,
                  mobile: 10, tablet: 14, largeTablet: 16, desktop: 18),
            ),
          ),
          child: Icon(
            spec.icon,
            size: GetResponsiveSize.getResponsiveSize(context,
                mobile: 18, tablet: 28, largeTablet: 34, desktop: 40),
            color: const Color(0xFF475569),
          ),
        ),
        SizedBox(
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 10, tablet: 14, largeTablet: 16, desktop: 18)),
        Expanded(
          child: Column(
            mainAxisAlignment: isDescription
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.label,
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 11, tablet: 18, largeTablet: 22, desktop: 26),
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 2, tablet: 4, largeTablet: 5, desktop: 6)),
              Text(
                spec.value,
                maxLines:
                    (spec.label == 'Amenities' || spec.label == 'Description')
                        ? null
                        : 1,
                overflow:
                    (spec.label == 'Amenities' || spec.label == 'Description')
                        ? null
                        : TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 13, tablet: 20, largeTablet: 24, desktop: 28),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
