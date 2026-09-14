import 'dart:async';
import 'dart:typed_data';
import 'package:ado_dad_user/services/chat_socket_service.dart';
import 'package:ado_dad_user/services/chat_api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';

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
    } catch (_) {
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

  StreamSubscription<String>? _socketErrorSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketRoomSubscription;
  bool _initialized = false;

  /// Initialize chat repository. Idempotent: this is a singleton and every
  /// InitializeChat used to stack another set of listeners, so each socket
  /// event was forwarded N times.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _socketErrorSubscription?.cancel();
    await _socketRoomSubscription?.cancel();

    _socketErrorSubscription = _socketService.errorStream.listen((error) {
      if (!_errorController.isClosed) _errorController.add(error);
    });

    // Listen to room events
    _socketRoomSubscription = _socketService.roomStream.listen((event) {
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

    final lastMessageType = latestMessage?['type'] as String? ?? 'text';
    return {
      'id': room['roomId'] ?? '',
      'name': otherUser?['name'] ?? 'Chat Room',
      'lastMessage': latestMessage?['content'] ?? 'No messages yet',
      'lastMessageType': lastMessageType,
      'timestamp': room['lastMessageAt'] != null
          ? DateTime.tryParse(room['lastMessageAt']) ?? DateTime.now()
          : DateTime.now(),
      // Unread count from the backend when available. Accepts `unreadCount`
      // or `unread`; falls back to 0 so the badge simply stays hidden.
      'unreadCount': _asInt(room['unreadCount'] ?? room['unread']),
      'adId': room['adId'] ?? '',
      'status': room['status'] ?? 'active',
      'messageCount': room['messageCount'] ?? 0,
      'otherUser': otherUser,
      'adDetails': adDetails,
      'adTitle': adDetails?['title'] ??
          'Ad #${room['adId'] ?? 'Unknown'}', // Extract title from adDetails
      // Ad price from the room payload (when backend includes adDetails.price),
      // so the chat page can show it on the pinned card without a 2nd fetch.
      'adPrice': _asInt(adDetails?['price'], orNull: true),
    };
  }

  /// Coerce a dynamic numeric/string value to an int.
  /// Returns null (when [orNull]) for missing values, otherwise 0.
  static int? _asInt(dynamic v, {bool orNull = false}) {
    if (v == null) return orNull ? null : 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final parsed = int.tryParse(v.toString());
    return parsed ?? (orNull ? null : 0);
  }

  /// Mark a room as read: optimistically zero its local unread count (so the
  /// badge clears instantly) and tell the server. Safe to call repeatedly.
  Future<void> markRoomRead(String roomId) async {
    var changed = false;
    for (final room in _rooms) {
      if (room['id'] == roomId && ((room['unreadCount'] as int?) ?? 0) != 0) {
        room['unreadCount'] = 0;
        changed = true;
      }
    }
    if (changed) _roomsController.add(List.from(_rooms));
    try {
      await _socketService.markRoomRead(roomId);
    } catch (_) {
    }
  }

  /// Connect to chat server
  Future<bool> connect() async {
    try {
      final success = await _socketService.connect();
      if (success) {
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
  }

  /// Get user's chat rooms from HTTP API
  Future<void> getUserChatRooms() async {
    try {
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
        } else {
        }
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      if (!_errorController.isClosed) {
        _errorController.add('Failed to load chat rooms: $e');
      }
    }
  }

  /// Join a chat room and wait for success callback
  Future<void> joinChatRoom(String roomId) async {
    try {

      // Check if socket is connected, if not, try to connect first
      if (!_socketService.isConnected) {
        final connected = await _socketService.connect();
        if (!connected) {
          throw Exception('Failed to connect to server');
        }
      } else {
      }

      // Use the new joinRoomAndWait method that waits for callback
      final success = await _socketService.joinRoomAndWait(roomId);
      if (success) {
      } else {
        throw Exception('Failed to join room');
      }
    } catch (e) {
      if (!_errorController.isClosed) {
        _errorController.add('Failed to join room: $e');
      }
      rethrow;
    }
  }

  /// Get messages for a specific room
  Future<List<Map<String, dynamic>>> getRoomMessages(String roomId) async {
    try {

      // Use HTTP API to get messages
      final response = await _apiService.getRoomMessages(roomId);

      if (response['success'] == true) {
        final messagesData = response['data'] as Map<String, dynamic>?;
        final messages = (messagesData?['messages'] as List<dynamic>?)
                ?.map((message) => _formatMessageData(message))
                .toList() ??
            [];

        return messages;
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      if (!_errorController.isClosed) {
        _errorController.add('Failed to load messages: $e');
      }
      rethrow;
    }
  }

  /// Send message via WebSocket only (like HTML file)
  void sendMessage(String content, {String type = 'text'}) {
    try {
      _socketService.sendMessage(content, type: type);
    } catch (e) {
      if (!_errorController.isClosed) {
        _errorController.add('Failed to send message: $e');
      }
    }
  }

  /// Send message with attachments via API (for image/audio). Falls back to
  /// WebSocket if the API POST /chats/rooms/:roomId/messages is not available.
  Future<void> sendMessageWithAttachments(String roomId, String type,
      List<Map<String, dynamic>> attachments,
      {String content = ''}) async {
    try {
      await _apiService.sendMessage(roomId, content,
          type: type, attachments: attachments);
    } catch (e) {
      final errStr = e.toString();
      final isPostNotAvailable = errStr.contains('Cannot POST') ||
          errStr.contains('404') ||
          errStr.contains('Not Found');
      if (isPostNotAvailable) {
        try {
          await _socketService.joinRoomAndWait(roomId);
          _socketService.sendMessage(content,
              type: type, attachments: attachments);
        } catch (socketErr) {
          if (!_errorController.isClosed) {
            _errorController.add('Failed to send message: $socketErr');
          }
          rethrow;
        }
      } else {
        if (!_errorController.isClosed) {
          _errorController.add('Failed to send message: $e');
        }
        rethrow;
      }
    }
  }

  /// Upload file to S3 and send as image message.
  Future<void> sendImageMessage(
      String roomId, Uint8List fileBytes, String mimeType) async {
    final url = await AddRepository().uploadFileToS3(fileBytes, mimeType,
        filePrefix: 'image');
    if (url == null) throw Exception('Image upload failed');
    await sendMessageWithAttachments(roomId, 'image', [
      {'type': 'image', 'url': url, 'mimeType': mimeType, 'size': fileBytes.length}
    ]);
  }

  /// Upload file to S3 and send as audio message.
  Future<void> sendAudioMessage(
      String roomId, Uint8List fileBytes, String mimeType) async {
    final url = await AddRepository().uploadFileToS3(fileBytes, mimeType,
        filePrefix: 'audio');
    if (url == null) throw Exception('Audio upload failed');
    await sendMessageWithAttachments(roomId, 'audio', [
      {'type': 'audio', 'url': url, 'mimeType': mimeType, 'size': fileBytes.length}
    ]);
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
      final check = await _apiService.checkRoomExists(
          adId, ''); // Empty otherUserId for legacy
      if (check['data']?['exists'] == true) {
        return check['data']['roomId'];
      } else {
        return await createChatRoom(adId) ??
            (throw Exception('Failed to create room'));
      }
    } catch (_) {
      return await createChatRoom(adId) ??
          (throw Exception('Failed to create room'));
    }
  }

  /// Get or create room for an ad and other user
  Future<String> getOrCreateRoomForUser(String adId, String otherUserId) async {
    try {
      final check = await _apiService.checkRoomExists(adId, otherUserId);
      if (check['data']?['exists'] == true) {
        return check['data']['roomId'];
      } else {
        return await createChatRoom(adId) ??
            (throw Exception('Failed to create room'));
      }
    } catch (_) {
      return await createChatRoom(adId) ??
          (throw Exception('Failed to create room'));
    }
  }

  /// Send offer message after join confirmation (final stable version)
  Future<void> sendOfferMessage(String adId, double amount) async {
    String? roomId;

    try {
      // 1️⃣ Check if room exists (using legacy approach for backward compatibility)
      final result = await _apiService.checkRoomExists(
          adId, ''); // Empty otherUserId for legacy
      final exists = result['data']?['exists'] ?? false;
      roomId = result['data']?['roomId'];

      if (exists && roomId != null) {
      } else {
        roomId = await createChatRoom(adId);
      }

      // 2️⃣ Try joining room and wait for success
      final joined = await _socketService.joinRoomAndWait(roomId!);

      // 3️⃣ Send message only after successful join
      final msg =
          'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
      _socketService.sendMessage(msg, type: 'offer');
    } catch (e) {
      if (e.toString().contains('not a participant')) {
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
      } else {
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
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
      } else {
        roomId = await createChatRoom(adId);
      }

      // 2️⃣ Try joining room and wait for success
      final joined = await _socketService.joinRoomAndWait(roomId!);

      // 3️⃣ Send message only after successful join
      final msg =
          'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
      _socketService.sendMessage(msg, type: 'offer');
    } catch (e) {
      if (e.toString().contains('not a participant')) {
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
      } else {
        roomId = await createChatRoom(adId);
        final joined = await _socketService.joinRoomAndWait(roomId!);

        // Send message after successful join
        final msg =
            'I would like to make an offer of ₹${amount.toStringAsFixed(0)}';
        _socketService.sendMessage(msg, type: 'offer');
      }
    }
  }

  /// Check if a room exists for an ad using API
  Future<Map<String, dynamic>?> checkRoomExistsForAd(String adId) async {
    try {
      final response = await _apiService.checkRoomExists(
          adId, ''); // Empty otherUserId for legacy

      // The API response structure is: {success: true, data: {exists: true, roomId: "..."}}
      final data = response['data'] as Map<String, dynamic>?;
      final exists = data?['exists'] as bool? ?? false;
      final roomId = data?['roomId'] as String?;

      if (response['success'] == true && exists == true) {
        return {'exists': true, 'roomId': roomId, 'data': response};
      } else {
        return {'exists': false, 'roomId': null, 'data': response};
      }
    } catch (_) {
      return null;
    }
  }

  /// Check if a room exists for an ad and other user using API
  Future<Map<String, dynamic>?> checkRoomExistsForAdAndUser(
      String adId, String otherUserId) async {
    try {
      final response = await _apiService.checkRoomExists(adId, otherUserId);

      // The API response structure is: {success: true, data: {exists: true, roomId: "..."}}
      final data = response['data'] as Map<String, dynamic>?;
      final exists = data?['exists'] as bool? ?? false;
      final roomId = data?['roomId'] as String?;

      if (response['success'] == true && exists == true) {
        return {'exists': true, 'roomId': roomId, 'data': response};
      } else {
        return {'exists': false, 'roomId': null, 'data': response};
      }
    } catch (_) {
      return null;
    }
  }

  /// Find existing room by ad ID (legacy method - kept for compatibility)
  Future<String?> findRoomByAdId(String adId) async {
    try {

      // Ensure socket connected
      if (!_socketService.isConnected) await _socketService.connect();

      // Ask backend for user's chat rooms
      final rooms = await _socketService.getUserChatRooms();
      if (rooms == null || rooms.isEmpty) return null;

      // Find a room that matches adId
      for (final room in rooms) {
        final roomAdId = room['ad']?['id'] ?? room['adId'];
        if (roomAdId == adId) {
          return room['id'];
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if a chat room exists for an ad
  Future<String?> getExistingRoomForAd(String adId) async {
    try {

      // Get all chat rooms
      final response = await _apiService.getUserChatRooms();
      final rooms = response['data'] as List<dynamic>? ?? [];

      // Look for room with matching adId
      for (final room in rooms) {
        final roomData = room as Map<String, dynamic>;
        if (roomData['adId'] == adId) {
          return roomData['_id'] as String?;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a new chat room for an ad
  Future<String?> createChatRoom(String adId) async {
    try {

      // Ensure socket connected
      if (!_socketService.isConnected) {
        final connected = await _socketService.connect();
        if (!connected) throw Exception('Failed to connect socket');
      }

      final completer = Completer<String?>();
      StreamSubscription? subscription;

      // Listen once for room creation response
      subscription = _socketService.roomStream.listen((event) {
        if (event['type'] == 'roomCreated') {
          final roomId = event['data']?['data']?['roomId'];
          subscription?.cancel(); // Cancel subscription after first event
          completer.complete(roomId);
        }
      });

      // Emit room creation request
      _socketService.createChatRoom(adId);

      final result = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          subscription?.cancel(); // Cancel subscription on timeout
          return null;
        },
      );

      // Ensure subscription is canceled
      subscription.cancel();
      return result;
    } catch (e) {
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
    _socketErrorSubscription?.cancel();
    _socketRoomSubscription?.cancel();
    _socketErrorSubscription = null;
    _socketRoomSubscription = null;
    _initialized = false;
    if (!_errorController.isClosed) {
      _errorController.close();
    }
    if (!_roomsController.isClosed) {
      _roomsController.close();
    }
    _socketService.dispose();
  }
}
