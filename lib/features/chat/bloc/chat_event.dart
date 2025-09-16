import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';

part 'chat_event.freezed.dart';

@freezed
class ChatEvent with _$ChatEvent {
  // Connection events
  const factory ChatEvent.connect() = ConnectToChat;
  const factory ChatEvent.disconnect() = DisconnectFromChat;
  const factory ChatEvent.reconnect() = ReconnectToChat;

  // Thread events
  const factory ChatEvent.joinThread(String threadId) = JoinThread;
  const factory ChatEvent.leaveThread(String threadId) = LeaveThread;
  const factory ChatEvent.loadThreads() = LoadThreads;
  const factory ChatEvent.selectThread(String threadId) = SelectThread;

  // Message events
  const factory ChatEvent.sendMessage({
    required String threadId,
    required String content,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) = SendMessage;

  const factory ChatEvent.loadMessages(String threadId) = LoadMessages;
  const factory ChatEvent.messagesReceived(
      String threadId, List<Map<String, dynamic>> messages) = MessagesReceived;
  const factory ChatEvent.markMessageAsRead(String messageId) =
      MarkMessageAsRead;
  const factory ChatEvent.deleteMessage(String messageId) = DeleteMessage;

  // Typing events
  const factory ChatEvent.startTyping(String threadId) = StartTyping;
  const factory ChatEvent.stopTyping(String threadId) = StopTyping;

  // Offer events
  const factory ChatEvent.sendOffer({
    required String adId,
    required String amount,
    String? adTitle,
    String? adPosterName,
  }) = SendOffer;

  const factory ChatEvent.getUserChatRooms() = GetUserChatRooms;
  const factory ChatEvent.chatRoomsReceived(Map<String, dynamic> response) =
      ChatRoomsReceived;

  // Socket events (internal)
  const factory ChatEvent.socketConnected() = SocketConnected;
  const factory ChatEvent.socketDisconnected() = SocketDisconnected;
  const factory ChatEvent.socketError(String error) = SocketError;
  const factory ChatEvent.newMessageReceived(ChatMessage message) =
      NewMessageReceived;
  const factory ChatEvent.messageSent(ChatMessage message) = MessageSent;
  const factory ChatEvent.typingReceived(TypingIndicator typing) =
      TypingReceived;
  const factory ChatEvent.stopTypingReceived(TypingIndicator typing) =
      StopTypingReceived;
}
