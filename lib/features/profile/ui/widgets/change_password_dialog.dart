import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/password_validator.dart';
import 'package:ado_dad_user/features/profile/ui/widgets/password_field_builders.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class ChangePasswordDialog {
  static void show({
    required BuildContext context,
    required TextEditingController newPasswordController,
    required TextEditingController confirmPasswordController,
    required GlobalKey<FormState> formKey,
    required bool isNewPasswordVisible,
    required bool isConfirmPasswordVisible,
    required Function(bool) onNewPasswordVisibilityChanged,
    required Function(bool) onConfirmPasswordVisibilityChanged,
    required VoidCallback onConfirm,
    required VoidCallback onIOSConfirm,
  }) {
    if (!kIsWeb && Platform.isIOS) {
      // iOS Cupertino Dialog
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return CupertinoAlertDialog(
                title: Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 22,
                      largeTablet: 26,
                      desktop: 30,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Container(
                  padding: EdgeInsets.only(
                    top: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 16,
                      tablet: 20,
                      largeTablet: 24,
                      desktop: 28,
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PasswordFieldBuilders.buildIOSPasswordField(
                            context: context,
                            controller: newPasswordController,
                            label: "New Password",
                            isVisible: isNewPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() {
                                onNewPasswordVisibilityChanged(
                                    !isNewPasswordVisible);
                              });
                            },
                            validator: PasswordValidator.validatePassword,
                          ),
                          SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 12,
                              tablet: 16,
                              largeTablet: 20,
                              desktop: 24,
                            ),
                          ),
                          PasswordFieldBuilders.buildIOSPasswordField(
                            context: context,
                            controller: confirmPasswordController,
                            label: "Confirm Password",
                            isVisible: isConfirmPasswordVisible,
                            onToggleVisibility: () {
                              setDialogState(() {
                                onConfirmPasswordVisibilityChanged(
                                    !isConfirmPasswordVisible);
                              });
                            },
                            validator: (value) =>
                                PasswordValidator.validateConfirmPassword(
                              value,
                              newPasswordController.text,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: false,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          largeTablet: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      // Manual validation for iOS
                      final newPasswordError =
                          PasswordValidator.validatePassword(
                        newPasswordController.text,
                      );
                      final confirmPasswordError =
                          PasswordValidator.validateConfirmPassword(
                        confirmPasswordController.text,
                        newPasswordController.text,
                      );

                      if (newPasswordError != null ||
                          confirmPasswordError != null) {
                        // Show error message
                        showCupertinoDialog(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Validation Error'),
                            content: Text(
                              newPasswordError ??
                                  confirmPasswordError ??
                                  'Please check your input',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                isDefaultAction: true,
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context); // Close the password dialog
                      onIOSConfirm();
                    },
                    child: Text(
                      "OK",
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          largeTablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }

    // Android/Other Platforms Material Dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.whiteColor,
              insetPadding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 16,
                  tablet: 40,
                  largeTablet: 60,
                  desktop: 80,
                ),
              ),
              title: Text(
                "Change Password",
                textAlign: TextAlign.center,
                style: AppTextstyle.title1.copyWith(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: AppTextstyle.title1.fontSize ?? 20,
                    tablet: 24,
                    largeTablet: 28,
                    desktop: 34,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 24,
                  tablet: 32,
                  largeTablet: 40,
                  desktop: 48,
                ),
                vertical: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 20,
                  tablet: 24,
                  largeTablet: 28,
                  desktop: 32,
                ),
              ),
              content: SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 300,
                  tablet: 400,
                  largeTablet: 500,
                  desktop: 600,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PasswordFieldBuilders.buildPasswordField(
                        context: context,
                        controller: newPasswordController,
                        label: "New Password",
                        isVisible: isNewPasswordVisible,
                        onToggleVisibility: () {
                          setDialogState(() {
                            onNewPasswordVisibilityChanged(
                                !isNewPasswordVisible);
                          });
                        },
                        validator: PasswordValidator.validatePassword,
                      ),
                      const SizedBox(height: 16),
                      PasswordFieldBuilders.buildPasswordField(
                        context: context,
                        controller: confirmPasswordController,
                        label: "Confirm Password",
                        isVisible: isConfirmPasswordVisible,
                        onToggleVisibility: () {
                          setDialogState(() {
                            onConfirmPasswordVisibilityChanged(
                                !isConfirmPasswordVisible);
                          });
                        },
                        validator: (value) =>
                            PasswordValidator.validateConfirmPassword(
                          value,
                          newPasswordController.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 40,
                          tablet: 60,
                          largeTablet: 75,
                          desktop: 85,
                        ),
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: const WidgetStatePropertyAll(
                                AppColors.whiteColor),
                            side: WidgetStatePropertyAll(BorderSide(
                                color: Colors.grey[400]!, width: 1.0)),
                            shape: const WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)))),
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                vertical:
                                    GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24,
                                ),
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                largeTablet: 22,
                                desktop: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 12,
                        tablet: 18,
                        largeTablet: 24,
                        desktop: 30,
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 40,
                          tablet: 60,
                          largeTablet: 75,
                          desktop: 85,
                        ),
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: const WidgetStatePropertyAll(
                                AppColors.primaryColor),
                            shape: const WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)))),
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(
                                vertical:
                                    GetResponsiveSize.getResponsivePadding(
                                  context,
                                  mobile: 12,
                                  tablet: 16,
                                  largeTablet: 20,
                                  desktop: 24,
                                ),
                              ),
                            ),
                          ),
                          onPressed: onConfirm,
                          child: Text(
                            "OK",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 18,
                                largeTablet: 22,
                                desktop: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
