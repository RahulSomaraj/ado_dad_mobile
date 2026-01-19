import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PasswordFieldBuilders {
  static Widget buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return SizedBox(
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 56,
        tablet: 65,
        largeTablet: 75,
        desktop: 85,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: onToggleVisibility,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 12,
              tablet: 18,
              largeTablet: 24,
              desktop: 30,
            ),
            vertical: GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildIOSPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: GetResponsiveSize.getResponsivePadding(
              context,
              mobile: 6,
              tablet: 8,
              largeTablet: 10,
              desktop: 12,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 15,
                largeTablet: 17,
                desktop: 19,
              ),
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
          ),
        ),
        Container(
          height: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 44,
            tablet: 50,
            largeTablet: 56,
            desktop: 62,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  obscureText: !isVisible,
                  placeholder: label,
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 12,
                      tablet: 16,
                      largeTablet: 20,
                      desktop: 24,
                    ),
                    vertical: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 10,
                      tablet: 12,
                      largeTablet: 14,
                      desktop: 16,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      largeTablet: 20,
                      desktop: 22,
                    ),
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 8,
                    tablet: 12,
                    largeTablet: 16,
                    desktop: 20,
                  ),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: onToggleVisibility,
                  child: Icon(
                    isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    size: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      largeTablet: 24,
                      desktop: 26,
                    ),
                    color: CupertinoColors.label,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(
              top: GetResponsiveSize.getResponsivePadding(
                context,
                mobile: 6,
                tablet: 8,
                largeTablet: 10,
                desktop: 12,
              ),
            ),
            child: Text(
              errorText,
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 14,
                  largeTablet: 16,
                  desktop: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
