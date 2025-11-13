import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:flutter/material.dart';

class SaveButtonWidget extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const SaveButtonWidget({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 50,
              tablet: 65,
              largeTablet: 75,
              desktop: 85,
            ),
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 14,
                      tablet: 16,
                      largeTablet: 18,
                      desktop: 20,
                    ),
                  ),
                ),
              ),
              child: isSaving
                  ? SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 18,
                        tablet: 24,
                        largeTablet: 30,
                        desktop: 36,
                      ),
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 18,
                        tablet: 24,
                        largeTablet: 30,
                        desktop: 36,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 2,
                          tablet: 2.5,
                          largeTablet: 3,
                          desktop: 3.5,
                        ),
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: AppTextstyle.buttonText.copyWith(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: AppTextstyle.buttonText.fontSize ?? 16,
                          tablet: 20,
                          largeTablet: 24,
                          desktop: 28,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 24,
              desktop: 28,
            ),
          ),
        ],
      ),
    );
  }
}
