import 'package:ado_dad_user/common/api_response.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/services/auth_service.dart';
import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      // baseUrl: 'https://uat.ado-dad.com/',
      baseUrl: '${AppConfig.baseUrl}/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _initializeInterceptors();
  }

  Dio get dio {
    return _dio;
  }

  /// Prepares the Authorization header with the token
  /// Set useBearerPrefix to true if API expects "Bearer <token>", false if it expects just the token
  /// Most REST APIs use "Bearer " prefix, but some APIs don't
  static const bool _useBearerPrefix =
      true; // Set to false if API expects just the token without "Bearer "

  String _prepareAuthHeader(String token) {
    // Remove "Bearer " prefix if present to get clean token
    final cleanToken = token.replaceFirst(RegExp(r'^Bearer\s+'), '');

    // Add "Bearer " prefix if configured to use it
    if (_useBearerPrefix) {
      return 'Bearer $cleanToken';
    } else {
      return cleanToken;
    }
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('🌐 API ${options.method} ${options.uri}');

          // Get token from SharedPreferences - if it exists, use it
          // Token from login should work directly - only refresh when we get 401 (token expired)
          // After token refresh, new token is saved and will be used for subsequent requests
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            // API expects "Bearer <token>" format in Authorization header
            final authHeader = _prepareAuthHeader(token);
            options.headers['Authorization'] = authHeader;
            print('🔑 Using token for request to: ${options.uri}');
            print('🔑 Token length: ${token.length} chars');
            print(
                '🔑 Token first 30 chars: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
            print(
                '🔑 Authorization header format: ${authHeader.substring(0, authHeader.length > 30 ? 30 : authHeader.length)}...');
          } else {
            // No token found - proceed without Authorization header
            // Public endpoints like /v2/ads/list work without authentication
            print(
                'ℹ️ No token found for request to: ${options.uri} - proceeding without authentication');
          }
          // If no token, proceed without Authorization header (public endpoints don't need it)
          // This allows unauthenticated users to browse listings
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          print(
            '❌ ${e.response?.statusCode ?? 'ERR'} ${e.requestOptions.method} ${e.requestOptions.uri} — ${e.message}',
          );
          if (e.response?.statusCode == 401) {
            // Token expired or invalid - try to refresh it
            final authService = AuthService();

            print('🔄 Received 401 Unauthorized for: ${e.requestOptions.uri}');
            print('📋 401 Response details:');
            print('   Status Code: ${e.response?.statusCode}');
            print('   Response Data: ${e.response?.data}');
            print('   Request Headers: ${e.requestOptions.headers}');
            print(
                '   Authorization header sent: ${e.requestOptions.headers['Authorization']?.toString().substring(0, 30) ?? 'NOT SET'}...');

            // Check if token exists before attempting refresh
            final currentToken = await getToken();
            if (currentToken == null || currentToken.isEmpty) {
              // No token exists - this is an unauthenticated request
              // If endpoint requires auth, reject the error (user needs to login)
              // If endpoint is public, this shouldn't happen, but handle gracefully
              print('ℹ️ No token found in storage - unauthenticated request');
              print(
                  'ℹ️ If this endpoint requires authentication, user needs to login');
              return handler.reject(e);
            }

            // If the token in storage already differs from the one this
            // request was sent with, another request has refreshed it in the
            // meantime — just retry with the stored token, don't refresh again.
            final sentAuthHeader =
                e.requestOptions.headers['Authorization']?.toString();
            final storedAuthHeader = _prepareAuthHeader(currentToken);
            if (sentAuthHeader != null && sentAuthHeader != storedAuthHeader) {
              print(
                  '🔁 Token already refreshed by another request — retrying with stored token');
              e.requestOptions.headers['Authorization'] = storedAuthHeader;
              try {
                final retryResponse = await _dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              } catch (retryError) {
                return handler.reject(retryError is DioException
                    ? retryError
                    : DioException(
                        requestOptions: e.requestOptions,
                        type: DioExceptionType.unknown,
                        error: retryError,
                      ));
              }
            }

            print('🔄 Token exists, attempting to refresh...');

            // Try to refresh the token
            final newToken = await authService.refreshAccessToken();

            if (newToken != null && newToken.isNotEmpty) {
              // Token refreshed successfully, retry the original request
              print(
                  '✅ Token refreshed successfully, retrying original request...');

              // Mark initial refresh as done if this is the first refresh after login
              if (!authService.hasDoneInitialRefresh) {
                authService.markInitialRefreshDone();
              }

              // Update the Authorization header with the new token
              // API expects "Bearer <token>" format in Authorization header
              e.requestOptions.headers['Authorization'] =
                  _prepareAuthHeader(newToken);

              // Verify the new token is being used for retry
              print('🔄 Retrying request with new token...');
              print('🔑 New token length: ${newToken.length} chars');
              print(
                  '🔑 New token first 30 chars: ${newToken.substring(0, newToken.length > 30 ? 30 : newToken.length)}...');

              // Verify the token in storage matches what we're using
              final storedToken = await getToken();
              if (storedToken != null && storedToken == newToken) {
                print(
                    '✅ Confirmed: Stored token matches new token - will be used for all subsequent API calls');
              } else {
                print('⚠️ WARNING: Stored token does not match new token!');
              }

              try {
                final retryResponse = await _dio.fetch(e.requestOptions);
                print('✅ Request retry successful after token refresh');
                print(
                    '✅ New token is now active and will be used for all future API calls');
                return handler.resolve(retryResponse);
              } catch (retryError) {
                print(
                    '❌ Request retry failed after token refresh: $retryError');
                return handler.reject(retryError is DioException
                    ? retryError
                    : DioException(
                        requestOptions: e.requestOptions,
                        type: DioExceptionType.unknown,
                        error: retryError,
                      ));
              }
            } else {
              // Refresh failed - refresh token expired or invalid
              // AuthService will handle logout automatically
              print(
                  '⚠️ Token refresh failed - refresh token expired or invalid');
              print('⚠️ User will be logged out automatically');

              // If logout is in progress, suppress the error to avoid showing it in UI
              if (authService.isLoggingOut) {
                // Create a silent error that won't be shown to users
                final silentError = DioException(
                  requestOptions: e.requestOptions,
                  type: DioExceptionType.badResponse,
                  response: e.response,
                  error: 'Token expired - automatic logout in progress',
                );
                return handler.reject(silentError);
              }

              // Don't proceed with the original request
              return handler.reject(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}

class ApiErrorHandler {
  static ApiResponse handleError(DioException e) {
    if (e.response != null) {
      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('message')) {
        final message = responseData['message'];

        if (message is List<dynamic>) {
          return ApiResponse(success: false, message: message.join("\n"));
        }
        return ApiResponse(success: false, message: message.toString());
      }

      return ApiResponse(
          success: false,
          message: "An error occurred: ${e.response?.statusCode}");
    } else {
      return ApiResponse(
          success: false, message: "Network error: ${e.message}");
    }
  }
}

class DioErrorHandler {
  static String handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "❌ Connection timeout. Please check your internet.";
      case DioExceptionType.receiveTimeout:
        return "❌ Receive timeout. Server is too slow.";
      case DioExceptionType.sendTimeout:
        return "❌ Send timeout. Please try again.";
      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);
      case DioExceptionType.cancel:
        return "❌ Request was cancelled.";
      case DioExceptionType.connectionError:
        return "❌ No internet connection. Check your network.";
      case DioExceptionType.unknown:
      default:
        return "❌ Unexpected error: ${e.message}";
    }
  }

  // static String _handleBadResponse(Response? response) {
  //   if (response == null) return "❌ No response from server.";

  //   switch (response.statusCode) {
  //     case 400:
  //       return "❌ Bad request. Please try again.";
  //     case 401:
  //       return "❌ Unauthorized. Please log in again.";
  //     case 403:
  //       return "❌ Forbidden. You don't have permission.";
  //     case 404:
  //       return "❌ Not found. The requested resource doesn't exist.";
  //     case 500:
  //       return "❌ Internal server error. Try again later.";
  //     default:
  //       return "❌ Error ${response.statusCode}: ${response.statusMessage}";
  //   }
  // }

  static String _handleBadResponse(Response? response) {
    if (response == null) return "❌ No response from server.";
    print('response:........................${response.data}');
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        // If backend sends custom error message like: { error: "Some message" }
        if (data.containsKey('error') && data['error'] is String) {
          return "❌ ${data['error']}";
        }
        // Optional: handle 'message' key or others if used
        if (data.containsKey('message')) {
          final message = data['message'];
          if (message is String) {
            return "❌ $message";
          } else if (message is List) {
            return "❌ ${message.join("\n")}";
          }
        }
      }
    } catch (e) {
      // Silent catch if the body is not parseable
      print("⚠️ Error parsing response data: $e");
    }

    // Fall back to status-based messages
    switch (response.statusCode) {
      case 400:
        return "❌ Bad request. Please check input and try again.";
      case 401:
        return "❌ Unauthorized. Please log in again.";
      case 403:
        return "❌ Forbidden. You don't have permission.";
      case 404:
        return "❌ Not found. The resource doesn't exist.";
      case 500:
        return "❌ Server error. Please try again later.";
      default:
        return "❌ Error ${response.statusCode}: ${response.statusMessage}";
    }
  }
}
