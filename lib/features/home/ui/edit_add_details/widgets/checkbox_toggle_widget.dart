import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

/// Ownership toggle row (wireframe: "Edit ad" → OWNERSHIP switches).
/// Keeps the CheckboxToggleWidget name and onChanged contract so all four
/// edit forms pick this up without changes.
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
    return SwitchListTile(
      value: value,
      title: Text(
        title,
        style: TextStyle(
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 14.5,
            tablet: 18,
            largeTablet: 21,
            desktop: 24,
          ),
        ),
      ),
      activeColor: AppColors.primaryColor,
      dense: true,
      onChanged: (v) => onChanged(v),
      contentPadding: EdgeInsets.zero,
    );
  }
}
