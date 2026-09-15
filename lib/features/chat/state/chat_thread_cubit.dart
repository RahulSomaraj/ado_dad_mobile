// Chat thread state (Phase 5 · M6, screens 06–12).
//
// One cubit per open thread (not a global bloc — F-18). Order on open:
//   cache → join room (ack) → fetch newest page → merge pending outbox.
// Joining before fetching closes the gap where a message could land between
// the history snapshot and the socket join (F-09); reconnects catch up with
// `after=<newest id>`.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/chat_models.dart';
import '../data/chat_repository.dart';

enum ChatThreadStatus { loading, loaded, error }

class ChatThreadState {
  const ChatThreadState({
    required this.roomId,
    this.status = ChatThreadStatus.loading,
    this.room,
    this.messages = const [],
    this.hasMore = false,
    this.olderCursor,
    this.loadingOlder = false,
    this.olderFailed = false,
    this.failure,
    this.connection = ChatConnectionStatus.connecting,
    this.myUserId,
  });

  final String roomId;
  final ChatThreadStatus status;
  final ChatRoom? room;

  /// Newest first — rendered by a reversed ListView.
  final List<ChatMessage> messages;
  final bool hasMore;
  final String? olderCursor;
  final bool loadingOlder;
  final bool olderFailed;
  final ChatFailure? failure;
  final ChatConnectionStatus connection;
  final String? myUserId;

  bool get isEmpty => status == ChatThreadStatus.loaded && messages.isEmpty;
  bool get isClosed =>
      room?.isClosed == true ||
      room?.ad?.availability == AdAvailability.unavailable;

  /// Newest message the server has stored (for catch-up and mark-read).
  String? get newestServerId {
    for (final m in messages) {
      if (m.id != null) return m.id;
    }
    return null;
  }

  ChatThreadState copyWith({
    ChatThreadStatus? status,
    ChatRoom? room,
    List<ChatMessage>? messages,
    bool? hasMore,
    String? olderCursor,
    bool clearOlderCursor = false,
    bool? loadingOlder,
    bool? olderFailed,
    ChatFailure? failure,
    bool clearFailure = false,
    ChatConnectionStatus? connection,
    String? myUserId,
  }) =>
      ChatThreadState(
        roomId: roomId,
        status: status ?? this.status,
        room: room ?? this.room,
        messages: messages ?? this.messages,
        hasMore: hasMore ?? this.hasMore,
        olderCursor:
            clearOlderCursor ? null : (olderCursor ?? this.olderCursor),
        loadingOlder: loadingOlder ?? this.loadingOlder,
        olderFailed: olderFailed ?? this.olderFailed,
        failure: clearFailure ? null : (failure ?? this.failure),
        connection: connection ?? this.connection,
        myUserId: myUserId ?? this.myUserId,
      );
}

class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit({
    required String roomId,
    ChatRoom? initialRoom,
    ChatRepository? repository,
  })  : _repo = repository ?? ChatRepository.instance,
        super(ChatThreadState(roomId: roomId, room: initialRoom));

  final ChatRepository _repo;
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _readDebounce;
  bool _visible = true;
  String? _lastMarkedReadId;

  String get roomId => state.roomId;

  Future<void> open() async {
    await _repo.start();
    if (isClosed) return;
    emit(state.copyWith(
        myUserId: _repo.userId, connection: _repo.currentStatus));

    _subs
      ..add(_repo.incomingMessages
          .where((m) => m.roomId == roomId)
          .listen(_onIncoming))
      ..add(_repo.outboxUpdates.listen(_onOutbox))
      ..add(_repo.readReceipts
          .where((r) => r.roomId == roomId)
          .listen(_onReadReceipt))
      ..add(_repo.roomUpdates
          .where((r) => r.roomId == roomId)
          .listen((r) => emit(state.copyWith(room: r))))
      ..add(_repo.connectionStatus
          .listen((s) => emit(state.copyWith(connection: s))))
      ..add(_repo.reconnected.listen((_) => _catchUp()));

    // 1) Cache + pending outbox: paint something immediately.
    final cached = await _repo.cachedMessages(roomId) ?? const <ChatMessage>[];
    if (isClosed) return;
    final seeded = mergeMessages(cached, _repo.pendingFor(roomId));
    if (seeded.isNotEmpty) {
      emit(state.copyWith(status: ChatThreadStatus.loaded, messages: seeded));
    }

    // 2) Room details if we arrived without them (deep link / push tap).
    if (state.room == null) unawaited(_fetchRoom());

    // 3) Join (bounded wait), then history.
    await _repo
        .joinRoom(roomId)
        .timeout(const Duration(seconds: 4), onTimeout: () => false);
    await _loadNewest();
  }

  Future<void> retryLoad() async {
    emit(state.copyWith(
        status:
            state.messages.isEmpty ? ChatThreadStatus.loading : state.status,
        clearFailure: true));
    await _repo
        .joinRoom(roomId)
        .timeout(const Duration(seconds: 4), onTimeout: () => false);
    await _loadNewest();
  }

  Future<void> loadOlder() async {
    final cursor = state.olderCursor;
    if (!state.hasMore || cursor == null || state.loadingOlder) return;
    emit(state.copyWith(loadingOlder: true, olderFailed: false));
    try {
      final page = await _repo.fetchMessages(roomId, cursor: cursor);
      if (isClosed) return;
      emit(state.copyWith(
        messages: mergeMessages(state.messages, page.messages),
        hasMore: page.hasMore,
        olderCursor: page.nextCursor,
        clearOlderCursor: page.nextCursor == null,
        loadingOlder: false,
      ));
    } on ChatFailure {
      if (!isClosed) {
        emit(state.copyWith(loadingOlder: false, olderFailed: true));
      }
    }
  }

  // ---- sending ---------------------------------------------------------------

  void sendText(String text) {
    if (text.trim().isEmpty || state.isClosed) return;
    _add(_repo.sendText(roomId, text));
  }

  void sendImage(Uint8List bytes, String mimeType,
      {int? width, int? height, String caption = ''}) {
    if (state.isClosed) return;
    _add(_repo.sendImage(roomId, bytes, mimeType,
        width: width, height: height, caption: caption));
  }

  void sendVoice(Uint8List bytes, String mimeType, int durationSec) {
    if (state.isClosed) return;
    _add(_repo.sendVoice(roomId, bytes, mimeType, durationSec));
  }

  Future<void> retry(ChatMessage m) async {
    final cid = m.clientMessageId;
    if (cid != null) await _repo.retry(cid);
  }

  void discard(ChatMessage m) {
    final cid = m.clientMessageId;
    if (cid == null) return;
    _repo.discard(cid);
    emit(state.copyWith(
        messages:
            state.messages.where((x) => x.clientMessageId != cid).toList()));
  }

  /// The page tells us whether it is on screen (app resumed / route covered).
  void setVisible(bool visible) {
    _visible = visible;
    if (visible) _scheduleMarkRead();
  }

  // ---- internals -----------------------------------------------------------------

  Future<void> _loadNewest() async {
    try {
      final page = await _repo.fetchMessages(roomId);
      if (isClosed) return;
      // Server page is authoritative for stored messages; keep pending ones.
      final merged = mergeMessages(page.messages, _repo.pendingFor(roomId));
      // Keep anything newer that arrived over the socket during the fetch.
      final live = state.messages.where(
          (m) => m.id != null && page.messages.every((p) => p.id != m.id));
      final withLive = mergeMessages(merged,
          live.where((m) => !m.createdAt.isBefore(_oldest(page.messages))));
      emit(state.copyWith(
        status: ChatThreadStatus.loaded,
        messages: withLive,
        hasMore: page.hasMore,
        olderCursor: page.nextCursor,
        clearOlderCursor: page.nextCursor == null,
        clearFailure: true,
      ));
      unawaited(_repo.saveThreadSnapshot(roomId, withLive));
      _scheduleMarkRead();
    } on ChatFailure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(
        status: state.messages.isEmpty
            ? ChatThreadStatus.error
            : ChatThreadStatus.loaded,
        failure: f,
      ));
    }
  }

  Future<void> _fetchRoom() async {
    try {
      final room = await _repo.getRoom(roomId);
      if (!isClosed) emit(state.copyWith(room: room));
    } on ChatFailure catch (f) {
      if (!isClosed && state.messages.isEmpty) {
        emit(state.copyWith(status: ChatThreadStatus.error, failure: f));
      }
    }
  }

  DateTime _oldest(List<ChatMessage> newestFirst) => newestFirst.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : newestFirst.last.createdAt;

  Future<void> _catchUp() async {
    final newest = state.newestServerId;
    if (newest == null) return _loadNewest();
    try {
      final newer = await _repo.fetchNewerThan(roomId, newest);
      if (isClosed || newer.isEmpty) return;
      emit(state.copyWith(messages: mergeMessages(state.messages, newer)));
      _scheduleMarkRead();
    } on ChatFailure {
      // Next reconnect or pull will try again.
    }
  }

  void _add(ChatMessage pending) {
    emit(state.copyWith(
        status: ChatThreadStatus.loaded,
        messages: mergeMessages(state.messages, [pending])));
  }

  void _onIncoming(ChatMessage m) {
    emit(state.copyWith(
        status: ChatThreadStatus.loaded,
        messages: mergeMessages(state.messages, [m])));
    if (!m.isMine(state.myUserId)) _scheduleMarkRead();
    unawaited(_repo.saveThreadSnapshot(roomId, state.messages));
  }

  void _onOutbox(ChatMessage m) {
    final cid = m.clientMessageId;
    if (m.failure?.code == 'DISCARDED' && cid != null) {
      emit(state.copyWith(
          messages:
              state.messages.where((x) => x.clientMessageId != cid).toList()));
      return;
    }
    if (m.roomId != roomId) return;
    emit(state.copyWith(messages: mergeMessages(state.messages, [m])));
  }

  void _onReadReceipt(ReadReceipt r) {
    final me = state.myUserId;
    if (r.userId == me) return;
    final updated = state.messages
        .map((m) => m.isMine(me) &&
                m.status == MessageStatus.sent &&
                !m.createdAt.isAfter(r.readAt)
            ? m.copyWith(status: MessageStatus.read)
            : m)
        .toList();
    emit(state.copyWith(messages: updated));
  }

  void _scheduleMarkRead() {
    if (!_visible) return;
    final newest = state.newestServerId;
    if (newest == null || newest == _lastMarkedReadId) return;
    final hasIncoming =
        state.messages.any((m) => m.id != null && !m.isMine(state.myUserId));
    final roomUnread = state.room?.unreadCount ?? 0;
    if (!hasIncoming && roomUnread == 0) return;
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 600), () {
      _lastMarkedReadId = newest;
      unawaited(_repo.markRead(roomId, lastMessageId: newest));
      final room = state.room;
      if (room != null && room.unreadCount > 0 && !isClosed) {
        emit(state.copyWith(room: room.copyWith(unreadCount: 0)));
      }
    });
  }

  @override
  Future<void> close() async {
    _readDebounce?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _repo.leaveRoom(roomId);
    await _repo.saveThreadSnapshot(roomId, state.messages);
    return super.close();
  }
}
