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
  final TextEditingController _forgotPasswordEmailController =
      TextEditingController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _forgotPasswordFormKey = GlobalKey<FormState>();

  /// false = phone mode (default), true = email mode
  bool _emailMode = false;

  void _toggleMode() {
    setState(() {
      _emailMode = !_emailMode;
      _usernameController.clear(); // avoid mixing old value
    });
  }

  void _showForgotPasswordDialog() {
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

  void _handleForgotPassword() {
    final email = _forgotPasswordEmailController.text.trim();

    // Dispatch forgot password event to BLoC
    context.read<LoginBloc>().add(LoginEvent.forgotPassword(email: email));
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
                    const SizedBox(height: 10),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blackColor1),
              )),
              Center(
                child: TextButton(
                  onPressed: _toggleMode,
                  child: Text(
                    // 'Login with Email',
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
    // return GetInput(
    //   label: "Username",
    //   controller: _usernameController,
    //   isEmail: false,
    //   isPhone: true,
    //   onSaved: (value) {},
    // );
    // In email mode: label/email validation; In phone mode: label/phone validation
    return GetInput(
      label: _emailMode ? "Email" : "Phone",
      controller: _usernameController,
      isEmail: _emailMode,
      isPhone: !_emailMode,
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

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showForgotPasswordDialog,
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 14,
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
          failure: (message) => DialogUtil.showErrorDialog(context, message),
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
                content: Text('Error: $message'),
                backgroundColor: Colors.red,
              ),
            );
          },
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
