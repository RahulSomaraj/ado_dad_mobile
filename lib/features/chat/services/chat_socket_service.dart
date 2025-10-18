import 'dart:async';
import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/features/chat/utils/token_validator.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal() {
    // Log environment configuration on initialization
    log('🚀 ChatSocketService initialized');
    // log('🌐 Environment Base URL: ${AppConfig.baseUrl}');
    // log('🔗 Chat Socket Endpoint: ${AppConfig.baseUrl}/chat');
  }

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentSocketId;

  // Stream controllers for different events
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _chatEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get chatEventStream =>
      _chatEventController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters for current state
  bool get isConnected => _isConnected;
  String? get socketId => _currentSocketId;

  /// Initialize and connect to the chat socket
  Future<void> connect() async {
    try {
      // Get JWT token from shared preferences
      final token = await getToken();
      if (token == null) {
        log('❌ No JWT token found. Cannot connect to chat socket.');
        _errorController.add('No authentication token found');
        return;
      }

      // Disconnect existing connection if any
      if (_socket != null) {
        await disconnect();
      }

      // Print base URL for confirmation
      final socketUrl = '${AppConfig.baseUrl}/chat';
      // log('🌐 Base URL: ${AppConfig.baseUrl}');
      // log('🔗 Socket URL: $socketUrl');

      // Clean token - remove "Bearer " prefix if it exists
      String cleanToken = token;
      if (token.startsWith('Bearer ')) {
        cleanToken = token.substring(7); // Remove "Bearer " prefix
        // log('🔧 Cleaned token (removed Bearer prefix)');
      }

      // log('🔑 JWT Token: ${cleanToken.substring(0, 20)}...'); // Show first 20 chars for security
      // log('🔍 Token Analysis:');
      // log('   - Token length: ${cleanToken.length} characters');
      // log('   - Token starts with: ${cleanToken.substring(0, 10)}...');
      // log('   - Token ends with: ...${cleanToken.substring(cleanToken.length - 10)}');
      // log('   - Full auth header: Bearer $cleanToken');

      // Validate JWT token
      TokenValidator.validateToken(cleanToken);

      log('🔄 Connecting to chat socket...');

      // Create socket connection to chat namespace
      _socket = IO.io(
          socketUrl,
          IO.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .setAuth({'token': cleanToken})
              .enableAutoConnect()
              .setTimeout(10000) // 10 second timeout
              .setReconnectionAttempts(3) // Try 3 times
              .setReconnectionDelay(2000) // Wait 2 seconds between attempts
              .build());

      _setupEventListeners();

      // Connect the socket
      log('🔌 Attempting to connect socket...');
      _socket!.connect();

      // Add a small delay to check connection status
      await Future.delayed(const Duration(milliseconds: 1000));
      // log('🔍 Socket connection status after 1s: ${_socket!.connected}');
      // log('🔍 Socket ID after 1s: ${_socket!.id}');
    } catch (e) {
      log('❌ Error connecting to chat socket: $e');
      _errorController.add('Failed to connect: $e');
    }
  }

  /// Setup all socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      _currentSocketId = _socket!.id;
      log('✅ Connected to chat server successfully!');
      log('📡 Socket ID: ${_socket!.id}');
      // log('🌐 Connected to: ${AppConfig.baseUrl}/chat');
      // log('🔍 Socket transport: ${_socket!.io.engine?.transport?.name}');
      log('🔍 Socket connected status: ${_socket!.connected}');
      _connectionController.add(true);

      // Test if server responds to a simple ping
      _socket!.emitWithAck('ping', {}, ack: (response) {
        log('🏓 Server responded to ping: $response');
      });
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      _currentSocketId = null;
      log('❌ Disconnected from chat server: $reason');
      log('🔍 Disconnect reason analysis:');
      if (reason == 'io server disconnect') {
        log('⚠️ Server actively disconnected the client');
        log('💡 This usually indicates:');
        log('   - Authentication failed (invalid JWT token)');
        log('   - Server rejected the connection');
        log('   - User not authorized for chat namespace');
        log('   - Token expired or malformed');
      } else if (reason == 'io client disconnect') {
        log('ℹ️ Client initiated disconnect');
      } else if (reason == 'ping timeout') {
        log('⏰ Connection timeout');
      } else {
        log('❓ Unknown disconnect reason: $reason');
      }
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      log('🚫 Connection failed: ${error.message}');
      log('🔍 Connection error details:');
      log('   - Error type: ${error.runtimeType}');
      log('   - Error message: ${error.message}');
      log('   - Error description: ${error.description}');
      log('   - Error context: ${error.context}');
      log('   - Socket connected: ${_socket?.connected}');
      log('   - Socket ID: ${_socket?.id}');
      _errorController.add('Connection failed: ${error.message}');
    });

    // Reconnection events
    _socket!.onReconnect((attempt) {
      log('🔄 Reconnected after $attempt attempts');
    });

    _socket!.onReconnectAttempt((attempt) {
      log('🔄 Reconnection attempt #$attempt');
    });

    _socket!.onReconnectError((error) {
      log('❌ Reconnection failed: $error');
    });

    _socket!.onReconnectFailed((_) {
      log('❌ All reconnection attempts failed');
    });

    // Chat specific events
    _socket!.on('message', (data) {
      log('📨 Received message: $data');
      _messageController.add(data.toString());
    });

    _socket!.on('new_message', (data) {
      log('📨 New message received: $data');
      _chatEventController.add({
        'type': 'new_message',
        'data': data,
      });
    });

    _socket!.on('message_sent', (data) {
      log('✅ Message sent confirmation: $data');
      _chatEventController.add({
        'type': 'message_sent',
        'data': data,
      });
    });

    _socket!.on('getUserChatRoomsResponse', (response) {
      log('📋 Received getUserChatRoomsResponse: $response');
      _chatEventController.add({
        'type': 'getUserChatRoomsResponse',
        'data': response,
      });
    });

    _socket!.on('loadRoomMessagesResponse', (response) {
      log('📨 Received loadRoomMessagesResponse: $response');
      _chatEventController.add({
        'type': 'loadRoomMessagesResponse',
        'data': response,
      });
    });

    _socket!.on('chatRoomCreated', (data) {
      log('🏗️ Chat room created: $data');
      _chatEventController.add({
        'type': 'chatRoomCreated',
        'data': data,
      });
    });

    _socket!.on('existingChatRoomResponse', (data) {
      log('🔍 Existing chat room response: $data');
      _chatEventController.add({
        'type': 'existingChatRoomResponse',
        'data': data,
      });
    });

    _socket!.on('chatRoomJoined', (data) {
      log('🚪 Chat room joined: $data');
      _chatEventController.add({
        'type': 'chatRoomJoined',
        'data': data,
      });
    });

    _socket!.on('typing', (data) {
      log('⌨️ Typing indicator: $data');
      _chatEventController.add({
        'type': 'typing',
        'data': data,
      });
    });

    _socket!.on('stop_typing', (data) {
      log('⏹️ Stop typing: $data');
      _chatEventController.add({
        'type': 'stop_typing',
        'data': data,
      });
    });

    _socket!.on('user_joined', (data) {
      log('👤 User joined: $data');
      _chatEventController.add({
        'type': 'user_joined',
        'data': data,
      });
    });

    _socket!.on('user_left', (data) {
      log('👋 User left: $data');
      _chatEventController.add({
        'type': 'user_left',
        'data': data,
      });
    });

    _socket!.on('error', (data) {
      log('❌ Socket error: $data');
      _errorController.add('Socket error: $data');
    });

    // Authentication specific events
    _socket!.on('auth_error', (data) {
      log('🔐 Authentication error: $data');
      _errorController.add('Authentication failed: $data');
    });

    _socket!.on('unauthorized', (data) {
      log('🚫 Unauthorized access: $data');
      _errorController.add('Unauthorized: $data');
    });

    _socket!.on('token_expired', (data) {
      log('⏰ Token expired: $data');
      _errorController.add('Token expired: $data');
    });

    // Generic event handler for any other events
    _socket!.onAny((event, data) {
      // log('🔔 Socket event [$event]: $data');
      _chatEventController.add({
        'type': event,
        'data': data,
      });
    });
  }

  /// Send a message to a specific thread/room
  Future<void> sendMessage({
    required String threadId,
    required String message,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot send message: Socket not connected');
      _errorController.add('Socket not connected');
      return;
    }

    try {
      final messageData = {
        'threadId': threadId,
        'message': message,
        'messageType': messageType ?? 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      };

      log('📤 Sending message: $messageData');
      _socket!.emit('send_message', messageData);
    } catch (e) {
      log('❌ Error sending message: $e');
      _errorController.add('Failed to send message: $e');
    }
  }

  /// Join a specific chat thread/room
  Future<void> joinThread(String threadId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot join thread: Socket not connected');
      _errorController.add('Socket not connected');
      return;
    }

    try {
      log('🚪 Joining thread: $threadId');
      _socket!.emit('join_thread', {'threadId': threadId});
    } catch (e) {
      log('❌ Error joining thread: $e');
      _errorController.add('Failed to join thread: $e');
    }
  }

  /// Leave a specific chat thread/room
  Future<void> leaveThread(String threadId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot leave thread: Socket not connected');
      return;
    }

    try {
      log('🚪 Leaving thread: $threadId');
      _socket!.emit('leave_thread', {'threadId': threadId});
    } catch (e) {
      log('❌ Error leaving thread: $e');
      _errorController.add('Failed to leave thread: $e');
    }
  }

  /// Send typing indicator
  Future<void> sendTyping(String threadId) async {
    if (!_isConnected || _socket == null) return;

    try {
      _socket!.emit('typing', {'threadId': threadId});
    } catch (e) {
      log('❌ Error sending typing indicator: $e');
    }
  }

  /// Stop typing indicator
  Future<void> stopTyping(String threadId) async {
    if (!_isConnected || _socket == null) return;

    try {
      _socket!.emit('stop_typing', {'threadId': threadId});
    } catch (e) {
      log('❌ Error stopping typing indicator: $e');
    }
  }

  /// Disconnect from the socket
  Future<void> disconnect() async {
    if (_socket != null) {
      log('🔌 Disconnecting from chat socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _currentSocketId = null;
    _connectionController.add(false);
  }

  /// Reconnect to the socket
  Future<void> reconnect() async {
    log('🔄 Reconnecting to chat socket...');
    await disconnect();
    await connect();
  }

  /// Check for existing chat room for a specific ad
  Future<Map<String, dynamic>?> checkExistingChatRoom(String adId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Step 1: Socket not connected');
      return null;
    }

    try {
      final completer = Completer<Map<String, dynamic>>();
      bool responseReceived = false;

      void handleExistingChatRoomResponse(data) {
        if (!responseReceived) {
          responseReceived = true;
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        }
      }

      _socket!.on('existingChatRoomResponse', handleExistingChatRoomResponse);
      _socket!.emit('checkExistingChatRoom', {'adId': adId});

      final response = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log('⚠️ Step 1: No existing room found (timeout)');
          return {'success': false, 'error': 'Request timeout'};
        },
      );

      _socket!.off('existingChatRoomResponse', handleExistingChatRoomResponse);

      if (response['success'] == true && response['exists'] == true) {
        log('✅ Step 1: Found existing room: ${response['room']['roomId']}');
      } else {
        log('📝 Step 1: No existing room found');
      }

      return response;
    } catch (e) {
      log('❌ Step 1: Error checking existing room: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a new chat room for a specific ad
  Future<Map<String, dynamic>?> createChatRoom(String adId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Step 2: Socket not connected');
      return null;
    }

    try {
      log('🏗️ Step 2: Creating new chat room');

      final completer = Completer<Map<String, dynamic>>();
      bool responseReceived = false;

      void handleChatRoomCreated(data) {
        if (!responseReceived) {
          responseReceived = true;
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        }
      }

      _socket!.on('chatRoomCreated', handleChatRoomCreated);
      _socket!.emit('createChatRoom', {'adId': adId});

      final response = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log('❌ Step 2: Failed to create room (timeout)');
          return {'success': false, 'error': 'Request timeout'};
        },
      );

      _socket!.off('chatRoomCreated', handleChatRoomCreated);

      // Debug: Log the actual response structure
      log('🔍 Step 2: Server response structure: $response');

      if (response['success'] == true) {
        // Check for roomId in different possible locations
        String? roomId;

        // Try the expected structure first
        if (response['chatRoom'] != null &&
            response['chatRoom']['roomId'] != null) {
          roomId = response['chatRoom']['roomId'];
          log('✅ Step 2: Created new room (chatRoom structure): $roomId');
        }
        // Try the actual server structure (data object)
        else if (response['data'] != null &&
            response['data']['roomId'] != null) {
          roomId = response['data']['roomId'];
          log('✅ Step 2: Created new room (data structure): $roomId');
        }
        // Try if roomId is directly in data
        else if (response['data'] != null && response['data'] is String) {
          roomId = response['data'];
          log('✅ Step 2: Created new room (data as string): $roomId');
        }
        // Try if roomId is directly in response
        else if (response['roomId'] != null) {
          roomId = response['roomId'];
          log('✅ Step 2: Created new room (direct roomId): $roomId');
        } else {
          log('❌ Step 2: Room created but missing roomId in response');
          log('🔍 Available keys in response: ${response.keys.toList()}');
          if (response['data'] != null) {
            log('🔍 data structure: ${response['data']}');
            if (response['data'] is Map) {
              log('🔍 data keys: ${response['data'].keys.toList()}');
            }
          }
          return {
            'success': false,
            'error': 'Invalid response structure: missing roomId'
          };
        }

        // Add the roomId to the response for consistency
        response['roomId'] = roomId;
      } else {
        log('❌ Step 2: Failed to create room');
        log('🔍 Error details: ${response['error'] ?? response['message'] ?? 'Unknown error'}');
      }

      return response;
    } catch (e) {
      log('❌ Step 2: Error creating room: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Join a chat room
  Future<Map<String, dynamic>?> joinChatRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Step 3: Socket not connected');
      return null;
    }

    try {
      log('🚪 Step 3: Joining chat room: $roomId');
      log('🔍 Socket connected status: ${_socket!.connected}');
      log('🔍 Socket ID: ${_socket!.id}');

      final completer = Completer<Map<String, dynamic>>();
      bool responseReceived = false;

      void handleChatRoomJoined(data) {
        log('🔍 Received chatRoomJoined event: $data');
        if (!responseReceived) {
          responseReceived = true;
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        }
      }

      // Listen for multiple possible events
      _socket!.on('chatRoomJoined', handleChatRoomJoined);
      _socket!.on('roomJoined', handleChatRoomJoined);
      _socket!.on('joinedRoom', handleChatRoomJoined);

      // Also listen for any response to debug
      _socket!.on('joinChatRoomResponse', (data) {
        log('🔍 Received joinChatRoomResponse: $data');
        if (!responseReceived) {
          responseReceived = true;
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        }
      });

      // Debug: Listen for any socket events during join process
      void debugEventHandler(String eventName) {
        _socket!.on(eventName, (data) {
          log('🔍 Debug - Received event "$eventName": $data');
        });
      }

      // Listen for common events that might indicate room join success
      debugEventHandler('room_joined');
      debugEventHandler('user_joined');
      debugEventHandler('join_success');
      debugEventHandler('room_ready');

      log('📤 Emitting joinChatRoom with roomId: $roomId');
      _socket!.emit('joinChatRoom', {'roomId': roomId});

      final response = await completer.future.timeout(
        const Duration(seconds: 15), // Increased timeout
        onTimeout: () {
          log('❌ Step 3: Failed to join room (timeout)');
          log('🔍 No response received from server for joinChatRoom');
          log('🔍 Socket still connected: ${_socket!.connected}');
          return {
            'success': false,
            'error': 'Request timeout - server did not respond'
          };
        },
      );

      // Clean up listeners
      _socket!.off('chatRoomJoined', handleChatRoomJoined);
      _socket!.off('roomJoined', handleChatRoomJoined);
      _socket!.off('joinedRoom', handleChatRoomJoined);
      _socket!.off('joinChatRoomResponse', handleChatRoomJoined);

      // Clean up debug listeners
      _socket!.off('room_joined');
      _socket!.off('user_joined');
      _socket!.off('join_success');
      _socket!.off('room_ready');

      log('🔍 Join room response: $response');

      if (response['success'] == true) {
        log('✅ Step 3: Joined room successfully');
      } else {
        log('❌ Step 3: Failed to join room');
        log('🔍 Error details: ${response['error'] ?? response['message'] ?? 'Unknown error'}');
      }

      return response;
    } catch (e) {
      log('❌ Step 3: Error joining room: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send a message to a chat room
  Future<Map<String, dynamic>?> sendMessageToRoom({
    required String roomId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isConnected || _socket == null) {
      log('❌ Step 4: Socket not connected');
      return null;
    }

    try {
      log('📤 Step 4: Sending offer message');
      log('🔍 Message data: roomId=$roomId, type=$messageType, content=$content');

      // Match HTML implementation - simpler message structure
      final Map<String, dynamic> messageData = {
        'roomId': roomId,
        'content': content,
        'messageType': messageType, // Note: HTML uses 'messageType', not 'type'
      };

      // Add metadata if provided (for offer messages)
      if (metadata != null && metadata.isNotEmpty) {
        messageData['metadata'] = metadata;
      }

      final completer = Completer<Map<String, dynamic>>();
      bool responseReceived = false;

      // Listen for sendMessageResponse event (matching HTML implementation)
      void handleSendMessageResponse(data) {
        log('🔍 Received sendMessageResponse event: $data');
        if (!responseReceived) {
          responseReceived = true;
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        }
      }

      // Listen for the response event (matching HTML)
      _socket!.on('sendMessageResponse', handleSendMessageResponse);

      log('📤 Emitting sendMessage (matching HTML approach)...');
      // Use emitWithAck to match HTML callback behavior
      _socket!.emitWithAck('sendMessage', messageData, ack: (response) {
        log('🔍 Received sendMessage ack: $response');
        if (!responseReceived) {
          responseReceived = true;
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        }
      });

      final response = await completer.future.timeout(
        const Duration(seconds: 15), // Increased timeout
        onTimeout: () {
          log('❌ Step 4: Message send timeout');
          log('🔍 No response received from server for sendMessage');
          log('🔍 Socket still connected: ${_socket!.connected}');

          // Clean up listeners
          _socket!.off('sendMessageResponse', handleSendMessageResponse);

          // Return a warning instead of error - message might still be sent
          return {
            'success': true,
            'warning':
                'Message send confirmation timeout - message may have been sent',
            'message': 'Message sent (confirmation pending)'
          };
        },
      );

      // Clean up listeners
      _socket!.off('sendMessageResponse', handleSendMessageResponse);

      log('🔍 Message send response: $response');

      if (response['success'] == true) {
        log('✅ Step 4: Offer message sent successfully');
      } else {
        log('❌ Step 4: Failed to send message');
        log('🔍 Error details: ${response['error'] ?? response['message'] ?? 'Unknown error'}');
      }

      return response;
    } catch (e) {
      log('❌ Step 4: Error sending message: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all chat rooms for the current user
  Future<void> getUserChatRooms() async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot get chat rooms: Socket not connected');
      throw Exception('Socket not connected');
    }

    try {
      log('📋 Loading chat rooms...');
      _socket!.emit('getUserChatRooms', {});
    } catch (e) {
      log('❌ Error loading chat rooms: $e');
      throw Exception('Failed to emit getUserChatRooms: $e');
    }
  }

  /// Load messages for a specific chat room
  Future<void> loadRoomMessages(String roomId) async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot load messages: Socket not connected');
      throw Exception('Socket not connected');
    }

    try {
      log('📨 Loading messages for room: $roomId');
      _socket!.emit('loadRoomMessages', {'roomId': roomId});
    } catch (e) {
      log('❌ Error loading room messages: $e');
      throw Exception('Failed to emit loadRoomMessages: $e');
    }
  }

  /// Test socket connection with a simple ping
  Future<bool> testConnection() async {
    if (!_isConnected || _socket == null) {
      log('❌ Cannot test connection: Socket not connected');
      return false;
    }

    try {
      log('🏓 Testing socket connection with ping...');
      final completer = Completer<bool>();

      _socket!.emitWithAck('ping', {}, ack: (response) {
        log('🏓 Ping response: $response');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          log('⏰ Ping timeout');
          return false;
        },
      );

      return result;
    } catch (e) {
      log('❌ Ping test failed: $e');
      return false;
    }
  }

  /// Complete offer flow: check/create room, join, and send offer message
  Future<Map<String, dynamic>?> sendOfferMessage({
    required String adId,
    required String amount,
    String? adTitle,
    String? adPosterName,
  }) async {
    try {
      log('🎯 Starting offer flow for ₹$amount');

      // Check if socket is connected
      if (!_isConnected || _socket == null) {
        log('🔄 Connecting to chat server...');
        await connect();

        int attempts = 0;
        while (!_isConnected && attempts < 5) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }

        if (!_isConnected) {
          log('❌ Failed to connect to chat server');
          return {
            'success': false,
            'error': 'Failed to connect to chat server'
          };
        }
      }

      // Step 1: Check for existing chat room
      String roomId;
      bool isNewRoom = false;
      final checkResponse = await checkExistingChatRoom(adId);

      if (checkResponse != null &&
          checkResponse['success'] &&
          checkResponse['exists'] == true) {
        roomId = checkResponse['room']['roomId'];
      } else {
        // Step 2: Create new room
        final createResponse = await createChatRoom(adId);
        if (createResponse == null || !createResponse['success']) {
          log('❌ Failed to create chat room');
          return createResponse;
        }

        // Validate response structure before accessing roomId
        if (createResponse['roomId'] == null) {
          log('❌ Invalid response structure from createChatRoom');
          log('🔍 Response: $createResponse');
          return {'success': false, 'error': 'Invalid room creation response'};
        }

        roomId = createResponse['roomId'];
        isNewRoom = true;
      }

      // Step 3: Join the room
      final joinResponse = await joinChatRoom(roomId);
      if (joinResponse == null || !joinResponse['success']) {
        log('❌ Failed to join chat room');
        log('🔄 Attempting to proceed without explicit join confirmation...');

        // Fallback: If join fails, we can still try to send the message
        // The server might not require an explicit join step
        log('⚠️ Proceeding with message sending despite join failure');
      } else {
        log('✅ Successfully joined chat room');
      }

      // Step 4: Send offer message
      final offerMessage = 'I will make an offer for an amount ₹$amount';
      final messageResponse = await sendMessageToRoom(
        roomId: roomId,
        content: offerMessage,
        messageType: 'offer',
        metadata: {
          'amount': amount,
          'adId': adId,
          'adTitle': adTitle,
          'adPosterName': adPosterName,
          'isNewRoom': isNewRoom,
        },
      );

      if (messageResponse != null && messageResponse['success']) {
        log('🎉 Offer flow completed successfully!');
        return {
          'success': true,
          'roomId': roomId,
          'isNewRoom': isNewRoom,
          'message': messageResponse['message'],
          'warning': messageResponse['warning'], // Pass through any warnings
        };
      } else {
        log('❌ Failed to send offer message');
        log('🔄 Attempting to proceed despite message send failure...');

        // Fallback: Even if message send confirmation failed, the message might still be sent
        // We can return a success response with a warning
        log('⚠️ Proceeding with offer flow completion despite message send confirmation failure');
        return {
          'success': true,
          'roomId': roomId,
          'isNewRoom': isNewRoom,
          'message': 'Offer sent (confirmation pending)',
          'warning':
              'Message send confirmation failed, but offer may have been sent',
        };
      }
    } catch (e) {
      log('❌ Offer flow error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
    _chatEventController.close();
    _errorController.close();
  }
}
