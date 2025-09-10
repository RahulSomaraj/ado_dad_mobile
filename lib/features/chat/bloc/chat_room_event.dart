part of 'chat_room_bloc.dart';

@freezed
class ChatRoomEvent with _$ChatRoomEvent {
  const factory ChatRoomEvent.setChat(String chatId) = _SetChat;
  const factory ChatRoomEvent.loadMessages(String chatId) = _LoadMessages;
  const factory ChatRoomEvent.sendMessage(String chatId, String content) =
      _SendMessage;
  const factory ChatRoomEvent.markAsRead(String chatId) = _MarkAsRead;
  const factory ChatRoomEvent.newMessage(ChatMessage message) = _NewMessage;
  const factory ChatRoomEvent.clearChat() = _ClearChat;
}
