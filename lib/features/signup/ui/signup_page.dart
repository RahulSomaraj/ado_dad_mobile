import 'dart:typed_data';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
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
      body: Padding(
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
                Image.asset('assets/images/Ado-dad.png'),
                const SizedBox(height: 30),
                Text(
                  'Sign up your Account',
                  style: AppTextstyle.title1,
                ),
                const Text(
                    'Securely sign up and enjoy a seamless experience\nwith us!'),
                const SizedBox(height: 20),
                // ---------- NEW: Circular avatar picker ----------
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              AppColors.primaryColor.withOpacity(.1),
                          backgroundImage: _avatarBytes != null
                              ? MemoryImage(_avatarBytes!)
                              : null,
                          child: _avatarBytes == null
                              ? const Icon(Icons.person, size: 48)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: Text('Add profile photo')),
                const SizedBox(height: 20),
                BlocBuilder<SignupBloc, SignupState>(
                  builder: (context, state) {
                    return Form(
                      key: _signupFormKey,
                      child: Column(
                        children: [
                          _buildNameField(),
                          const SizedBox(height: 10),
                          _buildEmailField(),
                          const SizedBox(height: 10),
                          _buildPhoneField(),
                          const SizedBox(height: 10),
                          _buildPasswordField(),
                          const SizedBox(height: 20),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: state is Loading ? null : _signUp,
        child: state is Loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.whiteColor),
              )
            : const Text("SignUp",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
