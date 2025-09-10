import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_models.freezed.dart';
part 'chat_models.g.dart';

@freezed
class ChatSummary with _$ChatSummary {
  const factory ChatSummary({
    required String id,
    String? lastMessage,
    DateTime? updatedAt,
  }) = _ChatSummary;

  factory ChatSummary.fromJson(Map<String, dynamic> json) =>
      _$ChatSummaryFromJson(json);
}

@freezed
class Chat with _$Chat {
  const factory Chat({
    required String id,
    required List<String> participants,
    required String contextType,
    required String contextId,
    String? postId,
  }) = _Chat;

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String chat,
    required String sender,
    required String content,
    required DateTime createdAt,
    required bool read,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
