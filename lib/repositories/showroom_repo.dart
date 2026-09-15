import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/models/showroom_user_model.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:dio/dio.dart';

class ShowroomRepo {
  final Dio _dio = ApiService().dio;

  /// Fetches showroom users for authenticated users
  Future<List<ShowroomUser>> fetchShowroomUsers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get('/users', queryParameters: {
        'type': 'SR',
        'page': page,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> data;

        // Handle different response structures
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Check if data is wrapped in a 'data' field
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            data = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('users') &&
              responseData['users'] is List) {
            data = responseData['users'] as List<dynamic>;
          } else {
            throw Exception(
                "Unexpected response structure: expected List or Map with 'data'/'users' field");
          }
        } else {
          throw Exception(
              "Unexpected response type: ${responseData.runtimeType}");
        }

        final List<ShowroomUser> users = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final user = ShowroomUser.fromJson(data[i]);
            users.add(user);
          } catch (_) {}
        }

        // Check if there are more pages to fetch
        if (responseData is Map<String, dynamic>) {
          final total = responseData['total'] as int?;
          final hasNext = responseData['hasNext'] as bool?;
          final currentPage = responseData['page'] as int? ?? page;

          // If there are more pages, fetch them
          if (hasNext == true ||
              (total != null && (currentPage * limit) < total)) {
            // Fetch remaining pages
            int nextPage = currentPage + 1;
            while (true) {
              try {
                final nextResponse = await _dio.get('/users', queryParameters: {
                  'type': 'SR',
                  'page': nextPage,
                  'limit': limit,
                });

                if (nextResponse.statusCode == 200) {
                  final nextResponseData = nextResponse.data;
                  List<dynamic> nextData;

                  if (nextResponseData is List) {
                    nextData = nextResponseData;
                  } else if (nextResponseData is Map<String, dynamic>) {
                    if (nextResponseData.containsKey('data') &&
                        nextResponseData['data'] is List) {
                      nextData = nextResponseData['data'] as List<dynamic>;
                    } else if (nextResponseData.containsKey('users') &&
                        nextResponseData['users'] is List) {
                      nextData = nextResponseData['users'] as List<dynamic>;
                    } else {
                      break;
                    }
                  } else {
                    break;
                  }

                  if (nextData.isEmpty) break;

                  for (var item in nextData) {
                    try {
                      final user = ShowroomUser.fromJson(item);
                      if (user.type == 'SR') {
                        users.add(user);
                      }
                    } catch (_) {}
                  }

                  final nextHasNext = nextResponseData is Map<String, dynamic>
                      ? (nextResponseData['hasNext'] as bool?)
                      : false;
                  final nextTotal = nextResponseData is Map<String, dynamic>
                      ? (nextResponseData['total'] as int?)
                      : null;
                  final nextPageNum = nextResponseData is Map<String, dynamic>
                      ? (nextResponseData['page'] as int? ?? nextPage)
                      : nextPage;

                  if (nextHasNext != true &&
                      (nextTotal == null ||
                          (nextPageNum * limit) >= nextTotal)) {
                    break;
                  }

                  nextPage++;
                } else {
                  break;
                }
              } catch (_) {
                // If we have some users already, return them instead of failing completely
                if (users.isNotEmpty) {
                  break;
                }
                // If no users yet, let the error propagate
                rethrow;
              }
            }
          }
        }

        return users;
      } else {
        throw Exception(
            "Failed to load showroom users - Status: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException) {
        // Handle network connection errors first
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception(
              "Connection timeout. Please check your internet connection and try again.");
        }

        if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception(
              "Request timeout. The server is taking too long to respond. Please try again.");
        }

        if (e.type == DioExceptionType.connectionError) {
          throw Exception(
              "No internet connection. Please check your network settings and try again.");
        }

        if (e.type == DioExceptionType.sendTimeout) {
          throw Exception(
              "Request timeout. Please check your internet connection and try again.");
        }

        // Handle 401 Unauthorized - throw error so UI can show login prompt
        if (e.response?.statusCode == 401) {
          throw Exception("Please login to view showroom users.");
        }

        // Handle other HTTP errors
        if (e.response != null && e.response!.statusCode != null) {
          final statusCode = e.response!.statusCode!;
          if (statusCode == 403) {
            throw Exception(
                "You don't have permission to view showroom users.");
          } else if (statusCode == 404) {
            // 404 means no showroom users found - return empty list
            return [];
          } else if (statusCode == 400) {
            throw Exception(
                "Invalid request. Please try again or contact support if the problem persists.");
          } else if (statusCode >= 500) {
            throw Exception(
                "Server error. Our servers are experiencing issues. Please try again in a few moments.");
          } else {
            throw Exception(
                "Unable to load showroom users. Please try again later.");
          }
        }

        // Handle cases where response is null but there's an error
        throw Exception(
            "Unable to connect to the server. Please check your internet connection and try again.");
      }

      // If it's already an Exception with a message, rethrow it
      if (e is Exception) {
        rethrow;
      }

      // Generic error message for unknown errors
      throw Exception("An unexpected error occurred. Please try again later.");
    }
  }

  Future<List<AddModel>> fetchShowroomUserAds({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/ads/user/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> rawData = responseData['data'] ?? responseData;

        final ads = rawData.map((json) => AddModel.fromJson(json)).toList();
        return ads;
      } else {
        throw Exception(
            "Failed to load showroom user ads - Status: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException) {}
      throw Exception("Error fetching showroom user ads: $e");
    }
  }

  /// Fetches public showroom users (SR type) without authentication
  Future<List<ShowroomUser>> fetchPublicShowroomUsers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get('/users/public', queryParameters: {
        'type': 'SR',
        'page': page,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> data;

        // Handle different response structures
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Check if data is wrapped in a 'data' field
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            data = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('users') &&
              responseData['users'] is List) {
            data = responseData['users'] as List<dynamic>;
          } else {
            throw Exception(
                "Unexpected response structure: expected List or Map with 'data'/'users' field");
          }
        } else {
          throw Exception(
              "Unexpected response type: ${responseData.runtimeType}");
        }

        final List<ShowroomUser> users = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final user = ShowroomUser.fromJson(data[i]);
            // Filter to only include SR type users
            if (user.type == 'SR') {
              users.add(user);
            } else {}
          } catch (_) {}
        }

        // Check if there are more pages to fetch (for public endpoint)
        if (responseData is Map<String, dynamic>) {
          final total = responseData['total'] as int?;
          final hasNext = responseData['hasNext'] as bool?;
          final currentPage = responseData['page'] as int? ?? page;

          // If there are more pages, fetch them
          if (hasNext == true ||
              (total != null && (currentPage * limit) < total)) {
            int nextPage = currentPage + 1;
            while (true) {
              try {
                final nextResponse =
                    await _dio.get('/users/public', queryParameters: {
                  'type': 'SR',
                  'page': nextPage,
                  'limit': limit,
                });

                if (nextResponse.statusCode == 200) {
                  final nextResponseData = nextResponse.data;
                  List<dynamic> nextData;

                  if (nextResponseData is List) {
                    nextData = nextResponseData;
                  } else if (nextResponseData is Map<String, dynamic>) {
                    if (nextResponseData.containsKey('data') &&
                        nextResponseData['data'] is List) {
                      nextData = nextResponseData['data'] as List<dynamic>;
                    } else if (nextResponseData.containsKey('users') &&
                        nextResponseData['users'] is List) {
                      nextData = nextResponseData['users'] as List<dynamic>;
                    } else {
                      break;
                    }
                  } else {
                    break;
                  }

                  if (nextData.isEmpty) break;

                  for (var item in nextData) {
                    try {
                      final user = ShowroomUser.fromJson(item);
                      if (user.type == 'SR') {
                        users.add(user);
                      }
                    } catch (_) {}
                  }

                  final nextHasNext = nextResponseData is Map<String, dynamic>
                      ? (nextResponseData['hasNext'] as bool?)
                      : false;
                  final nextTotal = nextResponseData is Map<String, dynamic>
                      ? (nextResponseData['total'] as int?)
                      : null;
                  final nextPageNum = nextResponseData is Map<String, dynamic>
                      ? (nextResponseData['page'] as int? ?? nextPage)
                      : nextPage;

                  if (nextHasNext != true &&
                      (nextTotal == null ||
                          (nextPageNum * limit) >= nextTotal)) {
                    break;
                  }

                  nextPage++;
                } else {
                  break;
                }
              } catch (_) {
                // If we have some users already, return them instead of failing completely
                if (users.isNotEmpty) {
                  break;
                }
                // If no users yet, let the error propagate
                rethrow;
              }
            }
          }
        }

        return users;
      } else {
        throw Exception(
            "Failed to load public showroom users - Status: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException) {
        // Handle network connection errors first
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception(
              "Connection timeout. Please check your internet connection and try again.");
        }

        if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception(
              "Request timeout. The server is taking too long to respond. Please try again.");
        }

        if (e.type == DioExceptionType.connectionError) {
          throw Exception(
              "No internet connection. Please check your network settings and try again.");
        }

        if (e.type == DioExceptionType.sendTimeout) {
          throw Exception(
              "Request timeout. Please check your internet connection and try again.");
        }

        // Handle other HTTP errors
        if (e.response != null && e.response!.statusCode != null) {
          final statusCode = e.response!.statusCode!;
          if (statusCode == 403) {
            throw Exception(
                "You don't have permission to view showroom users.");
          } else if (statusCode == 404) {
            // 404 means no showroom users found - return empty list
            return [];
          } else if (statusCode == 400) {
            throw Exception(
                "Invalid request. Please try again or contact support if the problem persists.");
          } else if (statusCode >= 500) {
            throw Exception(
                "Server error. Our servers are experiencing issues. Please try again in a few moments.");
          } else {
            throw Exception(
                "Unable to load showroom users. Please try again later.");
          }
        }

        // Handle cases where response is null but there's an error
        throw Exception(
            "Unable to connect to the server. Please check your internet connection and try again.");
      }

      // If it's already an Exception with a message, rethrow it
      if (e is Exception) {
        rethrow;
      }

      // Generic error message for unknown errors
      throw Exception("An unexpected error occurred. Please try again later.");
    }
  }
}
