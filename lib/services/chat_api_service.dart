import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/services/auth_service.dart';

/// HTTP API service for chat functionality
class ChatApiService {
  static final ChatApiService _instance = ChatApiService._internal();
  factory ChatApiService() => _instance;
  ChatApiService._internal();

  /// Prepares the Authorization header with the token
  /// Uses the same format as ApiService (with or without "Bearer " prefix)
  static const bool _useBearerPrefix =
      true; // Must match ApiService._useBearerPrefix

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

  /// Helper method to execute HTTP request with automatic token refresh on 401
  Future<http.Response> _executeRequest(
    Future<http.Response> Function(String authHeader) request,
  ) async {
    var token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login first.');
    }

    // Prepare Authorization header with correct format (matching ApiService)
    final authHeader = _prepareAuthHeader(token);

    var response = await request(authHeader);

    // Handle 401 Unauthorized - try to refresh token using centralized AuthService
    if (response.statusCode == 401) {
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();
      if (newToken != null && newToken.isNotEmpty) {
        // Prepare new Authorization header with refreshed token
        final newAuthHeader = _prepareAuthHeader(newToken);
        response = await request(newAuthHeader);
      } else {
        // Refresh token expired, AuthService will handle automatic logout
        throw Exception('Session expired. Please login again.');
      }
    }

    return response;
  }

  /// Get user's chat rooms from API with automatic token refresh on 401
  Future<Map<String, dynamic>> getUserChatRooms() async {
    try {
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/chats/rooms';

      final response = await _executeRequest((authHeader) async {
        return await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
        ).timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData is Map<String, dynamic>
            ? (errorData['message'] ?? 'Unknown error')
            : 'Unknown error';
        throw Exception('Failed to fetch chat rooms: $errorMessage');
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Get room messages from API
  Future<Map<String, dynamic>> getRoomMessages(String roomId) async {
    try {
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/chats/rooms/$roomId/messages';

      final response = await _executeRequest((authHeader) async {
        return await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
        ).timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData is Map<String, dynamic>
            ? (errorData['message'] ?? 'Unknown error')
            : 'Unknown error';
        throw Exception('Failed to fetch messages: $errorMessage');
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Check if a chat room exists for an ad and other user
  Future<Map<String, dynamic>> checkRoomExists(
      String adId, String otherUserId) async {
    try {
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/chats/rooms/check/$adId/$otherUserId';

      final response = await _executeRequest((authHeader) async {
        return await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader,
          },
        ).timeout(const Duration(seconds: 10));
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        // Room doesn't exist - this is a valid response
        return {
          'success': false,
          'exists': false,
          'message': 'Room does not exist for this ad and user combination'
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData is Map<String, dynamic>
            ? (errorData['message'] ?? 'Unknown error')
            : 'Unknown error';
        throw Exception('Failed to check room: $errorMessage');
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Send message via HTTP API to store in database.
  /// For image/audio, pass type and attachments (content can be empty).
  Future<Map<String, dynamic>> sendMessage(String roomId, String content,
      {String type = 'text',
      List<Map<String, dynamic>>? attachments}) async {
    try {
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/chats/rooms/$roomId/messages';

      // Prepare request body
      final requestBody = <String, dynamic>{
        'content': content,
        'type': type,
      };
      if (attachments != null && attachments.isNotEmpty) {
        requestBody['attachments'] = attachments;
      }

      final response = await _executeRequest((authHeader) async {
        return await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': authHeader,
              },
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 15));
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        // 404 often returns plain text (e.g. "Cannot POST /path") from Express
        if (response.statusCode == 404) {
          throw Exception(
              'Cannot POST ${response.body.isNotEmpty ? response.body : url}');
        }
        String errorMessage = 'Unknown error';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData is Map<String, dynamic>
              ? (errorData['message'] ?? errorData['error'] ?? errorMessage)
              : errorMessage;
        } catch (_) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        }
        throw Exception('Failed to send message: $errorMessage');
      }
    } catch (_) {
      rethrow;
    }
  }
}
