import 'dart:async';
import 'package:ado_dad_user/env/env.dart';
import 'package:ado_dad_user/features/chat/auth/auth_provider.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Configuration for chat socket connection
class ChatConfig {
  final String baseUrl;
  final int reconnectionAttempts;
  final int timeout;
  final bool reconnection;

  const ChatConfig({
    this.baseUrl = Env.baseUrl,
    this.reconnectionAttempts = 10,
    this.timeout = 10000,
    this.reconnection = true,
  });
}

/// Service for handling real-time chat functionality via Socket.IO
class ChatSocketService {
  final ChatConfig _config;
  final ChatAuthProvider _authProvider;

  IO.Socket? _socket;
  final StreamController<ChatMessage> _messageCtrl =
      StreamController<ChatMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _newChatCtrl =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnecting = false;
  bool _isConnected = false;

  ChatSocketService({
    required ChatConfig config,
    required ChatAuthProvider authProvider,
  })  : _config = config,
        _authProvider = authProvider;

  /// Get the current socket instance
  IO.Socket? get socket => _socket;

  /// Check if socket is connected
  bool get isConnected => _isConnected;

  /// Check if socket is currently connecting
  bool get isConnecting => _isConnecting;

  /// Stream of incoming chat messages
  Stream<ChatMessage> get messages => _messageCtrl.stream;

  /// Stream of new chat notifications
  Stream<Map<String, dynamic>> get newChats => _newChatCtrl.stream;

  /// Connect to the chat socket server
  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      print('🔄 Chat socket: Already connecting or connected');
      return;
    }

    _isConnecting = true;

    try {
      final token = _authProvider.token;
      final userId = _authProvider.userId;

      if (token == null || userId == null) {
        throw Exception('Authentication required: token or userId is null');
      }

      print('🔌 Chat socket: Connecting to ${_config.baseUrl}/chat');

      _socket = IO.io(
        '${_config.baseUrl}/chat',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableReconnection()
            .setReconnectionAttempts(_config.reconnectionAttempts)
            .setTimeout(_config.timeout)
            .setAuth({
              'token': 'Bearer $token',
              'userId': userId,
            })
            .build(),
      );

      _setupSocketListeners();

      print('✅ Chat socket: Connection initiated');
    } catch (e) {
      _isConnecting = false;
      print('❌ Chat socket: Connection failed - $e');
      rethrow;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnecting = false;
      _isConnected = true;
      print('✅ Chat socket: Connected successfully');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      print('🔌 Chat socket: Disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnecting = false;
      _isConnected = false;
      print('❌ Chat socket: Connection error - $error');
    });

    _socket!.on('newMessage', (data) {
      try {
        print('📨 Chat socket: Received new message - $data');
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        _messageCtrl.add(message);
      } catch (e) {
        print('❌ Chat socket: Error parsing new message - $e');
      }
    });

    _socket!.on('newChatCreated', (data) {
      try {
        print('💬 Chat socket: New chat created - $data');
        final chatData = Map<String, dynamic>.from(data);
        _newChatCtrl.add(chatData);
      } catch (e) {
        print('❌ Chat socket: Error handling new chat - $e');
      }
    });

    _socket!.onError((error) {
      print('❌ Chat socket: Socket error - $error');
    });
  }

  /// Disconnect from the chat socket server
  void disconnect() {
    if (_socket != null) {
      print('🔌 Chat socket: Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _isConnecting = false;
  }

  /// Refresh authentication and reconnect with new credentials
  Future<void> refreshAuth() async {
    print('🔄 Chat socket: Refreshing authentication...');

    if (_socket != null) {
      final token = _authProvider.token;
      final userId = _authProvider.userId;

      if (token != null && userId != null) {
        _socket!.auth = {
          'token': 'Bearer $token',
          'userId': userId,
        };
        print('✅ Chat socket: Authentication refreshed');
      }
    }
  }

  /// Emit event with acknowledgment
  Future<Map<String, dynamic>> _emitWithAck(String event, dynamic data) async {
    if (_socket == null || !_isConnected) {
      throw Exception('Socket not connected');
    }

    return await Future.value(
        _socket!.emitWithAck(event, data) as Map<String, dynamic>);
  }

  /// Create a new chat for an advertisement
  Future<Map<String, dynamic>> createAdChat(String adId) async {
    print('💬 Chat socket: Creating ad chat for $adId');
    return await _emitWithAck('createAdChat', {'adId': adId});
  }

  /// Join an existing chat
  Future<Map<String, dynamic>> joinChat(String chatId) async {
    print('👥 Chat socket: Joining chat $chatId');
    return await _emitWithAck('joinChat', {'chatId': chatId});
  }

  /// Send a message to a chat
  Future<Map<String, dynamic>> sendMessage(
      String chatId, String content) async {
    print('📤 Chat socket: Sending message to chat $chatId');
    return await _emitWithAck('sendMessage', {
      'chatId': chatId,
      'content': content,
    });
  }

  /// Get all chats for the current user
  Future<Map<String, dynamic>> getUserChats() async {
    print('📋 Chat socket: Getting user chats');
    return await _emitWithAck('getUserChats', null);
  }

  /// Get messages for a specific chat
  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    print('📨 Chat socket: Getting messages for chat $chatId');
    return await _emitWithAck('getChatMessages', {'chatId': chatId});
  }

  /// Mark messages in a chat as read
  Future<Map<String, dynamic>> markAsRead(String chatId) async {
    print('👁️ Chat socket: Marking chat $chatId as read');
    return await _emitWithAck('markAsRead', {'chatId': chatId});
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageCtrl.close();
    _newChatCtrl.close();
  }
}
