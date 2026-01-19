import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditable;
  final bool isPhoneField;
  final String? countryCode;
  final Function(String)? onCountryCodeChanged;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.isEditable,
    this.isPhoneField = false,
    this.countryCode,
    this.onCountryCodeChanged,
  });

  void _showCountryPicker(BuildContext context) {
    if (!isEditable) return;

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        if (onCountryCodeChanged != null) {
          onCountryCodeChanged!("+${country.phoneCode}");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPhoneField) {
      // Phone field with country code in same row (no flag, just code)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Country code display/selector
          if (countryCode != null)
            GestureDetector(
              onTap: isEditable ? () => _showCountryPicker(context) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    countryCode!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 24,
                        largeTablet: 26,
                        desktop: 26,
                      ),
                      color: AppColors.greyColor,
                    ),
                  ),
                  if (isEditable) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 20,
                        tablet: 28,
                        largeTablet: 30,
                        desktop: 32,
                      ),
                      color: AppColors.greyColor,
                    ),
                  ],
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.greyColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          // Phone number text field
          Expanded(
            child: TextFormField(
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
              keyboardType: TextInputType.phone,
              inputFormatters: isEditable
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                    ]
                  : null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      );
    }

    // Regular text field (non-phone or non-editable)
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
            ]
          : null,
      decoration: const InputDecoration(
        border: InputBorder.none,
      ),
    );
  }
}
