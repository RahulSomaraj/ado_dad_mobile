// Global unread badge for the nav bar (Phase 6).

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/chat_models.dart';
import '../data/chat_repository.dart';

class ChatBadgeCubit extends Cubit<int> {
  ChatBadgeCubit({ChatRepository? repository})
      : _repo = repository ?? ChatRepository.instance,
        super(0);

  final ChatRepository _repo;
  StreamSubscription<ChatRoom>? _sub;
  StreamSubscription<ChatMessage>? _msgSub;
  Timer? _debounce;

  /// Call after login / app start when a user is signed in.
  Future<void> start() async {
    _sub ??= _repo.roomUpdates.listen((_) => _scheduleRefresh());
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final total = await _repo.unreadTotal();
      if (!isClosed) emit(total);
    } on ChatFailure {
      // Keep the last known value.
    }
  }

  /// Optimistic decrement when a thread is opened.
  void clearRoom(int unreadInRoom) {
    if (unreadInRoom <= 0) return;
    emit((state - unreadInRoom).clamp(0, 1 << 30).toInt());
  }

  void reset() {
    _debounce?.cancel();
    emit(0);
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), refresh);
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _sub?.cancel();
    await _msgSub?.cancel();
    return super.close();
  }
}
