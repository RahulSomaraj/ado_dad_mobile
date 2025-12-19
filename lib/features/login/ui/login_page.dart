import 'dart:io';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/error_message_util.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _forgotPasswordEmailController =
      TextEditingController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _forgotPasswordFormKey = GlobalKey<FormState>();

  /// Helper function to validate if input is email or phone
  bool _isEmail(String value) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(value);
  }

  bool _isPhone(String value) {
    return RegExp(r"^[0-9]{10}$").hasMatch(value);
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Username is required";
    }
    final trimmedValue = value.trim();
    if (!_isEmail(trimmedValue) && !_isPhone(trimmedValue)) {
      return "Enter a valid email or phone number";
    }
    return null;
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      print('🔗 [URL Launcher] Attempting to open URL: $url');

      if (Platform.isIOS) {
        // Use native iOS channel to bypass pigeon channel issues
        print('🔗 [URL Launcher] Using native iOS channel...');
        const platform = MethodChannel('com.ado_dad_user/url_launcher');
        try {
          final result = await platform.invokeMethod('launchUrl', url);
          print('✅ [URL Launcher] Native channel result: $result');
          if (result == false) {
            throw PlatformException(
              code: 'LAUNCH_FAILED',
              message: 'Failed to open URL',
            );
          }
        } on PlatformException catch (e) {
          print('❌ [URL Launcher] Native channel PlatformException:');
          print('   Code: ${e.code}');
          print('   Message: ${e.message}');
          print('   Details: ${e.details}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening link: ${e.message ?? e.code}'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          rethrow;
        }
      } else {
        // Android: Use url_launcher package
        print('🔗 [URL Launcher] Using url_launcher package for Android...');
        final uri = Uri.parse(url);
        final canLaunch = await canLaunchUrl(uri);
        print('🔗 [URL Launcher] canLaunchUrl result: $canLaunch');

        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('✅ [URL Launcher] URL launched successfully');
        } else {
          print('❌ [URL Launcher] Cannot launch URL: $url');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open link')),
            );
          }
        }
      }
    } on PlatformException catch (e) {
      // Already handled above for iOS, but catch here for Android
      print('❌ [URL Launcher] PlatformException:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: ${e.message ?? e.code}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [URL Launcher] General exception occurred:');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('   StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    if (Platform.isIOS) {
      // iOS-friendly dialog with Cupertino styling
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width > 600
                  ? 400
                  : MediaQuery.of(context).size.width * 0.85,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // iOS-style header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Forgot Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _forgotPasswordFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter your Email',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _forgotPasswordEmailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                color: CupertinoColors.label,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(
                                  color: CupertinoColors.placeholderText,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: CupertinoColors.systemGrey6,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: CupertinoColors.activeBlue,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: CupertinoColors.destructiveRed,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: CupertinoColors.destructiveRed,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                errorStyle: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.destructiveRed,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // iOS-style action buttons
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _forgotPasswordEmailController.clear();
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: CupertinoColors.destructiveRed,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 0.5,
                            height: 44,
                            color: CupertinoColors.separator,
                          ),
                          Expanded(
                            child: BlocBuilder<LoginBloc, LoginState>(
                              builder: (context, state) {
                                final isLoading =
                                    state is ForgotPasswordLoading;
                                return CupertinoButton(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          if (_forgotPasswordFormKey
                                              .currentState!
                                              .validate()) {
                                            _handleForgotPassword();
                                          }
                                        },
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CupertinoActivityIndicator(
                                            radius: 8,
                                          ),
                                        )
                                      : const Text(
                                          'Continue',
                                          style: TextStyle(
                                            color: CupertinoColors.activeBlue,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Android: Keep original Material design
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Container(
              width: MediaQuery.of(context).size.width > 600
                  ? 400 // Fixed width for tablets and larger screens
                  : MediaQuery.of(context).size.width *
                      0.85, // Responsive for phones
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Forgot Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _forgotPasswordFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enter your Email',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.blackColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _forgotPasswordEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _forgotPasswordEmailController.clear();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.greyColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      BlocBuilder<LoginBloc, LoginState>(
                        builder: (context, state) {
                          final isLoading = state is ForgotPasswordLoading;
                          return ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_forgotPasswordFormKey.currentState!
                                        .validate()) {
                                      _handleForgotPassword();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: AppColors.whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Continue'),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _handleForgotPassword() {
    final email = _forgotPasswordEmailController.text.trim();

    // Dispatch forgot password event to BLoC
    context.read<LoginBloc>().add(LoginEvent.forgotPassword(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adodad logo with responsive sizing
                Align(
                  alignment: Alignment.centerLeft,
                  child: GetResponsiveSize.isTablet(context)
                      ? SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 0, // Not used since we check isTablet first
                            tablet: 40,
                            largeTablet: 80,
                            desktop: 130,
                          ),
                          width: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 0, // Not used since we check isTablet first
                            tablet: 200,
                            largeTablet: 250,
                            desktop: 300,
                          ),
                          child: Image.asset(
                            'assets/images/Ado-dad.png',
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          'assets/images/Ado-dad.png',
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Login to your Account',
                  style: AppTextstyle.title1.copyWith(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 20.0, // Keep mobile unchanged
                      tablet: 30.0,
                      largeTablet: 40.0,
                      desktop: 50.0,
                    ),
                  ),
                ),
                Text(
                  'Securely log in and enjoy a seamless experience\nwith us!',
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 14.0, // Keep mobile unchanged (default size)
                      tablet: 20.0,
                      largeTablet: 26.0,
                      desktop: 32.0,
                    ),
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _loginFormKey,
                  child: Column(
                    children: [
                      _buildUsernameField(),
                      SizedBox(
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 10, // Keep mobile unchanged
                          tablet: 20,
                          largeTablet: 25,
                          desktop: 30,
                        ),
                      ),
                      _buildPasswordField(),
                      // const SizedBox(height: 10),
                      _buildForgotPasswordButton(),
                      const SizedBox(height: 10),
                      _buildButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                    child: Text(
                  'Or',
                  style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 14.0, // Keep mobile unchanged
                        tablet: 20.0,
                        largeTablet: 25.0,
                        desktop: 30.0,
                      ),
                      fontWeight: FontWeight.w500,
                      color: AppColors.blackColor1),
                )),
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.push('/login-otp');
                    },
                    child: Text(
                      'Login with OTP',
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 14.0, // Keep mobile unchanged
                            tablet: 20.0,
                            largeTablet: 25.0,
                            desktop: 30.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: AppColors.blackColor1),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New User?',
                        style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 14.0, // Keep mobile unchanged
                              tablet: 20.0,
                              largeTablet: 25.0,
                              desktop: 30.0,
                            ),
                            fontWeight: FontWeight.w500,
                            color: AppColors.blackColor)),
                    GestureDetector(
                      onTap: () {
                        context.go('/signup');
                      },
                      child: Text('Signup',
                          style: TextStyle(
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14.0, // Keep mobile unchanged
                                tablet: 20.0,
                                largeTablet: 25.0,
                                desktop: 30.0,
                              ),
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor)),
                    )
                  ],
                ),
                const SizedBox(height: 70),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _openExternalUrl(
                            'https://adodad.com/terms-and-conditions'),
                        child: Text(
                          'Terms & Conditions',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 12.0, // Keep mobile unchanged
                                tablet: 20.0,
                                largeTablet: 25.0,
                                desktop: 30.0,
                              ),
                              color: AppColors.primaryColor),
                        ),
                      ),
                      // const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _openExternalUrl(
                            'https://adodad.com/privacy-policy'),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 12.0, // Keep mobile unchanged
                                tablet: 20.0,
                                largeTablet: 25.0,
                                desktop: 30.0,
                              ),
                              color: AppColors.primaryColor),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    // Custom text field that accepts both email and phone
    final textField = TextFormField(
      controller: _usernameController,
      keyboardType: TextInputType.text,
      style: TextStyle(
        fontSize: GetResponsiveSize.getResponsiveFontSize(
          context,
          mobile: 16.0, // Keep mobile unchanged
          tablet: 20.0,
          largeTablet: 22.0,
          desktop: 24.0,
        ),
      ),
      decoration: CommonDecoration.textFieldDecoration(
        labelText: "Email or Phone",
        isPassword: false,
        obscureText: false,
        togglePasswordVisibility: null,
      ).copyWith(
        labelStyle: TextStyle(
          fontSize: GetResponsiveSize.getResponsiveFontSize(
            context,
            mobile: 16.0, // Keep mobile unchanged
            tablet: 20.0,
            largeTablet: 22.0,
            desktop: 24.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 12,
            tablet: 16,
            largeTablet: 18,
            desktop: 20,
          ),
          vertical: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 16,
            tablet: 20,
            largeTablet: 22,
            desktop: 24,
          ),
        ),
      ),
      validator: _validateUsername,
    );

    // Wrap in SizedBox only for tablets and above
    if (GetResponsiveSize.isTablet(context)) {
      return SizedBox(
        height: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 0, // Not used since we check isTablet first
          tablet: 65,
          largeTablet: 75,
          desktop: 85,
        ),
        child: textField,
      );
    }
    return textField;
  }

  Widget _buildPasswordField() {
    return GetInput(
      label: "Password",
      controller: _passwordController,
      isPassword: true,
      onSaved: (value) {},
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 14.0, // Keep mobile unchanged
              tablet: 20.0,
              largeTablet: 25.0,
              desktop: 30.0,
            ),
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        state.maybeWhen(
          success: (username) {
            // Navigator.push(
            //     context, MaterialPageRoute(builder: (context) => Home()));
            context.go('/home');
          },
          failure: (message) =>
              DialogUtil.showLoginErrorDialog(context, message),
          forgotPasswordSuccess: () {
            // Close forgot password dialog
            Navigator.of(context).pop();
            _forgotPasswordEmailController.clear();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset link sent to your email'),
                backgroundColor: AppColors.primaryColor,
              ),
            );
          },
          forgotPasswordFailure: (message) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorMessageUtil.getUserFriendlyMessage(message)),
                backgroundColor: Colors.red,
              ),
            );
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return SizedBox(
          height: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 55, // Keep mobile unchanged
            tablet: 65,
            largeTablet: 75,
            desktop: 85,
          ),
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (_loginFormKey.currentState!.validate()) {
                context.read<LoginBloc>().add(
                      LoginEvent.login(
                        username: _usernameController.text.trim(),
                        password: _passwordController.text.trim(),
                      ),
                    );
              }
            },
            child: Text(
              'Login',
              style: AppTextstyle.buttonText.copyWith(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16.0, // Keep mobile unchanged
                  tablet: 25.0,
                  largeTablet: 30.0,
                  desktop: 35.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
