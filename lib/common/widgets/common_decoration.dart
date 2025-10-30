import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';

class CommonDecoration {
  static InputDecoration textFieldDecoration({
    required String labelText,
    bool isPassword = false,
    VoidCallback? togglePasswordVisibility,
    bool obscureText = false,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      // labelStyle: AppTextStyle.labelStyle,
      // floatingLabelStyle: AppTextStyle.floatinglabelStyle,
      border: const OutlineInputBorder(),
      // errorStyle: AppTextStyle.errortextStyle,
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                // color: AppColors.greyColor,
                size: 24,
              ),
              onPressed: togglePasswordVisibility,
            )
          : null,
      prefixText: prefixText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.greyColor,
          width: 0.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.greyColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.redColor,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.redColor,
        ),
      ),
    );
  }
}
