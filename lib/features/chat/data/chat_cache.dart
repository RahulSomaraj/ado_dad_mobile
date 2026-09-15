// Small persistent cache (Phase 5 · M4).
//
// Enough to paint the chat list and the last screen of a thread instantly on
// open, then refresh from the server. SharedPreferences + JSON: no new package.
//
// Keys are scoped by user id so a different login never sees another user's
// chats; `clearAll()` is called on logout.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'chat_models.dart';

class ChatCache {
  ChatCache._();
  static final ChatCache instance = ChatCache._();

  static const _prefix = 'chat.v1.';
  static const ttl = Duration(hours: 24);
  static const maxMessagesPerRoom = 30;
  static const maxRoomsWithMessages = 20;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _roomsKey(String uid) => '${_prefix}rooms.$uid';
  String _msgsKey(String uid, String roomId) => '${_prefix}msgs.$uid.$roomId';
  String _outboxKey(String uid) => '${_prefix}outbox.$uid';
  String _msgIndexKey(String uid) => '${_prefix}msgindex.$uid';

  // ---- rooms (first page of "All") -----------------------------------------

  Future<List<ChatRoom>?> readRooms(String uid) async {
    final raw = (await _p).getString(_roomsKey(uid));
    final decoded = _decodeFresh(raw);
    if (decoded == null) return null;
    return (decoded as List)
        .whereType<Map>()
        .map((r) => ChatRoom.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<void> writeRooms(String uid, List<ChatRoom> rooms) async {
    await (await _p).setString(
      _roomsKey(uid),
      _encode(rooms.take(50).map((r) => r.toJson()).toList()),
    );
  }

  // ---- messages (last N per room, LRU over rooms) --------------------------

  Future<List<ChatMessage>?> readMessages(String uid, String roomId) async {
    final raw = (await _p).getString(_msgsKey(uid, roomId));
    final decoded = _decodeFresh(raw);
    if (decoded == null) return null;
    return (decoded as List)
        .whereType<Map>()
        .map((m) => ChatMessage.fromCacheJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// [messages] newest-first. Pending messages are excluded (the outbox owns them).
  Future<void> writeMessages(
      String uid, String roomId, List<ChatMessage> messages) async {
    final prefs = await _p;
    final stored = messages
        .where((m) => m.id != null)
        .take(maxMessagesPerRoom)
        .map((m) => m.toJson())
        .toList();
    await prefs.setString(_msgsKey(uid, roomId), _encode(stored));

    final index = prefs.getStringList(_msgIndexKey(uid)) ?? <String>[];
    index
      ..remove(roomId)
      ..insert(0, roomId);
    while (index.length > maxRoomsWithMessages) {
      await prefs.remove(_msgsKey(uid, index.removeLast()));
    }
    await prefs.setStringList(_msgIndexKey(uid), index);
  }

  // ---- outbox (unsent / failed messages survive restarts) ------------------

  Future<List<ChatMessage>> readOutbox(String uid) async {
    final raw = (await _p).getString(_outboxKey(uid));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => ChatMessage.fromCacheJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeOutbox(String uid, List<ChatMessage> pending) async {
    final prefs = await _p;
    if (pending.isEmpty) {
      await prefs.remove(_outboxKey(uid));
      return;
    }
    // Attachments that never finished uploading have no URL to resend — keep text only.
    final keep = pending
        .where((m) => m.type == MessageType.text)
        .map((m) => m.toJson())
        .toList();
    await prefs.setString(_outboxKey(uid), jsonEncode(keep));
  }

  // ---- housekeeping ----------------------------------------------------------

  Future<void> clearAll() async {
    final prefs = await _p;
    for (final key
        in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await prefs.remove(key);
    }
  }

  String _encode(Object value) =>
      jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'v': value});

  dynamic _decodeFresh(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final at =
          DateTime.fromMillisecondsSinceEpoch((map['at'] as num).toInt());
      if (DateTime.now().difference(at) > ttl) return null;
      return map['v'];
    } catch (_) {
      return null;
    }
  }
}
