import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class ProfileLabel extends StatelessWidget {
  final String text;

  const ProfileLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 14,
            tablet: 22,
            largeTablet: 24,
            desktop: 24,
          ),
        ),
      ),
    );
  }
}
