import 'dart:async';

import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';
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
      print('⏳ Token refresh already in progress, waiting for completion...');
      return _refreshCompleter!.future;
    }

    // Create a completer for this refresh operation
    _refreshCompleter = Completer<String?>();
    _isRefreshing = true;

    print('🔄 Starting token refresh...');

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No refresh token found in SharedPreferences');
        _isRefreshing = false;
        _refreshCompleter?.complete(null);
        _refreshCompleter = null;
        return null;
      }

      // Remove "Bearer " prefix from refresh token if present (refresh token should be sent without prefix)
      final cleanRefreshToken =
          refreshToken.replaceFirst(RegExp(r'^Bearer\s+'), '');

      print('📋 Refresh Token from SharedPreferences:');
      print('═══════════════════════════════════════');
      print(refreshToken);
      print('═══════════════════════════════════════');
      print('🔄 Refresh token from SharedPreferences:');
      print('   Length: ${cleanRefreshToken.length} characters');
      print(
          '   First 50 chars: ${cleanRefreshToken.length > 50 ? cleanRefreshToken.substring(0, 50) + "..." : cleanRefreshToken}');

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

      print('🔄 Attempting to refresh access token...');
      print('📤 Endpoint: $baseUrl/refresh-token');
      print('📤 Request body format: {"refreshToken": "<token_value>"}');
      print(
          '📤 Refresh token value (first 30 chars): ${cleanRefreshToken.substring(0, cleanRefreshToken.length > 30 ? 30 : cleanRefreshToken.length)}...');

      final response = await dio.post(
        '/refresh-token',
        data: {'refreshToken': cleanRefreshToken},
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      // Check response status code (success is 201 for refresh token endpoint)
      if (response.statusCode == 201 || response.statusCode == 200) {
        final newAccessToken = response.data['token'] as String?;
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Remove "Bearer " prefix if present (we'll add it in ApiService if needed)
          final cleanToken =
              newAccessToken.replaceFirst(RegExp(r'^Bearer\s+'), '');

          // Save the new token to SharedPreferences - ensure it's saved before proceeding
          await SharedPrefs().setString('token', cleanToken);

          // Immediately verify it was saved (no await needed for getString, but we await to ensure it's written)
          final verifyToken = await SharedPrefs().getString('token');
          if (verifyToken == cleanToken) {
            print('✅ Access token refreshed successfully and saved');
            print('✅ Token immediately verified in storage');
          } else {
            print('⚠️ WARNING: Token saved but verification failed!');
          }

          // If response also includes new refresh token, save it
          final newRefreshToken = response.data['refreshToken'] as String?;
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            // Remove "Bearer " prefix from refresh token if present
            final cleanNewRefreshToken =
                newRefreshToken.replaceFirst(RegExp(r'^Bearer\s+'), '');
            await SharedPrefs().setString('refreshToken', cleanNewRefreshToken);
            print('✅ New refresh token also saved');
          }

          print('✅ New Bearer Token received:');
          print('═══════════════════════════════════════');
          print(cleanToken);
          print('═══════════════════════════════════════');

          // Verify the new token was saved and can be retrieved
          final savedToken = await getToken();
          final isSaved = savedToken != null && savedToken == cleanToken;
          print(
              '💾 Token saved in SharedPreferences: ${isSaved ? "✅ YES" : "❌ NO"}');
          if (isSaved) {
            // savedToken is guaranteed to be non-null here because isSaved checks for null
            print('💾 Saved token length: ${savedToken.length} chars');
            print(
                '💾 Saved token first 30 chars: ${savedToken.substring(0, savedToken.length > 30 ? 30 : savedToken.length)}...');
            print('💾 New token will be used for all subsequent API calls');
          } else {
            print(
                '⚠️ WARNING: Token was not saved correctly or cannot be retrieved!');
            if (savedToken != null) {
              print('⚠️ Retrieved token length: ${savedToken.length} chars');
              print('⚠️ Expected token length: ${cleanToken.length} chars');
            }
          }

          _isRefreshing = false;
          _refreshCompleter?.complete(cleanToken);
          _refreshCompleter = null;
          return cleanToken;
        }
      }

      // If we reach here, refresh failed - check if it's due to expired refresh token
      print('❌ Token refresh failed');
      print('═══════════════════════════════════════');
      print('📋 Summary:');
      print('   - Refresh token exists in SharedPreferences: ✅ YES');
      print(
          '   - Server response: ${response.statusCode} ${response.statusCode == 401 ? "Unauthorized" : response.statusCode == 403 ? "Forbidden" : "Error"}');

      // Check if refresh token expired (401 Unauthorized or 403 Forbidden)
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('   - Reason: Refresh token has EXPIRED on server');
        print('   - Action: User needs to login again to get new tokens');
        print('═══════════════════════════════════════');

        // Check if refresh token is still in storage after failed attempt
        final refreshTokenAfter = await getRefreshToken();
        print(
            '💾 Refresh token still in SharedPreferences after failure: ${refreshTokenAfter != null && refreshTokenAfter.isNotEmpty ? "✅ YES (still stored locally)" : "❌ NO"}');
        print(
            '   ℹ️ This is normal - expired tokens remain in storage until logout/clearUserData()');
        print(
            '   ℹ️ The token exists locally but server rejects it because it has expired');
        print('═══════════════════════════════════════');

        print(
            '⚠️ Refresh token expired or invalid (status: ${response.statusCode}), triggering automatic logout...');
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
      print('⚠️ Token refresh failed with status ${response.statusCode}');
      final result = null;
      _isRefreshing = false;
      _refreshCompleter?.complete(result);
      _refreshCompleter = null;
      return result;
    } catch (e) {
      // Handle network errors or other exceptions
      print('❌ Error refreshing token: $e');
      final result = null;
      _isRefreshing = false;

      // For network errors, don't logout - might be temporary connection issue
      // Only logout if we get a DioException with 401/403 status
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          print(
              '⚠️ Refresh token expired (DioException), triggering automatic logout...');
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
      print('🚪 Automatic logout triggered due to token expiration');

      // Reset initial refresh flag
      resetInitialRefreshFlag();

      // Disconnect chat socket to prevent using old user's token
      try {
        await ChatSocketService().disconnect();
        print('🔌 Chat socket disconnected on logout');
      } catch (e) {
        print('⚠️ Error disconnecting chat socket: $e');
      }

      // Clear all user data
      await clearUserData();

      // Navigate to login page using GoRouter
      // We need to use the router instance
      final router = AppRoutes.router;
      if (router.canPop()) {
        // If we can pop, pop until we reach the root
        while (router.canPop()) {
          router.pop();
        }
      }

      // Navigate to login page
      router.go('/login');

      print('✅ User automatically logged out and redirected to login');
    } catch (e) {
      print('❌ Error during automatic logout: $e');
    } finally {
      // Reset flag after a delay to allow navigation to complete
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }

  /// Manual logout (called by user action)
  Future<void> logout() async {
    // Reset initial refresh flag
    resetInitialRefreshFlag();

    // Disconnect chat socket to prevent using old user's token
    try {
      await ChatSocketService().disconnect();
      print('🔌 Chat socket disconnected on logout');
    } catch (e) {
      print('⚠️ Error disconnecting chat socket: $e');
    }

    await clearUserData();

    final router = AppRoutes.router;
    if (router.canPop()) {
      while (router.canPop()) {
        router.pop();
      }
    }

    router.go('/login');
  }

  /// Reset refresh state (useful for testing or manual refresh)
  void resetRefreshState() {
    _isRefreshing = false;
    _refreshCompleter = null;
  }
}
