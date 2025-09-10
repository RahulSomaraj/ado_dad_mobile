import 'package:ado_dad_user/features/chat/auth/auth_provider.dart';
import 'package:ado_dad_user/features/chat/data/chat_socket_service.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';

/// Repository for chat operations that wraps the ChatSocketService
class ChatRepository {
  final ChatSocketService _socketService;
  final ChatAuthProvider _authProvider;

  ChatRepository({
    required ChatSocketService socketService,
    required ChatAuthProvider authProvider,
  })  : _socketService = socketService,
        _authProvider = authProvider;

  /// Get the underlying socket service
  ChatSocketService get socketService => _socketService;

  /// Stream of incoming chat messages
  Stream<ChatMessage> get messages => _socketService.messages;

  /// Stream of new chat notifications
  Stream<Map<String, dynamic>> get newChats => _socketService.newChats;

  /// Create a new chat for an advertisement
  Future<Chat> createAdChat(String adId) async {
    try {
      final response = await _socketService.createAdChat(adId);

      if (response['success'] == true && response['chat'] != null) {
        return Chat.fromJson(Map<String, dynamic>.from(response['chat']));
      } else {
        final errorMessage =
            response['error'] ?? response['message'] ?? 'Failed to create chat';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error creating ad chat: $e');
    }
  }

  /// Join an existing chat
  Future<void> joinChat(String chatId) async {
    try {
      final response = await _socketService.joinChat(chatId);

      if (response['success'] != true) {
        final errorMessage =
            response['error'] ?? response['message'] ?? 'Failed to join chat';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error joining chat: $e');
    }
  }

  /// Send a message to a chat
  Future<void> sendMessage(String chatId, String content) async {
    try {
      final response = await _socketService.sendMessage(chatId, content);

      if (response['success'] != true) {
        final errorMessage = response['error'] ??
            response['message'] ??
            'Failed to send message';

        // Handle unauthorized error - try to rejoin chat and retry
        if (response['error'] == 'Unauthorized' ||
            response['message']?.toString().contains('Unauthorized') == true) {
          try {
            await joinChat(chatId);
            // Retry sending the message
            final retryResponse =
                await _socketService.sendMessage(chatId, content);
            if (retryResponse['success'] != true) {
              throw Exception(retryResponse['error'] ??
                  retryResponse['message'] ??
                  'Failed to send message after retry');
            }
          } catch (retryError) {
            throw Exception(
                'Failed to rejoin chat and send message: $retryError');
          }
        } else {
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Get all chats for the current user
  Future<List<ChatSummary>> getUserChats() async {
    try {
      final response = await _socketService.getUserChats();

      if (response['success'] == true && response['chats'] != null) {
        final List<dynamic> chatsData = response['chats'];
        return chatsData
            .map((chatData) =>
                ChatSummary.fromJson(Map<String, dynamic>.from(chatData)))
            .toList();
      } else {
        final errorMessage = response['error'] ??
            response['message'] ??
            'Failed to get user chats';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error getting user chats: $e');
    }
  }

  /// Get messages for a specific chat
  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    try {
      final response = await _socketService.getChatMessages(chatId);

      if (response['success'] == true && response['messages'] != null) {
        final List<dynamic> messagesData = response['messages'];
        return messagesData
            .map((messageData) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(messageData)))
            .toList();
      } else {
        final errorMessage = response['error'] ??
            response['message'] ??
            'Failed to get chat messages';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error getting chat messages: $e');
    }
  }

  /// Mark messages in a chat as read
  Future<void> markAsRead(String chatId) async {
    try {
      final response = await _socketService.markAsRead(chatId);

      if (response['success'] != true) {
        final errorMessage = response['error'] ??
            response['message'] ??
            'Failed to mark messages as read';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }

  /// Connect to the chat socket
  Future<void> connect() async {
    await _socketService.connect();
  }

  /// Disconnect from the chat socket
  void disconnect() {
    _socketService.disconnect();
  }

  /// Check if socket is connected
  bool get isConnected => _socketService.isConnected;

  /// Check if socket is connecting
  bool get isConnecting => _socketService.isConnecting;

  /// Refresh authentication
  Future<void> refreshAuth() async {
    await _socketService.refreshAuth();
  }

  /// Dispose resources
  void dispose() {
    _socketService.dispose();
  }
}
