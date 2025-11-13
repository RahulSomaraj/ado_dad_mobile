import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class AdDetailKeyValRow extends StatelessWidget {
  final String label;
  final String value;

  const AdDetailKeyValRow(
      {super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 110, tablet: 140, largeTablet: 170, desktop: 200),
            child: Text(
              label,
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 12, tablet: 18, largeTablet: 22, desktop: 26),
                color: const Color(0xFF6B7280),
              ),
            )),
        SizedBox(
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20)),
        Expanded(
            child: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 13, tablet: 20, largeTablet: 24, desktop: 28),
          ),
        )),
      ],
    );
  }
}
