import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/ado_dad_logo.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/phone_number_util.dart';
import 'package:ado_dad_user/common/widgets/common_decoration.dart';
import 'package:ado_dad_user/features/login/bloc/otp_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class OtpLoginPage extends StatefulWidget {
  /// Where to send the user after a successful login (from `?redirect=`).
  final String? redirect;

  const OtpLoginPage({super.key, this.redirect});

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  final TextEditingController _otpInputController = TextEditingController();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  /// false = phone mode (default), true = email mode
  bool _emailMode = false;

  /// Selected country code when in phone mode
  String _selectedCountryCode = '+91';

  /// Selected flag emoji for the chosen country (for display only)
  String _selectedFlag = '🇮🇳';

  /// Stores the last identifier used for sending OTP so that we reuse
  /// the exact same value during navigation, resend, etc.
  String? _lastIdentifier;

  /// Helper function to validate if input is email or phone
  bool _isEmail(String value) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(value);
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
      final phone =
          PhoneNumberUtil.normalise(trimmedValue, _selectedCountryCode);
      if (!phone.isValid) {
        return phone.validationMessage;
      }
    }
    return null;
  }

  /// Builds the identifier value that is sent to the backend.
  /// - For email mode: plain email
  /// - For phone mode: `<countryCode><phoneNumber>` e.g. `+937559052468`
  String _buildIdentifier() {
    final trimmedValue = _otpInputController.text.trim();
    if (_emailMode) {
      return trimmedValue;
    }
    if (trimmedValue.isEmpty) return '';
    // Strips a pasted/autofilled "+91", "0091" or trunk "0" so the country
    // code is never doubled (the "+91919474…" bug).
    return PhoneNumberUtil.normalise(trimmedValue, _selectedCountryCode).e164;
  }

  /// Live "Will send to +91 94744 14563" hint under the phone field.
  String? get _sendToHint {
    if (_emailMode) return null;
    final raw = _otpInputController.text.trim();
    if (raw.isEmpty) return null;
    final phone = PhoneNumberUtil.normalise(raw, _selectedCountryCode);
    if (!phone.isValid) return null;
    return 'Will send to ${PhoneNumberUtil.format(phone.national, phone.dialCode)}';
  }

  /// Rewrites the field to the cleaned national number after a paste/autofill
  /// (e.g. "+91 94744 14563" → "9474414563") so the user sees what is sent.
  void _onPhoneChanged(String value) {
    if (!_emailMode) {
      final phone = PhoneNumberUtil.normalise(value, _selectedCountryCode);
      if (phone.national != value && phone.isValid) {
        _otpInputController.value = TextEditingValue(
          text: phone.national,
          selection: TextSelection.collapsed(offset: phone.national.length),
        );
      }
    }
    setState(() {});
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = "+${country.phoneCode}";
          _selectedFlag = country.flagEmoji;
        });
      },
    );
  }

  void _toggleMode() {
    setState(() {
      _emailMode = !_emailMode;
      _otpInputController.clear(); // avoid mixing old value
    });
  }

  void _handleGetOtp() {
    if (_otpFormKey.currentState!.validate()) {
      final identifier = _buildIdentifier();
      if (identifier.isEmpty) {
        return;
      }
      _lastIdentifier = identifier;
      context.read<OtpBloc>().add(OtpEvent.sendOtp(identifier: identifier));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpBloc, OtpState>(
      listener: (context, state) {
        // OtpBloc is app-global: when the verification page (pushed on top)
        // resends, this listener fires too. Only react while this page is
        // the visible route, otherwise a duplicate verification page is pushed.
        if (ModalRoute.of(context)?.isCurrent != true) return;
        state.whenOrNull(
          sendOtpSuccess: () {
            final identifier = _lastIdentifier ?? _buildIdentifier();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'OTP sent successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.primaryColor,
              ),
            );

            // Navigate to OTP verification page
            context.push('/otp-verification', extra: {
              'identifier': identifier,
              'isEmail': _emailMode,
              'redirect': widget.redirect,
            });
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
          // '/login' is a root route after logout / splash — only show a
          // back arrow when there is actually something to pop.
          automaticallyImplyLeading: false,
          leading: context.canPop()
              ? IconButton(
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
                  onPressed: () => context.pop(),
                )
              : null,
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
                Text(
                  'Welcome back',
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
                  _emailMode
                      ? 'Enter your email and we\'ll send you a one-time code.'
                      : 'Enter your mobile number and we\'ll text you a one-time code.',
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
                const SizedBox(height: 20),
                Form(
                  key: _otpFormKey,
                  child: Column(
                    children: [
                      _buildOtpInputField(),
                      if (_sendToHint != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _sendToHint!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _buildGetOtpButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _emailMode ? 'Use phone number instead' : 'Use email instead',
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
                _buildOrDivider(),
                const SizedBox(height: 16),
                _buildPasswordLoginButton(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.greyColor.withValues(alpha: 0.5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.greyColor,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.greyColor.withValues(alpha: 0.5))),
      ],
    );
  }

  /// Secondary action: password login lives one tap away, below the fold line.
  Widget _buildPasswordLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: GetResponsiveSize.getResponsiveSize(
        context,
        mobile: 50,
        tablet: 65,
        largeTablet: 75,
        desktop: 85,
      ),
      child: OutlinedButton(
        onPressed: () => context.push('/login-password'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blackColor,
          side: BorderSide(color: AppColors.greyColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(
                context,
                mobile: 25,
                tablet: 30,
                largeTablet: 35,
                desktop: 40,
              ),
            ),
          ),
        ),
        child: Text(
          'Login with password',
          style: AppTextstyle.buttonText.copyWith(
            color: AppColors.blackColor,
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
    );
  }

  Widget _buildOtpInputField() {
    final textField = TextFormField(
      controller: _otpInputController,
      onChanged: _onPhoneChanged,
      autofillHints:
          _emailMode ? const [AutofillHints.email] : const [AutofillHints.telephoneNumberNational],
      keyboardType:
          _emailMode ? TextInputType.emailAddress : TextInputType.phone,
      inputFormatters: _emailMode
          ? null
          : [
              FilteringTextInputFormatter.digitsOnly,
            ],
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
        labelText: _emailMode ? "Email" : "Phone",
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
        prefixIcon: !_emailMode
            ? Padding(
                padding: const EdgeInsets.only(left: 10, right: 5),
                child: GestureDetector(
                  onTap: _showCountryPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFlag,
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 20.0,
                            tablet: 25.0,
                            largeTablet: 28.0,
                            desktop: 30.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 25,
                        child: VerticalDivider(
                          width: 10,
                          thickness: 1.5,
                          color: AppColors.greyColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _selectedCountryCode,
                        style: TextStyle(
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16.0,
                            tablet: 18.0,
                            largeTablet: 20.0,
                            desktop: 22.0,
                          ),
                          color: AppColors.greyColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          largeTablet: 26.0,
                          desktop: 28.0,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      validator: _validateInput,
    );

    // Apply responsive height wrapper for tablets and above
    final fieldWithHeight = GetResponsiveSize.isTablet(context)
        ? SizedBox(
            height: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 0, // Not used since we check isTablet first
              tablet: 65,
              largeTablet: 75,
              desktop: 85,
            ),
            child: textField,
          )
        : textField;

    return fieldWithHeight;
  }

  Widget _buildGetOtpButton() {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          sendOtpLoading: () => true,
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
            onPressed: isLoading ? null : _handleGetOtp,
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
                    'Get OTP',
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
