import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/signup/bloc/signup_bloc.dart';
import 'package:ado_dad_user/models/signup_model.dart';
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

      context.read<SignupBloc>().add(SignupEvent.signup(data: signupData));
      Future.delayed(const Duration(milliseconds: 500), () {
        _showSuccessPopup(context, "You have been successfully SignedUp");
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
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
        onPressed: _signUp,
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
