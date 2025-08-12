part of 'chat_bloc.dart';

@freezed
class ChatState with _$ChatState {
  // const factory ChatState.initial() = _Initial;
  const factory ChatState({
    @Default([]) List<Map<String, dynamic>> chats, // Chat list
    @Default([]) List<Map<String, String>> messages, // Messages in chat detail
  }) = ChatBlocState;
  factory ChatState.initial() => ChatBlocState();
}
