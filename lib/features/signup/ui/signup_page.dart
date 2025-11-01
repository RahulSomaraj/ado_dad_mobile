import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/signup/bloc/signup_bloc.dart';
import 'package:ado_dad_user/models/signup_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';

  Uint8List? _avatarBytes; // <-- NEW: local preview bytes

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // we need bytes for S3 upload
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        setState(() {
          _avatarBytes = file.bytes;
        });
      }
    }
  }

  void _signUp() {
    if (_signupFormKey.currentState!.validate()) {
      _signupFormKey.currentState!.save();

      final signupData = SignupModel(
          id: '',
          name: _name,
          email: _email,
          phoneNumber: _phone,
          password: _password,
          type: 'NU');

      print('data:..........$signupData');

      context.read<SignupBloc>().add(SignupEvent.signup(
            data: signupData,
            profileBytes: _avatarBytes,
          ));
    }
  }

  void _showSuccessPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async {
                context.pop();
                context.go('/');
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sign up failed"),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text("OK")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: BlocListener<SignupBloc, SignupState>(
            listenWhen: (prev, curr) => curr is SignUpSuccess || curr is Error,
            listener: (context, state) {
              if (state is SignUpSuccess) {
                _showSuccessPopup(context, state.message);
              } else if (state is Error) {
                _showErrorPopup(context, state.message); // implement below
              }
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adodad logo with responsive sizing (matching login page)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GetResponsiveSize.isTablet(context)
                        ? SizedBox(
                            height: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile:
                                  0, // Not used since we check isTablet first
                              tablet: 40,
                              largeTablet: 80,
                              desktop: 130,
                            ),
                            width: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile:
                                  0, // Not used since we check isTablet first
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
                    'Sign up your Account',
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
                    'Securely sign up and enjoy a seamless experience\nwith us!',
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
                  // ---------- NEW: Circular avatar picker ----------
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: GetResponsiveSize.getResponsiveSize(
                              context,
                              mobile: 48,
                              tablet: 64,
                              largeTablet: 75,
                              desktop: 85,
                            ),
                            backgroundColor:
                                AppColors.primaryColor.withOpacity(.1),
                            backgroundImage: _avatarBytes != null
                                ? MemoryImage(_avatarBytes!)
                                : null,
                            child: _avatarBytes == null
                                ? Icon(
                                    Icons.person,
                                    size: GetResponsiveSize.getResponsiveSize(
                                      context,
                                      mobile: 48,
                                      tablet: 64,
                                      largeTablet: 75,
                                      desktop: 85,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: GetResponsiveSize.getResponsiveSize(
                                    context,
                                    mobile: 2,
                                    tablet: 3,
                                    largeTablet: 3,
                                    desktop: 4,
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.all(
                                GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 6,
                                  tablet: 8,
                                  largeTablet: 10,
                                  desktop: 12,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  largeTablet: 24,
                                  desktop: 28,
                                ),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
                  Center(
                    child: Text(
                      'Add profile photo',
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 14.0, // Keep mobile unchanged
                          tablet: 20.0,
                          largeTablet: 25.0,
                          desktop: 30.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<SignupBloc, SignupState>(
                    builder: (context, state) {
                      return Form(
                        key: _signupFormKey,
                        child: Column(
                          children: [
                            _buildNameField(),
                            SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 10, // Keep mobile unchanged
                                tablet: 20,
                                largeTablet: 25,
                                desktop: 30,
                              ),
                            ),
                            _buildEmailField(),
                            SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 10, // Keep mobile unchanged
                                tablet: 20,
                                largeTablet: 25,
                                desktop: 30,
                              ),
                            ),
                            _buildPhoneField(),
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
                            const SizedBox(height: 10),
                            _buildButton(state)
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return GetInput(
      label: "Name",
      initialValue: '',
      onSaved: (value) => _name = value!,
    );
  }

  Widget _buildEmailField() {
    return GetInput(
      label: "Email",
      initialValue: '',
      onSaved: (value) => _email = value!,
      isEmail: true,
    );
  }

  Widget _buildPhoneField() {
    return GetInput(
      label: "Phone Number",
      initialValue: '',
      onSaved: (value) => _phone = value!,
      isPhone: true,
    );
  }

  Widget _buildPasswordField() {
    return GetInput(
      label: "Password",
      initialValue: '',
      onSaved: (value) => _password = value!,
      isPassword: true,
      isSignupPassword: true,
    );
  }

  Widget _buildButton(SignupState state) {
    return Column(
      children: [
        SizedBox(
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: state is Loading ? null : _signUp,
            child: state is Loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Text(
                    "SignUp",
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
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
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
            GestureDetector(
              onTap: () {
                context.go('/login');
              },
              child: Text(
                'Login',
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
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
