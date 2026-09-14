import 'dart:async';

import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/secure_token_store.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/features/home/bloc/advertisement_bloc.dart';
import 'package:ado_dad_user/services/chat_socket_service.dart';
import 'package:dio/dio.dart';

/// Centralized authentication service for token refresh and automatic logout
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Track if we're currently refreshing to avoid multiple simultaneous refresh attempts
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  // Track if we've done the initial refresh after login (only refresh once on first API call)
  bool _hasDoneInitialRefresh = false;

  // Track if automatic logout is in progress to suppress error UI
  bool _isLoggingOut = false;

  /// Check if automatic logout is in progress
  bool get isLoggingOut => _isLoggingOut;

  /// Check if initial refresh has been done
  bool get hasDoneInitialRefresh => _hasDoneInitialRefresh;

  /// Mark initial refresh as done (called after first API call refresh)
  void markInitialRefreshDone() {
    _hasDoneInitialRefresh = true;
  }

  /// Reset initial refresh flag (called on logout)
  void resetInitialRefreshFlag() {
    _hasDoneInitialRefresh = false;
  }

  /// Refresh the access token using the refresh token
  /// Returns the new access token if successful, null if refresh token expired
  /// If a refresh is already in progress, waits for that refresh to complete
  Future<String?> refreshAccessToken() async {
    // If already refreshing, wait for the ongoing refresh to complete
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    // Create a completer for this refresh operation
    _refreshCompleter = Completer<String?>();
    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _isRefreshing = false;
        _refreshCompleter?.complete(null);
        _refreshCompleter = null;
        return null;
      }

      // Remove "Bearer " prefix from refresh token if present (refresh token should be sent without prefix)
      final cleanRefreshToken =
          refreshToken.replaceFirst(RegExp(r'^Bearer\s+'), '');

      final baseUrl = AppConfig.baseUrl;
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        // baseUrl: 'https://4ea93026a29f.ngrok-free.app/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        // Allow 401 responses to be returned instead of throwing exceptions
        // This allows us to handle refresh token expiration gracefully
        validateStatus: (status) {
          // Return true for all status codes so we can handle them manually
          // This prevents Dio from throwing exceptions for 401/403 responses
          return true;
        },
      ));

      final response = await dio.post(
        '/refresh-token',
        data: {'refreshToken': cleanRefreshToken},
      );

      // Check response status code (success is 201 for refresh token endpoint)
      if (response.statusCode == 201 || response.statusCode == 200) {
        final newAccessToken = response.data['token'] as String?;
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Remove "Bearer " prefix if present (we'll add it in ApiService if needed)
          final cleanToken =
              newAccessToken.replaceFirst(RegExp(r'^Bearer\s+'), '');

          // Save the new token to the keystore - ensure it's saved before proceeding
          await SecureTokenStore().setToken(cleanToken);

          // If response also includes new refresh token, save it
          final newRefreshToken = response.data['refreshToken'] as String?;
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            // Remove "Bearer " prefix from refresh token if present
            final cleanNewRefreshToken =
                newRefreshToken.replaceFirst(RegExp(r'^Bearer\s+'), '');
            await SecureTokenStore().setRefreshToken(cleanNewRefreshToken);
          }

          _isRefreshing = false;
          _refreshCompleter?.complete(cleanToken);
          _refreshCompleter = null;
          return cleanToken;
        }
      }

      // If we reach here, refresh failed - check if it's due to expired refresh token

      // Check if refresh token expired (401 Unauthorized or 403 Forbidden)
      if (response.statusCode == 401 || response.statusCode == 403) {
        final result = null;
        _isRefreshing = false;
        _refreshCompleter?.complete(result);
        _refreshCompleter = null;
        // Set logout flag before calling handleTokenExpiration to suppress errors
        _isLoggingOut = true;
        // Don't await here to avoid blocking - logout will handle navigation
        handleTokenExpiration();
        return result;
      }

      // For other error status codes (500, etc.), don't logout, just return null
      final result = null;
      _isRefreshing = false;
      _refreshCompleter?.complete(result);
      _refreshCompleter = null;
      return result;
    } catch (e) {
      // Handle network errors or other exceptions
      final result = null;
      _isRefreshing = false;

      // For network errors, don't logout - might be temporary connection issue
      // Only logout if we get a DioException with 401/403 status
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          // Set logout flag before calling handleTokenExpiration to suppress errors
          _isLoggingOut = true;
          handleTokenExpiration();
        }
      }

      _refreshCompleter?.complete(result);
      _refreshCompleter = null;
      return result;
    }
  }

  /// Handle token expiration by clearing user data and navigating to login
  Future<void> handleTokenExpiration() async {
    try {
      // Flag is already set before calling this method

      // Reset initial refresh flag
      resetInitialRefreshFlag();

      // Disconnect socket connection
      await ChatSocketService().disconnect();

      // Clear all user data
      await clearUserData();

      // Drop the ad feeds and their cached pages — they belong to the session
      // that just ended.
      AdvertisementBloc.resetAll();

      // Navigate to login page using GoRouter. `.go()` replaces the whole
      // navigation stack, so no need to pop pages first (the old
      // `while (canPop()) pop()` loop could pop the last page and throw).
      AppRoutes.router.go('/login');
    } catch (_) {
    } finally {
      // Reset flag after a delay to allow navigation to complete
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }

  /// Manual logout (called by user action).
  ///
  /// Clears the socket connection and all stored auth/user data, then
  /// navigates to [redirectTo]. The data clear is fully awaited BEFORE
  /// navigation so the destination route never sees a stale token.
  ///
  /// Defaults to '/login' (used by automatic token-expiry logout). The manual
  /// logout button passes '/home' so the user lands on the home screen as a
  /// guest (the app allows browsing without login).
  Future<void> logout({String redirectTo = '/login'}) async {
    // Reset initial refresh flag
    resetInitialRefreshFlag();

    // Disconnect socket connection
    await ChatSocketService().disconnect();

    await clearUserData();

    // Drop the ad feeds and their cached pages — they belong to the session
    // that just ended.
    AdvertisementBloc.resetAll();

    // go_router's `.go()` replaces the entire navigation stack with the target
    // location's stack, so there's no need to pop pages first. The previous
    // `while (canPop()) pop()` loop could pop the last remaining page and throw
    // "You have popped the last page off of the stack".
    AppRoutes.router.go(redirectTo);
  }

  /// Reset refresh state (useful for testing or manual refresh)
  void resetRefreshState() {
    _isRefreshing = false;
    _refreshCompleter = null;
  }
}
