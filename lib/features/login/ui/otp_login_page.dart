import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:ado_dad_user/features/login/bloc/otp_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({super.key});

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  final TextEditingController _otpInputController = TextEditingController();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  /// false = phone mode (default), true = email mode
  bool _emailMode = false;

  /// Helper function to validate if input is email or phone
  bool _isEmail(String value) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(value);
  }

  bool _isPhone(String value) {
    return RegExp(r"^[0-9]{10}$").hasMatch(value);
  }

  String? _validateInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _emailMode ? "Email is required" : "Phone is required";
    }
    final trimmedValue = value.trim();
    if (_emailMode) {
      if (!_isEmail(trimmedValue)) {
        return "Enter a valid email address";
      }
    } else {
      if (!_isPhone(trimmedValue)) {
        return "Enter a valid phone number";
      }
    }
    return null;
  }

  void _toggleMode() {
    setState(() {
      _emailMode = !_emailMode;
      _otpInputController.clear(); // avoid mixing old value
    });
  }

  void _handleGetOtp() {
    if (_otpFormKey.currentState!.validate()) {
      final identifier = _otpInputController.text.trim();
      context.read<OtpBloc>().add(OtpEvent.sendOtp(identifier: identifier));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpBloc, OtpState>(
      listener: (context, state) {
        state.whenOrNull(
          sendOtpSuccess: () {
            final identifier = _otpInputController.text.trim();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully'),
                backgroundColor: AppColors.primaryColor,
              ),
            );

            // Navigate to OTP verification page
            context.push('/otp-verification', extra: {
              'identifier': identifier,
              'isEmail': _emailMode,
            });
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
            icon: const Icon(Icons.arrow_back),
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
                Image.asset('assets/images/Ado-dad.png'),
                const SizedBox(height: 30),
                Text(
                  _emailMode
                      ? 'Login with your Email'
                      : 'Login with your Phone Number',
                  style: AppTextstyle.title1,
                ),
                const Text(
                    'Securely enter your account for a seamless\nexperience.'),
                const SizedBox(height: 20),
                Form(
                  key: _otpFormKey,
                  child: Column(
                    children: [
                      _buildOtpInputField(),
                      const SizedBox(height: 20),
                      _buildGetOtpButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                    child: Text(
                  'Or',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blackColor1),
                )),
                Center(
                  child: TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _emailMode ? 'Login with Phone' : 'Login with Email',
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 14,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.blackColor)),
                    GestureDetector(
                      onTap: () {
                        context.go('/signup');
                      },
                      child: Text('Signup',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputField() {
    return TextFormField(
      controller: _otpInputController,
      keyboardType:
          _emailMode ? TextInputType.emailAddress : TextInputType.phone,
      inputFormatters: _emailMode
          ? null
          : [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10)
            ],
      decoration: CommonDecoration.textFieldDecoration(
        labelText: _emailMode ? "Email" : "Phone",
        isPassword: false,
        obscureText: false,
        togglePasswordVisibility: null,
      ),
      validator: _validateInput,
    );
  }

  Widget _buildGetOtpButton() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          sendOtpLoading: () => true,
          orElse: () => false,
        );
        return SizedBox(
          height: 55,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: isLoading ? null : _handleGetOtp,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Get OTP',
                    style: AppTextstyle.buttonText,
                  ),
          ),
        );
      },
    );
  }
}
