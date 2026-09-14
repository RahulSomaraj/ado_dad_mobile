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
      // A flaky network used to spin for 30 s before surfacing an error; 10 s
      // is well past the p99 for these endpoints and fails fast enough that
      // the retry (or the error state) reaches the user while they're still
      // looking at the screen.
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
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
          // Get token from SharedPreferences - if it exists, use it
          // Token from login should work directly - only refresh when we get 401 (token expired)
          // After token refresh, new token is saved and will be used for subsequent requests
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            // API expects "Bearer <token>" format in Authorization header
            final authHeader = _prepareAuthHeader(token);
            options.headers['Authorization'] = authHeader;
          } else {
            // No token found - proceed without Authorization header
            // Public endpoints like /v2/ads/list work without authentication
          }
          // If no token, proceed without Authorization header (public endpoints don't need it)
          // This allows unauthenticated users to browse listings
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired or invalid - try to refresh it
            final authService = AuthService();

            // Check if token exists before attempting refresh
            final currentToken = await getToken();
            if (currentToken == null || currentToken.isEmpty) {
              // No token exists - this is an unauthenticated request
              // If endpoint requires auth, reject the error (user needs to login)
              // If endpoint is public, this shouldn't happen, but handle gracefully
              return handler.reject(e);
            }

            // If the token in storage already differs from the one this
            // request was sent with, another request has refreshed it in the
            // meantime — just retry with the stored token, don't refresh again.
            final sentAuthHeader =
                e.requestOptions.headers['Authorization']?.toString();
            final storedAuthHeader = _prepareAuthHeader(currentToken);
            if (sentAuthHeader != null && sentAuthHeader != storedAuthHeader) {
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

            // Try to refresh the token
            final newToken = await authService.refreshAccessToken();

            if (newToken != null && newToken.isNotEmpty) {
              // Token refreshed successfully, retry the original request
              // Mark initial refresh as done if this is the first refresh after login
              if (!authService.hasDoneInitialRefresh) {
                authService.markInitialRefreshDone();
              }

              // Update the Authorization header with the new token
              // API expects "Bearer <token>" format in Authorization header
              e.requestOptions.headers['Authorization'] =
                  _prepareAuthHeader(newToken);

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
            } else {
              // Refresh failed - refresh token expired or invalid
              // AuthService will handle logout automatically

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
    } catch (_) {
      // Silent catch if the body is not parseable
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
