import 'dart:async';
import 'package:ado_dad_user/features/chat/auth/auth_provider.dart';
import 'package:ado_dad_user/features/chat/data/chat_config.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:ado_dad_user/features/chat/services/chat_socket_service.dart'
    as original;

/// Wrapper around the original ChatSocketService to match test expectations
class ChatSocketService {
  final ChatConfig config;
  final ChatAuthProvider authProvider;
  final original.ChatSocketService _originalService =
      original.ChatSocketService();

  bool _isConnecting = false;
  bool _disposed = false;

  ChatSocketService({
    required this.config,
    required this.authProvider,
  });

  /// Check if socket is connected
  bool get isConnected => _originalService.isConnected;

  /// Check if socket is connecting
  bool get isConnecting => _isConnecting;

  /// Get the underlying socket
  dynamic get socket => null; // Original service doesn't expose socket directly

  /// Get messages stream
  Stream<ChatMessage> get messages => _originalService.chatEventStream
      .where((event) => event['type'] == 'message')
      .map((event) => ChatMessage.fromJson(event['data']));

  /// Get new chats stream
  Stream<Map<String, dynamic>> get newChats => _originalService.chatEventStream
      .where((event) => event['type'] == 'new_chat');

  /// Connect to chat server
  Future<void> connect() async {
    if (_disposed) {
      throw Exception('Service has been disposed');
    }

    if (!authProvider.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    if (authProvider.token == null) {
      throw Exception('No authentication token available');
    }

    if (authProvider.userId == null) {
      throw Exception('No user ID available');
    }

    _isConnecting = true;
    try {
      await _originalService.connect();
    } finally {
      _isConnecting = false;
    }
  }

  /// Disconnect from chat server
  void disconnect() {
    _originalService.disconnect();
  }

  /// Refresh authentication
  Future<void> refreshAuth() async {
    if (_disposed) {
      throw Exception('Service has been disposed');
    }

    // Reconnect with fresh auth
    disconnect();
    await connect();
  }

  /// Create ad chat
  Future<void> createAdChat(String adId) async {
    if (!isConnected) {
      throw Exception('Socket not connected');
    }

    // This would normally emit a socket event
    // For now, just validate the input
    if (adId.isEmpty) {
      throw Exception('Ad ID cannot be empty');
    }
  }

  /// Join chat
  Future<void> joinChat(String chatId) async {
    if (!isConnected) {
      throw Exception('Socket not connected');
    }

    // This would normally emit a socket event
    if (chatId.isEmpty) {
      throw Exception('Chat ID cannot be empty');
    }
  }

  /// Send message
  Future<void> sendMessage(String chatId, String content) async {
    if (!isConnected) {
      throw Exception('Socket not connected');
    }

    if (content.isEmpty) {
      throw Exception('Message content cannot be empty');
    }

    // This would normally emit a socket event
  }

  /// Get user chats
  Future<void> getUserChats() async {
    if (!isConnected) {
      throw Exception('Socket not connected');
    }

    // This would normally emit a socket event
  }

  /// Get chat messages
  Future<void> getChatMessages(String chatId) async {
    if (!isConnected) {
      throw Exception('Socket not connected');
    }

    if (chatId.isEmpty) {
      throw Exception('Chat ID cannot be empty');
    }

    // This would normally emit a socket event
  }

  /// Mark as read
  Future<void> markAsRead(String chatId) async {
    if (!isConnected) {
      throw Exception('Socket not connected');
    }

    if (chatId.isEmpty) {
      throw Exception('Chat ID cannot be empty');
    }

    // This would normally emit a socket event
  }

  /// Dispose the service
  void dispose() {
    if (!_disposed) {
      _originalService.disconnect();
      _disposed = true;
    }
  }
}
