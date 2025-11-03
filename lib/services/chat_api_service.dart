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

  /// Helper method to execute HTTP request with automatic token refresh on 401
  Future<http.Response> _executeRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    var token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login first.');
    }

    var response = await request(token);

    // Handle 401 Unauthorized - try to refresh token using centralized AuthService
    if (response.statusCode == 401) {
      print('🔄 Received 401, attempting token refresh...');
      final authService = AuthService();
      final newToken = await authService.refreshAccessToken();
      if (newToken != null) {
        print('🔄 Retrying request with refreshed token...');
        response = await request(newToken);
        print('📡 Retry response status: ${response.statusCode}');
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

      print('🌐 Fetching chat rooms from: $url');
      final token = await getToken();
      print(
          '🔑 Using token: ${token != null && token.length > 20 ? token.substring(0, 20) + "..." : (token ?? "null")}');

      final response = await _executeRequest((token) async {
        return await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,
          },
        ).timeout(const Duration(seconds: 10));
      });

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Chat rooms fetched successfully');
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData is Map<String, dynamic>
            ? (errorData['message'] ?? 'Unknown error')
            : 'Unknown error';
        throw Exception('Failed to fetch chat rooms: $errorMessage');
      }
    } catch (e) {
      print('❌ Error fetching chat rooms: $e');
      rethrow;
    }
  }

  /// Get room messages from API
  Future<Map<String, dynamic>> getRoomMessages(String roomId) async {
    try {
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/chats/rooms/$roomId/messages';

      print('🌐 Fetching messages for room: $roomId');
      print('🔗 URL: $url');

      final response = await _executeRequest((token) async {
        return await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,
          },
        ).timeout(const Duration(seconds: 10));
      });

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Messages fetched successfully');
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData is Map<String, dynamic>
            ? (errorData['message'] ?? 'Unknown error')
            : 'Unknown error';
        throw Exception('Failed to fetch messages: $errorMessage');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      rethrow;
    }
  }

  /// Check if a chat room exists for an ad and other user
  Future<Map<String, dynamic>> checkRoomExists(
      String adId, String otherUserId) async {
    try {
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/chats/rooms/check/$adId/$otherUserId';

      print(
          '🌐 Checking if room exists for ad: $adId and other user: $otherUserId');
      print('🔗 URL: $url');

      final response = await _executeRequest((token) async {
        return await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,
          },
        ).timeout(const Duration(seconds: 10));
      });

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Room check completed successfully');
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
    } catch (e) {
      print('❌ Error checking room: $e');
      rethrow;
    }
  }

  /// Send message via HTTP API to store in database
  Future<Map<String, dynamic>> sendMessage(String roomId, String content,
      {String type = 'text'}) async {
    try {
      final baseUrl = AppConfig.baseUrl;
      final url = '$baseUrl/chats/rooms/$roomId/messages';

      print('🌐 Sending message to room: $roomId');
      print('🔗 URL: $url');
      print('📝 Content: $content');
      print('📝 Type: $type');

      // Prepare request body
      final requestBody = {
        'content': content,
        'type': type,
      };

      final response = await _executeRequest((token) async {
        return await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': token,
              },
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 10));
      });

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Message sent successfully via API');
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData is Map<String, dynamic>
            ? (errorData['message'] ?? 'Unknown error')
            : 'Unknown error';
        throw Exception('Failed to send message: $errorMessage');
      }
    } catch (e) {
      print('❌ Error sending message via API: $e');
      rethrow;
    }
  }
}
