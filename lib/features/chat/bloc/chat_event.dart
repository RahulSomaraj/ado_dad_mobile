part of 'chat_bloc.dart';

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.initialize() = _Initialize;
  const factory ChatEvent.loadChats() = _LoadChats;
  const factory ChatEvent.refreshChats() = _RefreshChats;
  const factory ChatEvent.connect() = _Connect;
  const factory ChatEvent.disconnect() = _Disconnect;
  const factory ChatEvent.newMessage(ChatMessage message) = _NewMessage;
  const factory ChatEvent.newChat(Map<String, dynamic> chatData) = _NewChat;
  const factory ChatEvent.createAdChat(String adId) = _CreateAdChat;
  const factory ChatEvent.joinChat(String chatId) = _JoinChat;
  const factory ChatEvent.sendMessage(String chatId, String content) =
      _SendMessage;
  const factory ChatEvent.markAsRead(String chatId) = _MarkAsRead;
  const factory ChatEvent.error(String message) = _Error;
}
