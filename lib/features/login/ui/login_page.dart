import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:ado_dad_user/common/widgets/get_input.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
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
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
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
                'Login to your Account',
                style: AppTextstyle.title1,
              ),
              const Text(
                  'Securely log in and enjoy a seamless experience\nwith us!'),
              const SizedBox(height: 20),
              Form(
                key: _loginFormKey,
                child: Column(
                  children: [
                    _buildUsernameField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 20),
                    _buildButton(),
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
                  onPressed: () {},
                  child: Text(
                    'Login with Email',
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
              const SizedBox(height: 100),
              Center(
                child: GestureDetector(
                  child: Text(
                    'Terms & Conditions',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: AppColors.primaryColor),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return GetInput(
      label: "Username",
      controller: _usernameController,
      isEmail: false,
      isPhone: true,
      onSaved: (value) {},
    );
  }

  Widget _buildPasswordField() {
    return GetInput(
      label: "Password",
      controller: _passwordController,
      isPassword: true,
      onSaved: (value) {},
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
          failure: (message) => DialogUtil.showErrorDialog(context, message),
          orElse: () {},
        );
      },
      builder: (context, state) {
        return SizedBox(
          height: 55,
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
              style: AppTextstyle.buttonText,
            ),
          ),
        );
      },
    );
  }
}
