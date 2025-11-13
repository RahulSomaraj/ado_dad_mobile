import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class CheckboxToggleWidget extends StatelessWidget {
  final bool value;
  final String title;
  final ValueChanged<bool?> onChanged;

  const CheckboxToggleWidget({
    super.key,
    required this.value,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      title: Text(
        title,
        style: TextStyle(
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 16,
            tablet: 20,
            largeTablet: 24,
            desktop: 28,
          ),
        ),
      ),
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
