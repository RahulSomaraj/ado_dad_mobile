import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/common/widgets/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Authentication helper utility with centralized helper functions
/// for checking authentication and showing login prompts
class AuthHelper {
  /// Check if user is authenticated
  /// Returns true if user has a valid token, false otherwise
  static Future<bool> isAuthenticated() async {
    return await AuthGuard.isAuthenticated();
  }

  /// Require authentication before executing a callback
  /// Shows login prompt if user is not authenticated
  /// Executes the callback if user is authenticated
  /// 
  /// Example:
  /// ```dart
  /// AuthHelper.requireAuth(
  ///   context,
  ///   onAuthenticated: () {
  ///     // User is authenticated, proceed with action
  ///     Navigator.push(context, MaterialPageRoute(...));
  ///   },
  /// );
  /// ```
  static Future<void> requireAuth(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
    String? redirectPath,
  }) async {
    final isAuth = await isAuthenticated();
    if (isAuth) {
      // User is authenticated, execute the callback
      onAuthenticated();
    } else {
      // User is not authenticated, show login prompt
      showLoginPrompt(
        context,
        message: message,
        redirectPath: redirectPath,
      );
    }
  }

  /// Show login prompt dialog
  /// Uses platform-specific design (iOS Cupertino, Android Material)
  /// 
  /// Example:
  /// ```dart
  /// AuthHelper.showLoginPrompt(
  ///   context,
  ///   message: "Please login to access this feature.",
  ///   redirectPath: '/profile',
  /// );
  /// ```
  static void showLoginPrompt(
    BuildContext context, {
    String? message,
    String? redirectPath,
  }) {
    DialogUtil.showLoginPromptDialog(
      context,
      message: message,
      redirectPath: redirectPath,
    );
  }

  /// Check authentication before navigating to a route
  /// Shows login prompt if not authenticated
  /// Navigates to route if authenticated
  /// 
  /// Example:
  /// ```dart
  /// AuthHelper.checkAuthAndNavigate(
  ///   context,
  ///   '/profile',
  /// );
  /// ```
  static Future<void> checkAuthAndNavigate(
    BuildContext context,
    String route, {
    String? message,
  }) async {
    final isAuth = await isAuthenticated();
    if (isAuth) {
      // User is authenticated, navigate to route
      context.push(route);
    } else {
      // User is not authenticated, show login prompt with redirect
      showLoginPrompt(
        context,
        message: message ?? "Please login to access this page.",
        redirectPath: route,
      );
    }
  }

  /// Check authentication and execute different callbacks based on auth status
  /// 
  /// Example:
  /// ```dart
  /// AuthHelper.checkAuth(
  ///   context,
  ///   onAuthenticated: () {
  ///     // User is authenticated
  ///     print('User is logged in');
  ///   },
  ///   onUnauthenticated: () {
  ///     // User is not authenticated
  ///     print('User is not logged in');
  ///   },
  /// );
  /// ```
  static Future<void> checkAuth(
    BuildContext context, {
    VoidCallback? onAuthenticated,
    VoidCallback? onUnauthenticated,
  }) async {
    final isAuth = await isAuthenticated();
    if (isAuth) {
      onAuthenticated?.call();
    } else {
      onUnauthenticated?.call();
    }
  }
}

