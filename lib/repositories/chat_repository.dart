import 'dart:async';
import 'package:ado_dad_user/services/chat_socket_service.dart';
import 'package:ado_dad_user/services/chat_api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';

/// Repository for WebSocket connection testing
class ChatRepository {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  ChatRepository._internal();

  final ChatSocketService _socketService = ChatSocketService();
  final ChatApiService _apiService = ChatApiService();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters
  bool get isConnected => _socketService.isConnected;
  ChatSocketService get socketService => _socketService;

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final sharedPrefs = SharedPrefs();
      final userId = await sharedPrefs.getUserId();
      return userId;
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }

  // Streams
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStream => _socketService.connectionStream;
  Stream<List<Map<String, dynamic>>> get roomsStream => _roomsController.stream;
  Stream<List<Map<String, dynamic>>> get messagesStream =>
      _socketService.messagesStream;

  // Local storage
  final List<Map<String, dynamic>> _rooms = [];
  final StreamController<List<Map<String, dynamic>>> _roomsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  /// Initialize chat repository
  Future<void> initialize() async {
    // Setup socket event listeners
    _socketService.connectionStream.listen((connected) {
      // Connection status is handled by the socket service
    });

    _socketService.errorStream.listen((error) {
      _errorController.add(error);
    });

    // Listen to room events
    _socketService.roomStream.listen((event) {
      _handleRoomEvent(event);
    });
  }

  /// Handle room events from socket
  void _handleRoomEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>?;

    if (type == 'roomsList' && data != null) {
      final rooms = (data['chatRooms'] as List<dynamic>?)
              ?.map((room) => _formatRoomData(room))
              .toList() ??
          [];

      _rooms.clear();
      _rooms.addAll(rooms);
      _roomsController.add(List.from(_rooms));
    }
  }

  /// Format room data for UI
  Map<String, dynamic> _formatRoomData(dynamic room) {
    final otherUser = room['otherUser'] as Map<String, dynamic>?;
    final latestMessage = room['latestMessage'] as Map<String, dynamic>?;
    final adDetails = room['adDetails'] as Map<String, dynamic>?;

    return {
      'id': room['roomId'] ?? '',
      'name': otherUser?['name'] ?? 'Chat Room',
      'lastMessage': latestMessage?['content'] ?? 'No messages yet',
      'timestamp': room['lastMessageAt'] != null
          ? DateTime.tryParse(room['lastMessageAt']) ?? DateTime.now()
          : DateTime.now(),
      'unreadCount': 0, // API doesn't provide unread count
      'adId': room['adId'] ?? '',
      'status': room['status'] ?? 'active',
      'messageCount': room['messageCount'] ?? 0,
      'otherUser': otherUser,
      'adDetails': adDetails,
      'adTitle': adDetails?['title'] ??
          'Ad #${room['adId'] ?? 'Unknown'}', // Extract title from adDetails
    };
  }

  /// Connect to chat server
  Future<bool> connect() async {
    try {
      final success = await _socketService.connect();
      if (success) {
        print('✅ Chat repository connected');
        return true;
      } else {
        _errorController.add('Failed to connect to chat server');
        return false;
      }
    } catch (e) {
      _errorController.add('Connection error: $e');
      return false;
    }
  }

  /// Disconnect from chat server
  Future<void> disconnect() async {
    await _socketService.disconnect();
    print('🔌 Disconnected from WebSocket');
  }

  /// Get user's chat rooms from HTTP API
  Future<void> getUserChatRooms() async {
    try {
      print('📋 Fetching chat rooms from API...');
      final response = await _apiService.getUserChatRooms();

      if (response['success'] == true) {
        final rooms = (response['data'] as List<dynamic>?)
                ?.map((room) => _formatRoomData(room))
                .toList() ??
            [];

        _rooms.clear();
        _rooms.addAll(rooms);

        // Check if controller is still open before adding events
        if (!_roomsController.isClosed) {
          _roomsController.add(List.from(_rooms));
          print('✅ Loaded ${rooms.length} chat rooms from API');
        } else {
          print('⚠️ Rooms controller is closed, cannot add events');
        }
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      print('❌ Error fetching chat rooms: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Failed to load chat rooms: $e');
      }
    }
  }

  /// Join a chat room and wait for success callback
  Future<void> joinChatRoom(String roomId) async {
    try {
      print('🚪 Joining chat room: $roomId');
      print('🔍 Socket connection status: ${_socketService.isConnected}');

      // Check if socket is connected, if not, try to connect first
      if (!_socketService.isConnected) {
        print('🔌 Socket not connected, attempting to connect...');
        final connected = await _socketService.connect();
        if (!connected) {
          throw Exception('Failed to connect to server');
        }
        print('✅ Socket connected successfully');
      } else {
        print('✅ Socket already connected');
      }

      // Use the new joinRoomAndWait method that waits for callback
      final success = await _socketService.joinRoomAndWait(roomId);
      if (success) {
        print('✅ Successfully joined room: $roomId');
      } else {
        throw Exception('Failed to join room');
      }
    } catch (e) {
      print('❌ Error joining room: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Failed to join room: $e');
      }
      rethrow;
    }
  }

  /// Get messages for a specific room
  Future<List<Map<String, dynamic>>> getRoomMessages(String roomId) async {
    try {
      print('📨 Fetching messages for room: $roomId');

      // Use HTTP API to get messages
      final response = await _apiService.getRoomMessages(roomId);

      if (response['success'] == true) {
        final messagesData = response['data'] as Map<String, dynamic>?;
        final messages = (messagesData?['messages'] as List<dynamic>?)
                ?.map((message) => _formatMessageData(message))
                .toList() ??
            [];

        print('✅ Loaded ${messages.length} messages from API');
        return messages;
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Failed to load messages: $e');
      }
      rethrow;
    }
  }

  /// Send message via WebSocket only (like HTML file)
  void sendMessage(String content, {String type = 'text'}) {
    try {
      print('📤 Sending message via WebSocket only');
      _socketService.sendMessage(content, type: type);
    } catch (e) {
      print('❌ Error sending message: $e');
      if (!_errorController.isClosed) {
        _errorController.add('Failed to send message: $e');
      }
    }
  }

  /// Helper method to join a chat room
  Future<void> joinChatRoomHelper(String roomId) async {
    _socketService.joinChatRoom(roomId);
  }

  /// Helper method to send message with room ID
  Future<void> sendMessageToRoom(String roomId, String message,
      {String type = 'text'}) async {
    _socketService.sendMessage(message, type: type);
  }

  /// Get or create room for an ad (mirrors HTML flow)
  Future<String> getOrCreateRoom(String adId) async {
    try {
      // For backward compatibility, we'll use the old API without otherUserId
      // This might need to be updated based on backend requirements
      print(
          "⚠️ Using legacy room check - consider updating to use otherUserId");
      final check = await _apiService.checkRoomExists(
          adId, ''); // Empty otherUserId for legacy
      if (check['data']?['exists'] == true) {
        print("🟢 Room exists");
        return check['data']['roomId'];
      } else {
        print("🟢 Room created");
        return await createChatRoom(adId) ??
            (throw Exception('Failed to create room'));
      }
    } catch (e) {
      print("⚠️ Room check failed, fallback to create: $e");
      return await createChatRoom(adId) ??
          (throw Exception('Failed to create room'));
    }
  }

  /// Get or create room for an ad and other user
  Future<String> getOrCreateRoomForUser(String adId, String otherUserId) async {
    try {
      final check = await _apiService.checkRoomExists(adId, otherUserId);
      if (check['data']?['exists'] == true) {
        print("🟢 Room exists");
        return check['data']['roomId'];
      } else {
        print("🟢 Room created");
        return await createChatRoom(adId) ??
            (throw Exception('Failed to create room'));
      }
    } catch (e) {
      print("⚠️ Room check failed, fallback to create: $e");
      return await createChatRoom(adId) ??
          (throw Exception('Failed to create room'));
    }
  }

  /// Send offer message after join confirmation (final stable version)
  Future<void> sendOfferMessage(String adId, double amount) async {
    String? roomId;

    try {
      // 1️⃣ Check if room exists (using legacy approach for backward compatibility)
      print(
          "⚠️ Using legacy room check - consider updating to use otherUserId");
      final result = await _apiService.checkRoomExists(
          adId, ''); // Empty otherUserId for legacy
      final exists = result['data']?['exists'] ?? false;
      roomId = result['data']?['roomId'];

      if (exists && roomId != null) {
        print("🟢 Room exists for ad: $adId ($roomId)");
      } else {
        print("❌ No room exists, creating new...");
        roomId = await createChatRoom(adId);
      }

      // 2️⃣ Try joining room and wait for success
      final joined = await _socketService.joinRoomAndWait(roomId!);
      print("✅ Joined room: $joined");

      // 3️⃣ Send message only after successful join
      final msg =
          'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
      _socketService.sendMessage(msg, type: 'offer');
      print('✅ Offer message sent successfully in room: $roomId');
    } catch (e) {
      if (e.toString().contains('not a participant')) {
        print("⚠️ Not a participant, creating your own room...");
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);
        print("✅ Joined new room: $joined");

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
        print('✅ Offer message sent successfully in room: $roomId');
      } else {
        print("⚠️ Room join failed, creating fallback room...");
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);
        print("✅ Joined fallback room: $joined");

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
        print('✅ Offer message sent successfully in room: $roomId');
      }
    }
  }

  /// Send offer message for specific ad and user
  Future<void> sendOfferMessageForUser(
      String adId, String otherUserId, double amount) async {
    String? roomId;

    try {
      // 1️⃣ Check if room exists
      final result = await _apiService.checkRoomExists(adId, otherUserId);
      final exists = result['data']?['exists'] ?? false;
      roomId = result['data']?['roomId'];

      if (exists && roomId != null) {
        print("🟢 Room exists for ad: $adId and user: $otherUserId ($roomId)");
      } else {
        print("❌ No room exists, creating new...");
        roomId = await createChatRoom(adId);
      }

      // 2️⃣ Try joining room and wait for success
      final joined = await _socketService.joinRoomAndWait(roomId!);
      print("✅ Joined room: $joined");

      // 3️⃣ Send message only after successful join
      final msg =
          'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
      _socketService.sendMessage(msg, type: 'offer');
      print('✅ Offer message sent successfully in room: $roomId');
    } catch (e) {
      if (e.toString().contains('not a participant')) {
        print("⚠️ Not a participant, creating your own room...");
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);
        print("✅ Joined new room: $joined");

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
        print('✅ Offer message sent successfully in room: $roomId');
      } else {
        print("⚠️ Room join failed, creating fallback room...");
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);
        print("✅ Joined fallback room: $joined");

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
        print('✅ Offer message sent successfully in room: $roomId');
      }
    }
  }

  /// Check if a room exists for an ad using API
  Future<Map<String, dynamic>?> checkRoomExistsForAd(String adId) async {
    try {
      print('🔍 Checking if room exists for ad: $adId');
      print(
          "⚠️ Using legacy room check - consider updating to use otherUserId");
      final response = await _apiService.checkRoomExists(
          adId, ''); // Empty otherUserId for legacy

      // The API response structure is: {success: true, data: {exists: true, roomId: "..."}}
      final data = response['data'] as Map<String, dynamic>?;
      final exists = data?['exists'] as bool? ?? false;
      final roomId = data?['roomId'] as String?;

      if (response['success'] == true && exists == true) {
        print('✅ Room exists: $roomId');
        return {'exists': true, 'roomId': roomId, 'data': response};
      } else {
        print('❌ No room exists for this ad');
        return {'exists': false, 'roomId': null, 'data': response};
      }
    } catch (e) {
      print('❌ Error checking room existence: $e');
      return null;
    }
  }

  /// Check if a room exists for an ad and other user using API
  Future<Map<String, dynamic>?> checkRoomExistsForAdAndUser(
      String adId, String otherUserId) async {
    try {
      print(
          '🔍 Checking if room exists for ad: $adId and other user: $otherUserId');
      final response = await _apiService.checkRoomExists(adId, otherUserId);

      // The API response structure is: {success: true, data: {exists: true, roomId: "..."}}
      final data = response['data'] as Map<String, dynamic>?;
      final exists = data?['exists'] as bool? ?? false;
      final roomId = data?['roomId'] as String?;

      if (response['success'] == true && exists == true) {
        print('✅ Room exists: $roomId');
        return {'exists': true, 'roomId': roomId, 'data': response};
      } else {
        print('❌ No room exists for this ad and user combination');
        return {'exists': false, 'roomId': null, 'data': response};
      }
    } catch (e) {
      print('❌ Error checking room existence: $e');
      return null;
    }
  }

  /// Find existing room by ad ID (legacy method - kept for compatibility)
  Future<String?> findRoomByAdId(String adId) async {
    try {
      print('🔍 Checking existing rooms for adId: $adId');

      // Ensure socket connected
      if (!_socketService.isConnected) await _socketService.connect();

      // Ask backend for user's chat rooms
      final rooms = await _socketService.getUserChatRooms();
      if (rooms == null || rooms.isEmpty) return null;

      // Find a room that matches adId
      for (final room in rooms) {
        final roomAdId = room['ad']?['id'] ?? room['adId'];
        if (roomAdId == adId) {
          print('✅ Found matching room: ${room['id']}');
          return room['id'];
        }
      }

      print('⚠️ No room found for this ad');
      return null;
    } catch (e) {
      print('❌ Error checking rooms: $e');
      return null;
    }
  }

  /// Check if a chat room exists for an ad
  Future<String?> getExistingRoomForAd(String adId) async {
    try {
      print('🔍 Checking for existing room for ad: $adId');

      // Get all chat rooms
      final response = await _apiService.getUserChatRooms();
      final rooms = response['data'] as List<dynamic>? ?? [];

      // Look for room with matching adId
      for (final room in rooms) {
        final roomData = room as Map<String, dynamic>;
        if (roomData['adId'] == adId) {
          print('✅ Found existing room: ${roomData['_id']}');
          return roomData['_id'] as String?;
        }
      }

      print('❌ No existing room found for ad: $adId');
      return null;
    } catch (e) {
      print('❌ Error checking existing room: $e');
      return null;
    }
  }

  /// Create a new chat room for an ad
  Future<String?> createChatRoom(String adId) async {
    try {
      print('🏠 Creating chat room for adId: $adId');

      // Ensure socket connected
      if (!_socketService.isConnected) {
        print('🔌 Socket not connected, connecting...');
        final connected = await _socketService.connect();
        if (!connected) throw Exception('Failed to connect socket');
      }

      final completer = Completer<String?>();
      StreamSubscription? subscription;

      // Listen once for room creation response
      subscription = _socketService.roomStream.listen((event) {
        if (event['type'] == 'roomCreated') {
          final roomId = event['data']?['data']?['roomId'];
          print('✅ Room created with ID: $roomId');
          subscription?.cancel(); // Cancel subscription after first event
          completer.complete(roomId);
        }
      });

      // Emit room creation request
      _socketService.createChatRoom(adId);

      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Room creation timed out');
          subscription?.cancel(); // Cancel subscription on timeout
          return null;
        },
      );

      // Ensure subscription is canceled
      subscription.cancel();
      return result;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      _errorController.add('Failed to create chat room: $e');
      return null;
    }
  }

  /// Format message data for UI
  Map<String, dynamic> _formatMessageData(dynamic message) {
    final sender = message['sender'] as Map<String, dynamic>?;

    return {
      'id': message['_id'] ?? '',
      'roomId': message['roomId'] ?? '',
      'senderId': message['senderId'] ?? '',
      'type': message['type'] ?? 'text',
      'content': message['content'] ?? '',
      'attachments': message['attachments'] ?? [],
      'isRead': message['isRead'] ?? false,
      'createdAt': message['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': message['updatedAt'] ?? DateTime.now().toIso8601String(),
      'sender': {
        'id': sender?['_id'] ?? '',
        'name': sender?['name'] ?? 'Unknown User',
        'email': sender?['email'] ?? '',
        'profilePic': sender?['profilePic'] ?? 'default-profile-pic-url',
      },
    };
  }

  /// Test ping to server
  Future<void> ping() async {
    try {
      await _socketService.ping();
    } catch (e) {
      if (!_errorController.isClosed) {
        _errorController.add('Ping failed: $e');
      }
    }
  }

  /// Clean up resources
  void dispose() {
    if (!_errorController.isClosed) {
      _errorController.close();
    }
    if (!_roomsController.isClosed) {
      _roomsController.close();
    }
    _socketService.dispose();
  }
}
