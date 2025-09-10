part of 'chat_room_bloc.dart';

@freezed
class ChatRoomState with _$ChatRoomState {
  const factory ChatRoomState.initial() = _Initial;
  const factory ChatRoomState.loading({required String chatId}) = _Loading;
  const factory ChatRoomState.loaded({
    required String chatId,
    required List<ChatMessage> messages,
    required bool loading,
  }) = _Loaded;
  const factory ChatRoomState.error({
    required String chatId,
    required String message,
  }) = _Error;
}
