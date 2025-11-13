import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditable;
  final bool isPhoneField;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.isEditable,
    this.isPhoneField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: isEditable,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 16,
          tablet: 24,
          largeTablet: 26,
          desktop: 26,
        ),
      ),
      keyboardType: isPhoneField ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhoneField
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      decoration: const InputDecoration(
        border: InputBorder.none,
      ),
    );
  }
}
