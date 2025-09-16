import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default(SocketConnectionState.disconnected)
    SocketConnectionState connectionState,
    @Default(false) bool isConnected,
    String? socketId,
    String? error,

    // Threads
    @Default([]) List<ChatThread> threads,
    @Default([]) List<ChatThread> chatRooms,
    @Default({}) Map<String, List<ChatMessage>> messages,
    String? selectedThreadId,
    @Default(false) bool isLoadingThreads,
    @Default(false) bool isLoadingChatRooms,

    // Current thread
    ChatThread? currentThread,
    @Default(false) bool isLoadingMessages,
    @Default({}) Map<String, TypingIndicator> typingUsers,

    // UI state
    @Default(false) bool isSendingMessage,
    @Default(false) bool isTyping,

    // Offer state
    @Default(false) bool isSendingOffer,
    String? lastOfferRoomId,
  }) = _ChatState;
}

/// Extension methods for ChatState
extension ChatStateExtension on ChatState {
  /// Get messages for the current thread
  List<ChatMessage> get currentThreadMessages {
    if (selectedThreadId == null) return [];
    return messages[selectedThreadId] ?? [];
  }

  /// Get unread count for all threads
  int get totalUnreadCount {
    return threads.fold(0, (sum, thread) => sum + thread.unreadCount);
  }

  /// Check if a specific user is typing in the current thread
  bool isUserTyping(String userId) {
    if (selectedThreadId == null) return false;
    final typing = typingUsers[selectedThreadId];
    return typing?.userId == userId && typing?.isTyping == true;
  }

  /// Get typing users for the current thread
  List<TypingIndicator> get currentThreadTypingUsers {
    if (selectedThreadId == null) return [];
    final typing = typingUsers[selectedThreadId];
    return typing != null ? [typing] : [];
  }
}
