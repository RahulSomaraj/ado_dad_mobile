import 'dart:async';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
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
      debugPrint('⏰ [SplashScreen] Fallback timer fired');
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        debugPrint('🚀 [SplashScreen] Navigating to /login (fallback)');
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
    if (!mounted || _hasNavigated) {
      return;
    }

    // Only navigate for core login states, ignore forgot password states
    if (loginState is Initial) {
      _hasNavigated = true;
      context.go('/login');
    } else if (loginState is Loading) {
      // Still checking, wait
    } else if (loginState is Success) {
      _hasNavigated = true;
      context.go('/home');
    } else if (loginState is Failure) {
      _hasNavigated = true;
      context.go('/login');
    }
    // Ignore forgot password states - they shouldn't trigger navigation
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo image with responsive sizing - add error handling
              Builder(
                builder: (context) {
                  try {
                    return Image.asset(
                      'assets/images/ado-d.png',
                      height: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 80,
                        tablet: 120,
                        largeTablet: 140,
                        desktop: 160,
                      ),
                      width: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 80,
                        tablet: 120,
                        largeTablet: 140,
                        desktop: 160,
                      ),
                      errorBuilder: (context, error, stackTrace) {
                        print(
                            '❌ [SplashScreen] Error loading ado-d.png: $error');
                        return const Icon(Icons.error,
                            size: 80, color: Colors.white);
                      },
                    );
                  } catch (e) {
                    print('❌ [SplashScreen] Exception loading image: $e');
                    return const Icon(Icons.error,
                        size: 80, color: Colors.white);
                  }
                },
              ),
              SizedBox(
                height: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 30,
                  tablet: 30,
                  largeTablet: 40,
                  desktop: 50,
                ),
              ),
              // Title image aligned to center with responsive sizing - add error handling
              Center(
                child: Builder(
                  builder: (context) {
                    try {
                      return GetResponsiveSize.isTablet(context)
                          ? SizedBox(
                              height: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile:
                                    0, // Not used since we check isTablet first
                                tablet: 80,
                                largeTablet: 100,
                                desktop: 120,
                              ),
                              child: Image.asset(
                                'assets/images/adodad-v1.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      '❌ [SplashScreen] Error loading adodad-v1.png: $error');
                                  return const Text('ADO-DAD',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 24));
                                },
                              ),
                            )
                          : SizedBox(
                              width: GetResponsiveSize.getResponsiveSize(
                                context,
                                mobile: 250,
                                tablet: 300,
                                largeTablet: 350,
                                desktop: 400,
                              ),
                              child: Image.asset(
                                'assets/images/adodad-v1.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      '❌ [SplashScreen] Error loading adodad-v1.png: $error');
                                  return const Text('ADO-DAD',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 24));
                                },
                              ),
                            );
                    } catch (e) {
                      print('❌ [SplashScreen] Exception in title image: $e');
                      return const Text('ADO-DAD',
                          style: TextStyle(color: Colors.white, fontSize: 24));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ [SplashScreen] CRITICAL ERROR in build(): $e');
      print('❌ [SplashScreen] Stack: $stackTrace');
      // Return a simple fallback widget
      return Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              Text('Error: $e', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }
}
