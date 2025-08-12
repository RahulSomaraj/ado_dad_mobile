part of 'chat_bloc.dart';

@freezed
class ChatEvent with _$ChatEvent {
  // const factory ChatEvent.started() = _Started;
  const factory ChatEvent.fetchChatList() = FetchChatList;

  const factory ChatEvent.updateChatList(List<Map<String, dynamic>> chats) =
      UpdateChatList;

  const factory ChatEvent.sendMessage(String username, String message) =
      SendMessage;

  const factory ChatEvent.receiveMessage(String username, String message) =
      ReceiveMessage;

  const factory ChatEvent.markChatAsRead(String username) = MarkChatAsRead;
}
