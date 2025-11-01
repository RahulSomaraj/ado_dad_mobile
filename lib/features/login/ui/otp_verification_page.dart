import 'package:ado_dad_user/common/app_colors.dart';
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

  @override
  void dispose() {
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
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleResendOtp() {
    context.read<OtpBloc>().add(
          OtpEvent.sendOtp(identifier: widget.identifier),
        );
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
              const SnackBar(
                content: Text('OTP sent successfully'),
                backgroundColor: AppColors.primaryColor,
              ),
            );
          },
          sendOtpFailure: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to send OTP: ${message.replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
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
                  child: GetResponsiveSize.isTablet(context)
                      ? SizedBox(
                          height: GetResponsiveSize.getResponsiveSize(
                            context,
                            mobile: 0, // Not used since we check isTablet first
                            tablet: 40,
                            largeTablet: 80,
                            desktop: 100,
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
                Text(
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
                const SizedBox(height: 30),
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
                  color: AppColors.greyColor,
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
                onPressed: isResending ? null : _handleResendOtp,
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
                child: isResending
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
