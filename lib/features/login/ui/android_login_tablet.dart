import 'package:ado_dad_user/features/login/ui/login_page.dart';
import 'package:flutter/material.dart';

class AndroidLoginTablet extends StatefulWidget {
  const AndroidLoginTablet({super.key});

  @override
  State<AndroidLoginTablet> createState() => _AndroidLoginTabletState();
}

class _AndroidLoginTabletState extends State<AndroidLoginTablet> {
  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   body: Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
    //     child: Center(
    //       child: SingleChildScrollView(
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Image.asset('assets/images/Ado-dad.png'),
    //             const SizedBox(height: 30),
    //             Text(
    //               'Login to your Account',
    //               style: GoogleFonts.poppins(
    //                   fontSize: 40,
    //                   fontWeight: FontWeight.w600,
    //                   color: Colors.black),
    //             ),
    //             Text(
    //               'Securely log in and enjoy a seamless experience\nwith us!',
    //               style: GoogleFonts.poppins(fontSize: 20, color: Colors.black),
    //             ),
    //             const SizedBox(height: 30),
    //             Form(
    //               key: _loginFormKey,
    //               child: Column(
    //                 children: [
    //                   _buildUsernameField(),
    //                   const SizedBox(height: 30),
    //                   _buildPasswordField(),
    //                   const SizedBox(height: 35),
    //                   _buildButton(),
    //                 ],
    //               ),
    //             ),
    //             const SizedBox(height: 30),
    //             Center(
    //                 child: Text(
    //               'Or',
    //               style: TextStyle(
    //                   fontSize: 20,
    //                   fontWeight: FontWeight.w500,
    //                   color: AppColors.blackColor1),
    //             )),
    //             Center(
    //               child: TextButton(
    //                 onPressed: () {},
    //                 child: Text(
    //                   'Login with Email',
    //                   style: TextStyle(
    //                       decoration: TextDecoration.underline,
    //                       fontSize: 25,
    //                       fontWeight: FontWeight.w500,
    //                       color: AppColors.blackColor1),
    //                 ),
    //               ),
    //             ),
    //             const SizedBox(height: 25),
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               children: [
    //                 Text('New User?',
    //                     style: TextStyle(
    //                         fontSize: 20,
    //                         fontWeight: FontWeight.w500,
    //                         color: AppColors.blackColor)),
    //                 GestureDetector(
    //                   onTap: () {
    //                     context.go('/signup');
    //                   },
    //                   child: Text('Signup',
    //                       style: TextStyle(
    //                           fontSize: 20,
    //                           fontWeight: FontWeight.w500,
    //                           color: AppColors.primaryColor)),
    //                 )
    //               ],
    //             ),
    //             const SizedBox(height: 200),
    //             Center(
    //               child: GestureDetector(
    //                 child: Text(
    //                   'Terms & Conditions',
    //                   style: TextStyle(
    //                       fontWeight: FontWeight.w500,
    //                       fontSize: 16,
    //                       color: AppColors.primaryColor),
    //                 ),
    //               ),
    //             )
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    return LoginPage();
  }
}
