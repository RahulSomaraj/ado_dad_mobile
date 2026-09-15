// Chat repository (Phase 5 · M5).
//
// The only thing presentation code talks to. Combines REST (ChatApi), realtime
// (ChatConnection) and the local cache, and owns the OUTBOX:
//  * every send gets a clientMessageId and is shown immediately as `sending`;
//  * delivery goes over REST (idempotent), so a retry can never duplicate;
//  * network failures stay `failed` and are retried automatically when the
//    connection comes back; policy failures wait for the user (Edit/Delete);
//  * each send carries its own roomId — there is no "current room" (F-04).

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:ado_dad_user/common/shared_pref.dart';

import 'chat_api.dart';
import 'chat_cache.dart';
import 'chat_connection.dart';
import 'chat_models.dart';

class _UploadJob {
  _UploadJob({
    required this.kind,
    required this.bytes,
    required this.mimeType,
    this.durationSec,
    this.width,
    this.height,
  });

  final String kind; // image | audio
  final Uint8List bytes;
  final String mimeType;
  final int? durationSec;
  final int? width;
  final int? height;
  ChatAttachment? uploaded;
}

class ChatRepository {
  ChatRepository({ChatApi? api, ChatConnection? connection, ChatCache? cache})
      : api = api ?? ChatApi(),
        connection = connection ?? ChatConnection.instance,
        cache = cache ?? ChatCache.instance;

  static final ChatRepository instance = ChatRepository();

  final ChatApi api;
  final ChatConnection connection;
  final ChatCache cache;

  final Map<String, ChatMessage> _outbox = {}; // clientMessageId → message
  final Map<String, _UploadJob> _uploads = {};
  final Set<String> _inFlight = {};
  final _outboxUpdates = StreamController<ChatMessage>.broadcast();
  StreamSubscription<ChatConnectionStatus>? _statusSub;
  String? _uid;
  Future<void>? _starting;

  // ---- streams ---------------------------------------------------------------

  Stream<ChatMessage> get incomingMessages => connection.messages;
  Stream<ChatRoom> get roomUpdates => connection.conversationUpdates;
  Stream<ReadReceipt> get readReceipts => connection.readReceipts;
  Stream<ChatConnectionStatus> get connectionStatus => connection.statusStream;
  ChatConnectionStatus get currentStatus => connection.status;
  Stream<void> get reconnected => connection.reconnected;

  /// Status/progress changes of messages I'm sending (optimistic → stored/failed).
  Stream<ChatMessage> get outboxUpdates => _outboxUpdates.stream;

  String? get userId => _uid;

  // ---- lifecycle ---------------------------------------------------------------

  /// Idempotent. Resolves the signed-in user, loads the outbox, connects.
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    _uid = await SharedPrefs().getUserId();
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      _starting = null;
      return;
    }
    for (final m in await cache.readOutbox(uid)) {
      if (m.clientMessageId != null) _outbox[m.clientMessageId!] = m;
    }
    _statusSub ??= connection.statusStream.listen((s) {
      if (s == ChatConnectionStatus.online) retryNetworkFailures();
    });
    unawaited(connection.ensureConnected());
  }

  /// Call on logout.
  Future<void> signOut() async {
    connection.disconnect();
    await _statusSub?.cancel();
    _statusSub = null;
    _outbox.clear();
    _uploads.clear();
    _inFlight.clear();
    _uid = null;
    _starting = null;
    await cache.clearAll();
  }

  // ---- rooms ---------------------------------------------------------------------

  Future<List<ChatRoom>?> cachedRooms() async {
    await start();
    final uid = _uid;
    return uid == null ? null : cache.readRooms(uid);
  }

  Future<ChatRoomPage> fetchRooms(
      {String filter = 'all',
      String? cursor,
      String? query,
      int limit = 20}) async {
    await start();
    final page = await api.listRooms(
        filter: filter, cursor: cursor, query: query, limit: limit);
    final uid = _uid;
    if (uid != null &&
        filter == 'all' &&
        cursor == null &&
        (query == null || query.isEmpty)) {
      unawaited(cache.writeRooms(uid, page.rooms));
    }
    return page;
  }

  Future<ChatRoom> getRoom(String roomId) async {
    await start();
    return api.getRoom(roomId);
  }

  /// Get-or-create the conversation for an ad (Chat / Make offer buttons).
  Future<ChatRoom> openChatForAd(String adId) async {
    await start();
    return api.createRoom(adId);
  }

  Future<int> unreadTotal() async {
    await start();
    return api.unreadTotal();
  }

  // ---- thread --------------------------------------------------------------------

  Future<bool> joinRoom(String roomId) => connection.joinRoom(roomId);

  void leaveRoom(String roomId) => connection.leaveRoom(roomId);

  Future<List<ChatMessage>?> cachedMessages(String roomId) async {
    await start();
    final uid = _uid;
    return uid == null ? null : cache.readMessages(uid, roomId);
  }

  Future<void> saveThreadSnapshot(
      String roomId, List<ChatMessage> newestFirst) async {
    final uid = _uid;
    if (uid != null) await cache.writeMessages(uid, roomId, newestFirst);
  }

  Future<ChatMessagePage> fetchMessages(String roomId,
      {String? cursor, int limit = 30}) async {
    await start();
    return api.getMessages(roomId, cursor: cursor, limit: limit);
  }

  /// Everything newer than [afterId] (newest first). Used after reconnects.
  Future<List<ChatMessage>> fetchNewerThan(
      String roomId, String afterId) async {
    final out = <ChatMessage>[];
    var cursor = afterId;
    for (var i = 0; i < 5; i++) {
      final page = await api.getMessagesAfter(roomId, cursor);
      if (page.messages.isEmpty) break;
      out.insertAll(0, page.messages);
      if (!page.hasMore) break;
      cursor = page.messages.first.id ?? cursor;
    }
    return out;
  }

  /// Best effort; the badge is also cleared optimistically by the caller.
  Future<void> markRead(String roomId, {String? lastMessageId}) async {
    try {
      await api.markRead(roomId, lastMessageId: lastMessageId);
    } catch (_) {}
  }

  /// Pending/failed messages for a room (newest first).
  List<ChatMessage> pendingFor(String roomId) {
    final list = _outbox.values.where((m) => m.roomId == roomId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ---- sending -------------------------------------------------------------------

  ChatMessage sendText(String roomId, String text) {
    final trimmed = text.trim();
    return _enqueue(roomId, MessageType.text, content: trimmed);
  }

  ChatMessage sendImage(String roomId, Uint8List bytes, String mimeType,
      {int? width, int? height, String caption = ''}) {
    final m = _enqueue(roomId, MessageType.image,
        content: caption.trim(), localBytes: bytes, defer: true);
    _uploads[m.clientMessageId!] = _UploadJob(
      kind: 'image',
      bytes: bytes,
      mimeType: mimeType,
      width: width,
      height: height,
    );
    unawaited(_deliver(m.clientMessageId!));
    return m;
  }

  ChatMessage sendVoice(
      String roomId, Uint8List bytes, String mimeType, int durationSec) {
    final m = _enqueue(roomId, MessageType.audio, defer: true);
    _uploads[m.clientMessageId!] = _UploadJob(
      kind: 'audio',
      bytes: bytes,
      mimeType: mimeType,
      durationSec:
          durationSec < 1 ? 1 : (durationSec > 180 ? 180 : durationSec),
    );
    unawaited(_deliver(m.clientMessageId!));
    return m;
  }

  /// User tapped Retry.
  Future<void> retry(String clientMessageId) async {
    final m = _outbox[clientMessageId];
    if (m == null) return;
    final isAttachment = m.type != MessageType.text;
    if (isAttachment && !_uploads.containsKey(clientMessageId)) {
      // The bytes were lost with an app restart — nothing to resend.
      _set(m.copyWith(
        status: MessageStatus.failed,
        failure:
            const ChatFailure(ChatFailureKind.invalid, code: 'ATTACHMENT_LOST'),
      ));
      return;
    }
    await _deliver(clientMessageId);
  }

  /// User deleted a failed message.
  void discard(String clientMessageId) {
    final m = _outbox.remove(clientMessageId);
    _uploads.remove(clientMessageId);
    _persistOutbox();
    if (m != null) {
      // Signal removal with a sentinel: same key, empty room id.
      _outboxUpdates.add(ChatMessage(
        clientMessageId: clientMessageId,
        roomId: '',
        senderId: m.senderId,
        type: m.type,
        createdAt: m.createdAt,
        status: MessageStatus.failed,
        failure: const ChatFailure(ChatFailureKind.unknown, code: 'DISCARDED'),
      ));
    }
  }

  void retryNetworkFailures() {
    for (final m in _outbox.values.toList()) {
      final f = m.failure;
      if (m.status == MessageStatus.failed && (f == null || f.isRetryable)) {
        unawaited(retry(m.clientMessageId!));
      }
    }
  }

  // ---- internals -----------------------------------------------------------------

  ChatMessage _enqueue(
    String roomId,
    MessageType type, {
    String content = '',
    Uint8List? localBytes,
    bool defer = false,
  }) {
    final cid = newClientMessageId();
    final m = ChatMessage(
      clientMessageId: cid,
      roomId: roomId,
      senderId: _uid ?? '',
      type: type,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      localBytes: localBytes,
      uploadProgress: localBytes != null ? 0 : null,
    );
    _set(m);
    if (!defer) unawaited(_deliver(cid));
    return m;
  }

  Future<void> _deliver(String cid) async {
    if (_inFlight.contains(cid)) return;
    final current = _outbox[cid];
    if (current == null) return;
    _inFlight.add(cid);
    _set(current.copyWith(status: MessageStatus.sending, clearFailure: true));
    try {
      await start();
      var attachments = current.attachments;
      final job = _uploads[cid];
      if (job != null) {
        if (job.uploaded == null) {
          final ticket = await api.createUpload(
            current.roomId,
            kind: job.kind,
            mimeType: job.mimeType,
            size: job.bytes.length,
          );
          await api.upload(ticket, job.bytes, onProgress: (p) {
            final latest = _outbox[cid];
            if (latest != null) {
              _set(latest.copyWith(uploadProgress: p), persist: false);
            }
          });
          job.uploaded = ChatAttachment(
            type: job.kind,
            url: ticket.url,
            mimeType: ticket.headers['Content-Type'] ?? job.mimeType,
            size: job.bytes.length,
            durationSec: job.durationSec,
            width: job.width,
            height: job.height,
          );
        }
        attachments = [job.uploaded!];
      }

      final stored = await api.sendMessage(
        current.roomId,
        clientMessageId: cid,
        type: current.type,
        content: current.content.isEmpty ? null : current.content,
        attachments: attachments,
      );
      final local = _outbox.remove(cid);
      _uploads.remove(cid);
      _persistOutbox();
      _outboxUpdates.add(stored.copyWith(localBytes: local?.localBytes));
    } on ChatFailure catch (failure) {
      final latest = _outbox[cid];
      if (latest != null) {
        _set(latest.copyWith(
            status: MessageStatus.failed,
            failure: failure,
            clearProgress: true));
      }
    } catch (_) {
      final latest = _outbox[cid];
      if (latest != null) {
        _set(latest.copyWith(
          status: MessageStatus.failed,
          failure: const ChatFailure(ChatFailureKind.unknown),
          clearProgress: true,
        ));
      }
    } finally {
      _inFlight.remove(cid);
    }
  }

  void _set(ChatMessage m, {bool persist = true}) {
    _outbox[m.clientMessageId!] = m;
    if (persist) _persistOutbox();
    if (!_outboxUpdates.isClosed) _outboxUpdates.add(m);
  }

  void _persistOutbox() {
    final uid = _uid;
    if (uid == null) return;
    unawaited(cache.writeOutbox(uid, _outbox.values.toList()));
  }
}

final _rng = Random.secure();

/// 22-char url-safe id (matches the server's `^[A-Za-z0-9_-]{8,64}$`).
String newClientMessageId() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
