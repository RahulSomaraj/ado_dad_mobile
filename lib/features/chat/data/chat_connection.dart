// Realtime connection (Phase 5 · M3).
//
// One Socket.IO connection per signed-in session. Owns:
//  * token handling — on `auth_error {TOKEN_EXPIRED}` it refreshes through
//    AuthService and reconnects with the new token (a silent dead socket after
//    the 1 h access-token expiry was audit F-02);
//  * room membership — rooms joined by open threads are re-joined after every
//    reconnect;
//  * typed event streams for the repository.
//
// UI never touches this class directly (architecture rule 3).

import 'dart:async';

import 'package:ado_dad_user/common/shared_pref.dart';
import 'package:ado_dad_user/config/app_config.dart';
import 'package:ado_dad_user/services/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'chat_models.dart';

class ChatConnection {
  ChatConnection._();
  static final ChatConnection instance = ChatConnection._();

  io.Socket? _socket;
  bool _wanted = false;
  bool _refreshing = false;
  int _authRetries = 0;
  Timer? _reconnectingDelay;
  final Set<String> _rooms = {};

  final _status = StreamController<ChatConnectionStatus>.broadcast();
  final _messages = StreamController<ChatMessage>.broadcast();
  final _reads = StreamController<ReadReceipt>.broadcast();
  final _rooms$ = StreamController<ChatRoom>.broadcast();
  final _reconnected = StreamController<void>.broadcast();

  ChatConnectionStatus _current = ChatConnectionStatus.offline;

  ChatConnectionStatus get status => _current;
  Stream<ChatConnectionStatus> get statusStream => _status.stream;
  Stream<ChatMessage> get messages => _messages.stream;
  Stream<ReadReceipt> get readReceipts => _reads.stream;
  Stream<ChatRoom> get conversationUpdates => _rooms$.stream;

  /// Fires after a reconnect (not the first connect) — threads use it to catch up.
  Stream<void> get reconnected => _reconnected.stream;

  bool get isOnline => _current == ChatConnectionStatus.online;

  /// Idempotent. Call when chat UI (or the nav badge) needs realtime.
  Future<void> ensureConnected() async {
    _wanted = true;
    if (_socket != null) {
      if (_socket!.connected || _current == ChatConnectionStatus.connecting)
        return;
      _socket!.connect();
      return;
    }
    await _open();
  }

  /// Call on logout. Clears joined rooms.
  void disconnect() {
    _wanted = false;
    _rooms.clear();
    _teardown();
    _emit(ChatConnectionStatus.offline);
  }

  /// Join a room and remember it for reconnects. Resolves false on failure.
  Future<bool> joinRoom(String roomId) async {
    _rooms.add(roomId);
    await ensureConnected();
    final s = _socket;
    if (s == null || !s.connected) return false; // re-joined on connect
    final ack = await _emitWithAck('joinChatRoom', {'roomId': roomId});
    return ack?['success'] == true;
  }

  void leaveRoom(String roomId) {
    _rooms.remove(roomId);
    final s = _socket;
    if (s != null && s.connected) s.emit('leaveChatRoom', {'roomId': roomId});
  }

  // ---------------------------------------------------------------------------

  Future<void> _open() async {
    final token = (await getToken())?.replaceFirst(RegExp(r'^Bearer\s+'), '');
    if (token == null || token.isEmpty) {
      _emit(ChatConnectionStatus.authFailed);
      return;
    }
    _emit(ChatConnectionStatus.connecting);

    final socket = io.io(
      '${AppConfig.baseUrl}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(15000)
          .setTimeout(10000)
          .build(),
    );
    _socket = socket;
    var connectedOnce = false;

    socket.onConnect((_) {
      _authRetries = 0;
      _reconnectingDelay?.cancel();
      _emit(ChatConnectionStatus.online);
      for (final roomId in _rooms) {
        socket.emit('joinChatRoom', {'roomId': roomId});
      }
      if (connectedOnce) _reconnected.add(null);
      connectedOnce = true;
    });

    socket.onDisconnect((reason) {
      if (!_wanted) return;
      // Server-initiated disconnects (auth) are handled by `auth_error`.
      if (reason == 'io server disconnect') return;
      _markReconnecting();
    });

    socket.onConnectError((_) => _markReconnecting());

    socket.on('auth_error', (data) {
      final code = data is Map ? data['code']?.toString() : null;
      _handleAuthError(code);
    });

    socket.on('message', (data) {
      if (data is Map) {
        final m = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        if (m.roomId.isNotEmpty) _messages.add(m);
      }
    });

    socket.on('messages_read', (data) {
      if (data is! Map) return;
      final at = DateTime.tryParse('${data['lastReadAt']}')?.toLocal() ??
          DateTime.now();
      _reads.add(ReadReceipt('${data['roomId']}', '${data['userId']}', at));
    });

    socket.on('conversation_updated', (data) {
      if (data is Map) {
        final room = ChatRoom.fromJson(Map<String, dynamic>.from(data));
        if (room.roomId.isNotEmpty) _rooms$.add(room);
      }
    });

    socket.connect();
  }

  /// Show "Reconnecting…" only if the blip lasts > 3 s (wireframe 11).
  void _markReconnecting() {
    if (_current == ChatConnectionStatus.reconnecting ||
        _reconnectingDelay?.isActive == true) {
      return;
    }
    _reconnectingDelay = Timer(const Duration(seconds: 3), () {
      if (_socket?.connected != true && _wanted)
        _emit(ChatConnectionStatus.reconnecting);
    });
  }

  Future<void> _handleAuthError(String? code) async {
    if (code == 'SUSPENDED') {
      _wanted = false;
      _teardown();
      _emit(ChatConnectionStatus.suspended);
      return;
    }
    if (_refreshing) return;
    if (_authRetries >= 2) {
      _teardown();
      _emit(ChatConnectionStatus.authFailed);
      return;
    }
    _refreshing = true;
    _authRetries++;
    try {
      _teardown();
      _emit(ChatConnectionStatus.reconnecting);
      final fresh = await AuthService().refreshAccessToken();
      if (fresh == null || fresh.isEmpty) {
        // AuthService logs the user out when the refresh token is dead.
        _emit(ChatConnectionStatus.authFailed);
        return;
      }
      if (_wanted) await _open();
    } finally {
      _refreshing = false;
    }
  }

  void _teardown() {
    _reconnectingDelay?.cancel();
    final s = _socket;
    _socket = null;
    if (s != null) {
      s.clearListeners();
      s.disconnect();
      s.dispose();
    }
  }

  Future<Map<String, dynamic>?> _emitWithAck(
    String event,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 8),
  }) {
    final s = _socket;
    if (s == null || !s.connected) return Future.value(null);
    final completer = Completer<Map<String, dynamic>?>();
    s.emitWithAck(event, payload, ack: (data) {
      if (completer.isCompleted) return;
      completer.complete(data is Map ? Map<String, dynamic>.from(data) : null);
    });
    return completer.future.timeout(timeout, onTimeout: () => null);
  }

  void _emit(ChatConnectionStatus s) {
    if (_current == s) return;
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }
}
