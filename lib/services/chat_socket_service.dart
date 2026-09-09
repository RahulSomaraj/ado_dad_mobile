import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';

/// WebSocket service for real-time chat functionality
class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;

  // Stream controllers for real-time updates
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _messagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _roomController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  // Transport-level status (connect / disconnect / connect_error). Kept apart
  // from _errorController so socket.io's own auto-reconnect doesn't surface
  // every blip as a chat error in the UI.
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;

  // Streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<Map<String, dynamic>>> get messagesStream =>
      _messagesController.stream;
  Stream<Map<String, dynamic>> get roomStream => _roomController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Initialize and connect to WebSocket server
  Future<bool> connect() async {
    try {
      // Already connected — reuse the live socket instead of stacking a new
      // forceNew connection whose duplicate listeners double-deliver messages
      // (QA audit 2026-07-10).
      if (_isConnected && _socket?.connected == true) {
        print('✅ Socket already connected — reusing existing connection');
        return true;
      }
      // Tear down any stale socket before creating a fresh one.
      if (_socket != null) {
        try {
          _socket!.dispose();
        } catch (_) {}
        _socket = null;
      }

      // Get stored token
      final token = await getToken();
      print('🔑 Retrieved token: ${token != null ? 'Present' : 'Missing'}');

      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        _errorController
            .add('No authentication token found. Please login first.');
        return false;
      }

      // Clean token (remove 'Bearer ' prefix if present)
      final cleanToken = token.replaceAll('Bearer ', '');

      // Get base URL from config
      final baseUrl = AppConfig.baseUrl;
      final socketUrl =
          '$baseUrl/chat'; // Add /chat namespace to match HTML file

      print('🔌 Connecting to WebSocket...');
      print('🌐 Server URL: $socketUrl');
      print('🔑 Token: ${cleanToken.substring(0, 20)}...');
      print('⏰ Timeout: 10000ms');

      // Validate URL
      if (baseUrl.isEmpty) {
        print('❌ Base URL is empty');
        _errorController.add(
            'Server URL not configured. Please check your environment settings.');
        return false;
      }

      // Create socket connection
      _socket = IO.io(
          socketUrl,
          IO.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .setAuth({'token': cleanToken})
              .setTimeout(10000)
              .enableForceNew()
              .build());

      _setupEventListeners();

      // Wait for connection with timeout using Completer
      print('⏳ Waiting for connection...');
      final completer = Completer<bool>();

      // Set up a one-time listener for connection
      late StreamSubscription connectionSub;
      connectionSub = _connectionController.stream.listen((connected) {
        if (connected && !completer.isCompleted) {
          print('✅ Socket connected successfully');
          connectionSub.cancel();
          completer.complete(true);
        }
      });

      // Set timeout
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('❌ Socket connection timeout');
          connectionSub.cancel();
          _errorController.add(
              'Connection timeout. Please check your internet connection and server status.');
          completer.complete(false);
        }
      });

      return await completer.future;
    } catch (e) {
      print('❌ Socket connection error: $e');
      _errorController.add('Connection failed: $e');
      return false;
    }
  }

  /// Setup socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('✅ WebSocket connected successfully!');
      print('🔗 Socket ID: ${_socket!.id}');
      _isConnected = true;
      _connectionController.add(true);
      _addConnectionStatus(true);

      // Server-side room membership dies with the old socket. After a
      // (re)connect, re-join the active room so live messages resume.
      final roomToRejoin = _currentRoomId;
      if (roomToRejoin != null) {
        print('🔁 Re-joining room after (re)connect: $roomToRejoin');
        _socket!.emit('joinChatRoom', {'roomId': roomToRejoin});
      }

      // Start connection monitoring to keep it alive
      _startConnectionMonitoring();
    });

    _socket!.onDisconnect((reason) {
      print('❌ WebSocket disconnected!');
      print('📝 Reason: $reason');
      print('🔍 Disconnect timestamp: ${DateTime.now().toIso8601String()}');
      _isConnected = false;
      _connectionController.add(false);
      _addConnectionStatus(false);
    });

    _socket!.onConnectError((error) {
      print('❌ WebSocket connection error!');
      print('💥 Error details: $error');
      _isConnected = false;
      _connectionController.add(false);
      _addConnectionStatus(false);
    });

    _socket!.on('connect_timeout', (data) {
      print('⏰ WebSocket connect timeout: $data');
      _isConnected = false;
      _connectionController.add(false);
      _addConnectionStatus(false);
    });

    // Chat room events
    _socket!.on('connected', (data) {
      print('🔗 Connected event: $data');
    });

    _socket!.on('chatRoomCreated', (data) {
      print('🏠 Chat room created: ${data['data']?['roomId']}');
      // Set the current room ID when room is created
      final roomId = data['data']?['roomId'] as String?;
      if (roomId != null) {
        _currentRoomId = roomId;
        print('✅ Set current room ID from chatRoomCreated event: $roomId');
        // Automatically join the newly created room
        print('🚪 Auto-joining newly created room: $roomId');
        _socket!.emit('joinChatRoom', {'roomId': roomId});
      }
      _roomController.add({'type': 'roomCreated', 'data': data});
    });

    _socket!.on('userJoinedRoom', (data) {
      print('👤 User joined room: ${data['roomId']}');
      _roomController.add({'type': 'userJoined', 'data': data});
    });

    _socket!.on('userLeftRoom', (data) {
      print('👋 User left room: ${data['roomId']}');
      _roomController.add({'type': 'userLeft', 'data': data});
    });

    // Message events - server broadcasts individual messages
    _socket!.on('message', (message) {
      print('💬 Message received: ${message['content']}');
      print('📨 Full message data: $message');
      print('🏠 Room ID: ${message['roomId']}');
      print('👤 Sender ID: ${message['senderId']}');

      // Add the individual message as a list to the stream
      _messagesController.add([message as Map<String, dynamic>]);
    });

    // Alternative message event (as mentioned in HTML file) - Only for logging
    _socket!.on('newMessage', (message) {
      print('💬 New message received (alternative): ${message['content']}');
      print('📨 Full new message data: $message');
      print('🏠 Room ID: ${message['roomId']}');
      print('👤 Sender ID: ${message['senderId']}');
      print(
          '⚠️ Using newMessage event as backup - message already processed by main listener');

      // Don't add to stream to prevent duplicates
      // The main 'message' event should handle all messages
    });

    // Add debugging for all socket events
    _socket!.onAny((event, data) {
      print('🔍 Socket event received: $event');
      print('📦 Event data: $data');
    });

    _socket!.on('sendMessageResponse', (response) {
      print('📨 SendMessageResponse received: $response');
      if (response['success'] == true) {
        print('✅ Message sent successfully');
      } else {
        print('❌ Message failed: ${response['error']}');
        _errorController.add('Message failed: ${response['error']}');
      }
    });

    // Room list response
    _socket!.on('getUserChatRoomsResponse', (response) {
      if (response['success'] == true) {
        final rooms = response['chatRooms'] ?? [];
        print('📋 Loaded ${rooms.length} chat rooms');
        _roomController.add({'type': 'roomsList', 'data': response});
      } else {
        print('❌ Failed to load rooms: ${response['error']}');
        _errorController.add('Failed to load rooms: ${response['error']}');
      }
    });

    // Join room response
    _socket!.on('joinChatRoomResponse', (response) {
      print('🚪 Join room response: $response');
      if (response['success'] == true) {
        _currentRoomId = response['roomId'];
        _roomController.add({'type': 'roomJoined', 'data': response});
      } else {
        _errorController.add('Failed to join room: ${response['error']}');
      }
    });

    // Messages response
    _socket!.on('getRoomMessagesResponse', (response) {
      print('📨 Messages response: ${response['success']}');
      if (response['success'] == true) {
        final messages = (response['data'] as List<dynamic>?)
                ?.map((message) => message as Map<String, dynamic>)
                .toList() ??
            [];
        print('✅ Loaded ${messages.length} messages');
        _messagesController.add(messages);
      } else {
        print('❌ Failed to load messages: ${response['error']}');
        _errorController.add('Failed to load messages: ${response['error']}');
      }
    });
  }

  /// Create a new chat room for an ad
  Future<void> createChatRoom(String adId) async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    print('🏠 Creating chat room for ad: $adId');
    _socket!.emitWithAck('createChatRoom', {'adId': adId}, ack: (response) {
      print('📩 CreateChatRoom Ack received: $response');
      if (response['success'] == true) {
        // Set the current room ID to the newly created room
        final roomId = response['data']?['roomId'] as String?;
        if (roomId != null) {
          _currentRoomId = roomId;
          print('✅ Set current room ID to: $roomId');
        }
        _roomController.add({'type': 'roomCreated', 'data': response});
      } else {
        _errorController.add('Failed to create room: ${response['error']}');
      }
    });
  }

  /// Get user's chat rooms
  Future<List<Map<String, dynamic>>?> getUserChatRooms() async {
    if (!_isConnected || _socket == null) return null;

    final completer = Completer<List<Map<String, dynamic>>?>();
    _socket!.emitWithAck('getUserChatRooms', {}, ack: (response) {
      if (response['success'] == true) {
        final data = (response['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        completer.complete(data);
      } else {
        completer.complete(null);
      }
    });

    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  /// Join a chat room and wait for success callback
  Future<bool> joinRoomAndWait(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      throw Exception('Not connected to server');
    }

    print('🚪 Joining room: $roomId');

    final completer = Completer<bool>();

    _socket!.emit('joinChatRoom', {'roomId': roomId});

    // Also listen for server push (redundant safety)
    _socket!.once('joinChatRoomResponse', (data) {
      print("🚪 Join room response: $data");
      if (data['success'] == true) {
        _currentRoomId = data['roomId'];
        completer.complete(true);
      } else {
        completer.completeError(Exception(data['error'] ?? 'Join failed'));
      }
    });

    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      throw Exception('Join timeout');
    });
  }

  /// Join a chat room (legacy method)
  Future<void> joinChatRoom(String roomId) async {
    await joinRoomAndWait(roomId);
  }

  /// Get messages for a room
  Future<void> getRoomMessages(String roomId) async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    print('💬 Loading messages for room: $roomId');
    _socket!.emit('getRoomMessages', {'roomId': roomId});
  }

  /// Tell the server the current user has read everything in [roomId] so its
  /// unread count is reset. No-op if the socket isn't connected.
  Future<void> markRoomRead(String roomId) async {
    if (!_isConnected || _socket == null) {
      print('⚠️ markRoomRead skipped — socket not connected');
      return;
    }
    print('👁️ Marking room as read: $roomId');
    _socket!.emit('markChatRoomRead', {'roomId': roomId});
  }

  /// Send a message to the current room with connection persistence.
  /// For image/audio, pass type and optional attachments.
  void sendMessage(String content,
      {String type = 'text', List<Map<String, dynamic>>? attachments}) async {
    if (_currentRoomId == null) {
      print('❌ No room selected, cannot send message');
      return;
    }

    // Ensure connection is stable before sending
    await _ensureConnection();

    if (!_isConnected || _socket == null) {
      print(
          '❌ Socket not connected after ensuring connection, cannot send message');
      return;
    }

    print('📤 Sending message: $content');
    print('🏠 Room ID: $_currentRoomId');
    print('📝 Type: $type');
    if (attachments != null) print('📎 Attachments: ${attachments.length}');
    print('🔍 Socket connected before emit: $_isConnected');
    print('🔍 Socket ID before emit: ${_socket!.id}');

    try {
      final payload = <String, dynamic>{
        'roomId': _currentRoomId,
        'content': content,
        'type': type,
      };
      if (attachments != null && attachments.isNotEmpty) {
        payload['attachments'] = attachments;
      }
      _socket!.emit('sendMessage', payload);

      // Optional: Use emitWithAck for better reliability
      // _socket!.emitWithAck('sendMessage', {
      //   'roomId': _currentRoomId,
      //   'content': content,
      //   'type': type,
      // }, ack: (res) => print('✅ Ack: $res'));

      print('✅ Send message event emitted');
      print('🔍 Socket connected after emit: $_isConnected');
      print('🔍 Socket ID after emit: ${_socket?.id}');

      // Keep connection alive after sending
      _keepConnectionAlive();
    } catch (e) {
      print('❌ Error sending message: $e');
      _errorController.add('Failed to send message: $e');
    }
  }

  Future<void> ping() async {
    if (!_isConnected || _socket == null) {
      _errorController.add('Not connected to server');
      return;
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;
    print('🏓 Testing ping...');

    _socket!.emit('ping', {'t0': startTime});
  }

  /// Ensure connection is stable before operations
  Future<void> _ensureConnection() async {
    if (!_isConnected || _socket == null) {
      print('🔄 Connection lost, attempting to reconnect...');
      final roomToRejoin = _currentRoomId;
      final reconnected = await connect();
      // Server-side room membership dies with the old socket — rejoin the
      // active room or subsequent sendMessage calls are silently dropped
      // (QA audit 2026-07-10).
      if (reconnected && roomToRejoin != null && _socket != null) {
        print('🔁 Rejoining room after reconnect: $roomToRejoin');
        _socket!.emit('joinChatRoom', {'roomId': roomToRejoin});
        _currentRoomId = roomToRejoin;
      }
    } else {
      print('✅ Connection is stable');
    }
  }

  /// Keep connection alive after operations
  void _keepConnectionAlive() {
    // Send a ping to keep connection alive
    if (_isConnected && _socket != null) {
      _socket!
          .emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
      print('🏓 Ping sent to keep connection alive');
    }
  }

  /// Monitor connection health
  Timer? _monitoringTimer;

  void _startConnectionMonitoring() {
    // A single periodic timer — previously one was spawned per onConnect and
    // never cancelled, so stale timers piled up and each triggered its own
    // reconnect storm (QA audit 2026-07-10).
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _socket != null) {
        _socket!
            .emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
        print('🏓 Periodic ping sent to maintain connection');
      } else {
        // Do NOT call connect() here: it disposes the socket that socket.io
        // is already trying to reconnect and raises a spurious
        // "Connection timeout" error. Let the built-in reconnection work.
        print('⚠️ Socket disconnected — waiting for socket.io auto-reconnect');
      }
    });
  }

  void _addConnectionStatus(bool connected) {
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(connected);
    }
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _isConnected = false;
    _currentRoomId = null;
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
    _addConnectionStatus(false);
    print('🔌 Disconnected from WebSocket');
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    if (!_connectionController.isClosed) _connectionController.close();
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }
    if (!_messageController.isClosed) _messageController.close();
    if (!_messagesController.isClosed) _messagesController.close();
    if (!_roomController.isClosed) _roomController.close();
    if (!_errorController.isClosed) _errorController.close();
  }
}
