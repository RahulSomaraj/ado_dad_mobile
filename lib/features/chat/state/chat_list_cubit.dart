// Chat list state (Phase 5 · M6, screens 01–05).

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/chat_models.dart';
import '../data/chat_repository.dart';

enum ChatListStatus { loading, loaded, refreshing, loadingMore, error }

enum ChatListFilter { all, unread, buying, selling }

class ChatListState {
  const ChatListState({
    this.status = ChatListStatus.loading,
    this.rooms = const [],
    this.filter = ChatListFilter.all,
    this.query = '',
    this.nextCursor,
    this.failure,
    this.loadMoreFailed = false,
    this.connection = ChatConnectionStatus.connecting,
    this.showingCache = false,
    this.searchingRemote = false,
  });

  final ChatListStatus status;

  /// Everything loaded so far for the active server filter (sorted newest first).
  final List<ChatRoom> rooms;
  final ChatListFilter filter;
  final String query;
  final String? nextCursor;
  final ChatFailure? failure;
  final bool loadMoreFailed;
  final ChatConnectionStatus connection;

  /// True while the list on screen came from the device cache.
  final bool showingCache;
  final bool searchingRemote;

  bool get hasMore => nextCursor != null;

  /// Rooms after the chip filter and the search box — what the list renders.
  List<ChatRoom> get visibleRooms {
    final q = query.trim().toLowerCase();
    return rooms.where((r) {
      final passFilter = switch (filter) {
        ChatListFilter.all => true,
        ChatListFilter.unread => r.hasUnread,
        ChatListFilter.buying => r.myRole == ChatRole.buying,
        ChatListFilter.selling => r.myRole == ChatRole.selling,
      };
      if (!passFilter) return false;
      if (q.isEmpty) return true;
      return r.title.toLowerCase().contains(q) ||
          (r.ad?.title.toLowerCase().contains(q) ?? false) ||
          (r.lastMessage?.preview.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  int get unreadRooms => rooms.where((r) => r.hasUnread).length;

  ChatListState copyWith({
    ChatListStatus? status,
    List<ChatRoom>? rooms,
    ChatListFilter? filter,
    String? query,
    String? nextCursor,
    bool clearCursor = false,
    ChatFailure? failure,
    bool clearFailure = false,
    bool? loadMoreFailed,
    ChatConnectionStatus? connection,
    bool? showingCache,
    bool? searchingRemote,
  }) =>
      ChatListState(
        status: status ?? this.status,
        rooms: rooms ?? this.rooms,
        filter: filter ?? this.filter,
        query: query ?? this.query,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        failure: clearFailure ? null : (failure ?? this.failure),
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        connection: connection ?? this.connection,
        showingCache: showingCache ?? this.showingCache,
        searchingRemote: searchingRemote ?? this.searchingRemote,
      );
}

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit({ChatRepository? repository})
      : _repo = repository ?? ChatRepository.instance,
        super(const ChatListState());

  final ChatRepository _repo;
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _searchDebounce;
  int _requestSeq = 0;

  /// Cache first, then network. The socket never blocks this (F-10).
  Future<void> start() async {
    _subs.add(_repo.roomUpdates.listen(_upsert));
    _subs.add(_repo.connectionStatus
        .listen((s) => emit(state.copyWith(connection: s))));
    emit(state.copyWith(connection: _repo.currentStatus));

    final cached = await _repo.cachedRooms();
    if (isClosed) return;
    if (cached != null && cached.isNotEmpty) {
      emit(state.copyWith(
        status: ChatListStatus.refreshing,
        rooms: _sorted(cached),
        showingCache: true,
      ));
    }
    await _loadFirstPage();
  }

  /// Pull-to-refresh / Try again. Completes when the request finishes.
  Future<void> refresh() => _loadFirstPage();

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null ||
        state.status == ChatListStatus.loadingMore ||
        state.query.isNotEmpty) return;
    emit(state.copyWith(
        status: ChatListStatus.loadingMore, loadMoreFailed: false));
    final seq = _requestSeq;
    try {
      final page =
          await _repo.fetchRooms(filter: _serverFilter, cursor: cursor);
      if (isClosed || seq != _requestSeq) return;
      emit(state.copyWith(
        status: ChatListStatus.loaded,
        rooms: _sorted(_mergeRooms(state.rooms, page.rooms)),
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
      ));
    } on ChatFailure {
      if (isClosed) return;
      emit(state.copyWith(status: ChatListStatus.loaded, loadMoreFailed: true));
    }
  }

  /// Chip tap: instant local filter, then fetch that filter from the server so
  /// rooms beyond the loaded pages appear too.
  void setFilter(ChatListFilter filter) {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter));
    unawaited(_loadFirstPage(keepRooms: true));
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      emit(state.copyWith(searchingRemote: false));
      return;
    }
    _searchDebounce = Timer(
        const Duration(milliseconds: 300), () => _searchRemote(query.trim()));
  }

  void clearQuery() => setQuery('');

  /// Called when a thread is opened — clears the badge instantly.
  void markRoomReadLocally(String roomId) {
    final i = state.rooms.indexWhere((r) => r.roomId == roomId);
    if (i < 0 || !state.rooms[i].hasUnread) return;
    final next = List<ChatRoom>.of(state.rooms)
      ..[i] = state.rooms[i].copyWith(unreadCount: 0);
    emit(state.copyWith(rooms: next));
  }

  // ---------------------------------------------------------------------------

  String get _serverFilter => state.filter.name;

  Future<void> _loadFirstPage({bool keepRooms = false}) async {
    final seq = ++_requestSeq;
    final hasData = state.rooms.isNotEmpty;
    emit(state.copyWith(
      status: hasData ? ChatListStatus.refreshing : ChatListStatus.loading,
      clearFailure: true,
      loadMoreFailed: false,
    ));
    try {
      final page = await _repo
          .fetchRooms(filter: _serverFilter)
          .timeout(const Duration(seconds: 12));
      if (isClosed || seq != _requestSeq) return;
      final rooms =
          keepRooms ? _mergeRooms(state.rooms, page.rooms) : page.rooms;
      emit(state.copyWith(
        status: ChatListStatus.loaded,
        rooms: _sorted(rooms),
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        showingCache: false,
      ));
    } on ChatFailure catch (f) {
      if (isClosed || seq != _requestSeq) return;
      // With data on screen this becomes a banner; without, the error view.
      emit(state.copyWith(
          status: hasData ? ChatListStatus.loaded : ChatListStatus.error,
          failure: f));
    } on TimeoutException {
      if (isClosed || seq != _requestSeq) return;
      emit(state.copyWith(
        status: hasData ? ChatListStatus.loaded : ChatListStatus.error,
        failure: const ChatFailure(ChatFailureKind.timeout),
      ));
    }
  }

  Future<void> _searchRemote(String q) async {
    if (isClosed || state.query.trim() != q) return;
    emit(state.copyWith(searchingRemote: true));
    try {
      final page = await _repo.fetchRooms(query: q, limit: 50);
      if (isClosed || state.query.trim() != q) return;
      emit(state.copyWith(
          rooms: _sorted(_mergeRooms(state.rooms, page.rooms)),
          searchingRemote: false));
    } on ChatFailure {
      if (isClosed) return;
      emit(state.copyWith(searchingRemote: false));
    }
  }

  void _upsert(ChatRoom room) {
    emit(state.copyWith(rooms: _sorted(_mergeRooms(state.rooms, [room]))));
  }

  static List<ChatRoom> _mergeRooms(
      List<ChatRoom> current, List<ChatRoom> incoming) {
    final byId = {for (final r in current) r.roomId: r};
    for (final r in incoming) {
      byId[r.roomId] = r;
    }
    return byId.values.toList();
  }

  static List<ChatRoom> _sorted(List<ChatRoom> rooms) {
    final out = List<ChatRoom>.of(rooms);
    out.sort((a, b) {
      final at = a.sortTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.sortTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return out;
  }

  @override
  Future<void> close() async {
    _searchDebounce?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
