import 'package:ado_dad_user/common/api_service.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:dio/dio.dart';

/// Service for making HTTP API calls related to chat functionality
class ChatApiService {
  final Dio _dio = ApiService().dio;

  /// Fetch messages for a specific chat room
  /// GET /chats/rooms/{roomId}/messages
  Future<ChatMessagesResponse> getChatRoomMessages(String roomId) async {
    try {
      final response = await _dio.get('/chats/rooms/$roomId/messages');

      if (response.statusCode == 200) {
        return ChatMessagesResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch messages: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Error in getChatRoomMessages: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is TypeError) {
        print('❌ TypeError details: ${e.toString()}');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch messages for a specific chat room with pagination
  /// GET /chats/rooms/{roomId}/messages?cursor={cursor}&limit={limit}
  Future<ChatMessagesResponse> getChatRoomMessagesWithPagination(
    String roomId, {
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      final response = await _dio.get(
        '/chats/rooms/$roomId/messages',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ChatMessagesResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch messages: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
