import 'dart:async';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/features/login/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _navigationTimer;
  Timer? _fallbackTimer;
  bool _canNavigate = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Set a minimum splash screen duration of 3 seconds
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      _canNavigate = true;
      _checkLoginAndNavigate();
    });

    // Fallback timer to ensure navigation happens after 5 seconds
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/login'); // Default to login page
      }
    });

    // Check login status and navigate accordingly
    _checkLoginAndNavigate();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _checkLoginAndNavigate() {
    // Check current login state immediately
    final currentState = context.read<LoginBloc>().state;
    if (_canNavigate) {
      _navigateBasedOnState(currentState);
    }

    // Listen to future login state changes
    context.read<LoginBloc>().stream.listen((loginState) {
      if (mounted && _canNavigate) {
        _navigateBasedOnState(loginState);
      }
    });
  }

  void _navigateBasedOnState(dynamic loginState) {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    loginState.when(
      initial: () {
        // User is not logged in, go to login page
        context.go('/login');
      },
      loading: () {
        // Still checking, wait
      },
      success: (username) {
        // User is logged in, go to home page
        context.go('/home');
      },
      failure: (message) {
        // Login check failed, go to login page
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo image
            Image.asset('assets/images/d-vector.png', height: 50, width: 50),
            SizedBox(width: 15),
            // Title image aligned to center
            Center(
              child: Image.asset('assets/images/Ado Dad SplashTitle.png'),
            ),
          ],
        ),
      ),
    );
  }
}
