import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/ado_dad_logo.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:ado_dad_user/features/login/bloc/otp_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationPage extends StatefulWidget {
  final String identifier;
  final bool isEmail;

  const OtpVerificationPage({
    super.key,
    required this.identifier,
    required this.isEmail,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  static const int _resendCooldownSeconds = 30;
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSecondsLeft > 0) {
          _resendSecondsLeft--;
        }
        if (_resendSecondsLeft == 0) {
          timer.cancel();
        }
      });
    });
  }

  /// Masks the destination the OTP was sent to, e.g. "+91 98•••• ••21"
  /// or "ra•••••@newshop.in".
  String get _maskedIdentifier {
    final id = widget.identifier.trim();
    if (widget.isEmail) {
      final at = id.indexOf('@');
      if (at <= 2) return id;
      return '${id.substring(0, 2)}${'•' * (at - 2)}${id.substring(at)}';
    }
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return id;
    final first = digits.substring(0, 2);
    final last = digits.substring(digits.length - 2);
    return '+91 $first•••• ••$last';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handleConfirmOtp() {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == 6) {
      context.read<OtpBloc>().add(
            OtpEvent.verifyOtp(
              identifier: widget.identifier,
              otp: otp,
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter complete OTP',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade300.withOpacity(0.9),
        ),
      );
    }
  }

  void _handleResendOtp() {
    context.read<OtpBloc>().add(
          OtpEvent.sendOtp(identifier: widget.identifier),
        );
    _startResendCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpBloc, OtpState>(
      listener: (context, state) {
        state.whenOrNull(
          verifyOtpSuccess: (username) {
            context.go('/home');
          },
          verifyOtpFailure: (message) {
            DialogUtil.showLoginErrorDialog(context, message);
          },
          sendOtpSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'OTP sent successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.primaryColor,
              ),
            );
          },
          sendOtpFailure: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to send OTP: ${message.replaceAll('Exception: ', '')}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade300.withOpacity(0.9),
              ),
            );
          },
        );
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              (!kIsWeb && Platform.isIOS)
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 24.0, // Keep mobile unchanged
                tablet: 30.0,
                largeTablet: 35.0,
                desktop: 40.0,
              ),
            ),
            onPressed: () {
              context.pop();
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adodad logo with responsive sizing
                Align(
                  alignment: Alignment.centerLeft,
                  child: AdoDadLogo(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 36,
                      tablet: 48,
                      largeTablet: 60,
                      desktop: 72,
                    ),
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 36.0,
                      tablet: 44.0,
                      largeTablet: 52.0,
                      desktop: 60.0,
                    ),
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'OTP Verification',
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
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Enter the OTP you received',
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 14.0, // Keep mobile unchanged
                        tablet: 20.0,
                        largeTablet: 26.0,
                        desktop: 32.0,
                      ),
                      color: AppColors.blackColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sent to $_maskedIdentifier',
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 12.0,
                            tablet: 16.0,
                            largeTablet: 20.0,
                            desktop: 24.0,
                          ),
                          color: AppColors.greyColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 12.0,
                              tablet: 16.0,
                              largeTablet: 20.0,
                              desktop: 24.0,
                            ),
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildOtpInputFields(),
                const SizedBox(height: 30),
                _buildConfirmOtpButton(),
                const SizedBox(height: 20),
                _buildResendCodeSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputFields() {
    final boxSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 50.0, // Keep mobile unchanged
      tablet: 60.0,
      largeTablet: 70.0,
      desktop: 80.0,
    );
    final fontSize = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: 24.0, // Keep mobile unchanged
      tablet: 30.0,
      largeTablet: 36.0,
      desktop: 42.0,
    );
    final borderWidth = GetResponsiveSize.isTablet(context) ? 1.0 : 0.5;
    final focusedBorderWidth = GetResponsiveSize.isTablet(context) ? 2.0 : 1.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: boxSize,
          height: GetResponsiveSize.isTablet(context)
              ? GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 0,
                  tablet: 65,
                  largeTablet: 75,
                  desktop: 85,
                )
              : null,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.greyColor,
                  width: borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: focusedBorderWidth,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 12,
                  tablet: 16,
                  largeTablet: 18,
                  desktop: 20,
                ),
              ),
            ),
            onChanged: (value) => _onOtpChanged(index, value),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmOtpButton() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          verifyOtpLoading: () => true,
          orElse: () => false,
        );
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
            onPressed: isLoading ? null : _handleConfirmOtp,
            child: isLoading
                ? SizedBox(
                    width: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 20,
                      tablet: 25,
                      largeTablet: 30,
                      desktop: 35,
                    ),
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 20,
                      tablet: 25,
                      largeTablet: 30,
                      desktop: 35,
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Confirm OTP',
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

  Widget _buildResendCodeSection() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        final isResending = state.maybeWhen(
          sendOtpLoading: () => true,
          orElse: () => false,
        );
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive code?",
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 14.0, // Keep mobile unchanged
                    tablet: 20.0,
                    largeTablet: 25.0,
                    desktop: 30.0,
                  ),
                  fontWeight: FontWeight.w500,
                  color: AppColors.blackColor,
                ),
              ),
              SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 4,
                  tablet: 6,
                  largeTablet: 8,
                  desktop: 10,
                ),
              ),
              TextButton(
                onPressed: (isResending || _resendSecondsLeft > 0)
                    ? null
                    : _handleResendOtp,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(
                      context,
                      mobile: 4,
                      tablet: 6,
                      largeTablet: 8,
                      desktop: 10,
                    ),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _resendSecondsLeft > 0
                    ? Text(
                        'Resend in 0:${_resendSecondsLeft.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 14.0,
                            tablet: 20.0,
                            largeTablet: 25.0,
                            desktop: 30.0,
                          ),
                          fontWeight: FontWeight.w500,
                          color: AppColors.greyColor,
                        ),
                      )
                    : isResending
                    ? SizedBox(
                        width: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 14,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26,
                        ),
                        height: GetResponsiveSize.getResponsiveSize(
                          context,
                          mobile: 14,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Resend Code',
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
            ],
          ),
        );
      },
    );
  }
}
