part of 'chat_bloc.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState.initial() = _Initial;
  const factory ChatState.loading() = _Loading;
  const factory ChatState.loaded({required List<ChatSummary> chats}) = _Loaded;
  const factory ChatState.error({required String message}) = ChatStateError;
}
