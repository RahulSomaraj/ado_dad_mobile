import 'package:ado_dad_user/common/app_routes.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:dio/dio.dart';

/// Centralized authentication service for token refresh and automatic logout
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Track if we're currently refreshing to avoid multiple simultaneous refresh attempts
  bool _isRefreshing = false;
  String? _refreshTokenFuture;

  /// Refresh the access token using the refresh token
  /// Returns the new access token if successful, null if refresh token expired
  Future<String?> refreshAccessToken() async {
    // If already refreshing, wait for the ongoing refresh
    if (_isRefreshing && _refreshTokenFuture != null) {
      // Wait a bit and return the result if available
      await Future.delayed(const Duration(milliseconds: 100));
      return _refreshTokenFuture;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ No refresh token available');
        _isRefreshing = false;
        _refreshTokenFuture = null;
        return null;
      }

      final baseUrl = AppConfig.baseUrl;
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
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

      final response = await dio.post(
        '/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      // Check response status code
      if (response.statusCode == 200) {
        final newAccessToken = response.data['token'] as String?;
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await SharedPrefs().setString('token', newAccessToken);
          print('✅ Access token refreshed successfully');
          _refreshTokenFuture = newAccessToken;
          _isRefreshing = false;
          return newAccessToken;
        }
      }

      // If we reach here, refresh failed - check if it's due to expired refresh token
      print('❌ Token refresh failed: ${response.statusCode}');

      // Check if refresh token expired (401 Unauthorized or 403 Forbidden)
      if (response.statusCode == 401 || response.statusCode == 403) {
        print(
            '⚠️ Refresh token expired or invalid (status: ${response.statusCode}), triggering automatic logout...');
        _isRefreshing = false;
        _refreshTokenFuture = null;
        // Don't await here to avoid blocking - logout will handle navigation
        handleTokenExpiration();
        return null;
      }

      // For other error status codes (500, etc.), don't logout, just return null
      print('⚠️ Token refresh failed with status ${response.statusCode}');
      _isRefreshing = false;
      _refreshTokenFuture = null;
      return null;
    } catch (e) {
      // Handle network errors or other exceptions
      print('❌ Error refreshing token: $e');
      _isRefreshing = false;
      _refreshTokenFuture = null;

      // For network errors, don't logout - might be temporary connection issue
      // Only logout if we get a DioException with 401/403 status
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          print(
              '⚠️ Refresh token expired (DioException), triggering automatic logout...');
          handleTokenExpiration();
        }
      }

      return null;
    }
  }

  /// Handle token expiration by clearing user data and navigating to login
  Future<void> handleTokenExpiration() async {
    try {
      print('🚪 Automatic logout triggered due to token expiration');

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
    }
  }

  /// Manual logout (called by user action)
  Future<void> logout() async {
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
    _refreshTokenFuture = null;
  }
}
