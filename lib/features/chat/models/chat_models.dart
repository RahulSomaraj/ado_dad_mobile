import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_models.freezed.dart';
part 'chat_models.g.dart';

/// Chat message model
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String threadId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    required String messageType, // 'text', 'image', 'file', etc.
    required DateTime timestamp,
    required bool isRead,
    required bool isDelivered,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? attachments,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

/// Extension to convert ApiMessage to ChatMessage
extension ApiMessageToChatMessage on ApiMessage {
  ChatMessage toChatMessage() {
    return ChatMessage(
      id: id,
      threadId: roomId,
      senderId: senderId,
      senderName: sender.name,
      senderAvatar: sender.profilePic,
      content: content,
      messageType: type,
      timestamp: createdAt,
      isRead: isRead,
      isDelivered: true, // Assume delivered if it's from API
      attachments: attachments.cast<String>(),
    );
  }
}

/// Chat thread model
@freezed
class ChatThread with _$ChatThread {
  const factory ChatThread({
    required String id,
    required String name,
    String? avatarUrl,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String>? participantAvatars,
    ChatMessage? lastMessage,
    required int unreadCount,
    required DateTime lastActivity,
    required bool isActive,
    String? threadType, // 'direct', 'group', etc.
    Map<String, dynamic>? metadata,
    // New fields from API response
    String? roomId,
    String? initiatorId,
    String? adId,
    String? adPosterId,
    List<String>? participants,
    String? status,
    DateTime? lastMessageAt,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    OtherUser? otherUser,
    LatestMessage? latestMessage,
    AdDetails? adDetails,
  }) = _ChatThread;

  factory ChatThread.fromJson(Map<String, dynamic> json) =>
      _$ChatThreadFromJson(json);
}

/// Other user model from API response
@freezed
class OtherUser with _$OtherUser {
  const factory OtherUser({
    required String id,
    required String name,
    String? profilePic,
    String? email,
  }) = _OtherUser;

  factory OtherUser.fromJson(Map<String, dynamic> json) =>
      _$OtherUserFromJson(json);
}

/// Latest message model from API response
@freezed
class LatestMessage with _$LatestMessage {
  const factory LatestMessage({
    required String content,
    required String type,
    required DateTime createdAt,
  }) = _LatestMessage;

  factory LatestMessage.fromJson(Map<String, dynamic> json) =>
      _$LatestMessageFromJson(json);
}

/// Ad details model from API response
@freezed
class AdDetails with _$AdDetails {
  const factory AdDetails({
    required String id,
    required String title,
    required String description,
    required int price,
    required List<String> images,
    required String category,
  }) = _AdDetails;

  factory AdDetails.fromJson(Map<String, dynamic> json) =>
      _$AdDetailsFromJson(json);
}

/// Socket event model for chat events
@freezed
class ChatSocketEvent with _$ChatSocketEvent {
  const factory ChatSocketEvent({
    required String type,
    required Map<String, dynamic> data,
    DateTime? timestamp,
  }) = _ChatSocketEvent;

  factory ChatSocketEvent.fromJson(Map<String, dynamic> json) =>
      _$ChatSocketEventFromJson(json);
}

/// Typing indicator model
@freezed
class TypingIndicator with _$TypingIndicator {
  const factory TypingIndicator({
    required String threadId,
    required String userId,
    required String userName,
    required bool isTyping,
    DateTime? timestamp,
  }) = _TypingIndicator;

  factory TypingIndicator.fromJson(Map<String, dynamic> json) =>
      _$TypingIndicatorFromJson(json);
}

/// Message status model
@freezed
class MessageStatus with _$MessageStatus {
  const factory MessageStatus({
    required String messageId,
    required String status, // 'sent', 'delivered', 'read'
    required DateTime timestamp,
    String? userId,
  }) = _MessageStatus;

  factory MessageStatus.fromJson(Map<String, dynamic> json) =>
      _$MessageStatusFromJson(json);
}

/// Chat participant model
@freezed
class ChatParticipant with _$ChatParticipant {
  const factory ChatParticipant({
    required String id,
    required String name,
    String? avatarUrl,
    required bool isOnline,
    DateTime? lastSeen,
    String? status,
  }) = _ChatParticipant;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) =>
      _$ChatParticipantFromJson(json);
}

/// Socket connection state
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// API Message model for chat messages from the server
@freezed
class ApiMessage with _$ApiMessage {
  const factory ApiMessage({
    @JsonKey(name: '_id') required String id,
    required String roomId,
    required String senderId,
    required String type,
    required String content,
    @Default([]) List<dynamic> attachments,
    required bool isRead,
    required DateTime createdAt,
    required DateTime updatedAt,
    required ApiMessageSender sender,
  }) = _ApiMessage;

  factory ApiMessage.fromJson(Map<String, dynamic> json) =>
      _$ApiMessageFromJson(json);
}

/// API Message sender model
@freezed
class ApiMessageSender with _$ApiMessageSender {
  const factory ApiMessageSender({
    @JsonKey(name: '_id') required String id,
    required String name,
    required String email,
    String? profilePic,
  }) = _ApiMessageSender;

  factory ApiMessageSender.fromJson(Map<String, dynamic> json) =>
      _$ApiMessageSenderFromJson(json);
}

/// API Response model for chat messages
@freezed
class ChatMessagesResponse with _$ChatMessagesResponse {
  const factory ChatMessagesResponse({
    required bool success,
    required ChatMessagesData data,
    required String roomId,
  }) = _ChatMessagesResponse;

  factory ChatMessagesResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatMessagesResponseFromJson(json);
}

/// Chat messages data model
@freezed
class ChatMessagesData with _$ChatMessagesData {
  const factory ChatMessagesData({
    required List<ApiMessage> messages,
    String? nextCursor,
    required bool hasMore,
    required int total,
  }) = _ChatMessagesData;

  factory ChatMessagesData.fromJson(Map<String, dynamic> json) =>
      _$ChatMessagesDataFromJson(json);
}

/// Chat message types
enum ChatMessageType {
  text,
  image,
  file,
  audio,
  video,
  location,
  contact,
  system,
}

/// Chat thread types
enum ChatThreadType {
  direct,
  group,
  channel,
}

/// Chat summary model for test compatibility
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

/// Chat model for test compatibility
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

/// Extension methods for enums
extension ChatMessageTypeExtension on ChatMessageType {
  String get value {
    switch (this) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.image:
        return 'image';
      case ChatMessageType.file:
        return 'file';
      case ChatMessageType.audio:
        return 'audio';
      case ChatMessageType.video:
        return 'video';
      case ChatMessageType.location:
        return 'location';
      case ChatMessageType.contact:
        return 'contact';
      case ChatMessageType.system:
        return 'system';
    }
  }

  static ChatMessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return ChatMessageType.text;
      case 'image':
        return ChatMessageType.image;
      case 'file':
        return ChatMessageType.file;
      case 'audio':
        return ChatMessageType.audio;
      case 'video':
        return ChatMessageType.video;
      case 'location':
        return ChatMessageType.location;
      case 'contact':
        return ChatMessageType.contact;
      case 'system':
        return ChatMessageType.system;
      default:
        return ChatMessageType.text;
    }
  }
}

extension ChatThreadTypeExtension on ChatThreadType {
  String get value {
    switch (this) {
      case ChatThreadType.direct:
        return 'direct';
      case ChatThreadType.group:
        return 'group';
      case ChatThreadType.channel:
        return 'channel';
    }
  }

  static ChatThreadType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'direct':
        return ChatThreadType.direct;
      case 'group':
        return ChatThreadType.group;
      case 'channel':
        return ChatThreadType.channel;
      default:
        return ChatThreadType.direct;
    }
  }
}
