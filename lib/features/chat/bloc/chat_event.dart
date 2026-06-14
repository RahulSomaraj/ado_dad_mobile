abstract class ChatEvent {}

class InitializeChat extends ChatEvent {}

class LoadChatRooms extends ChatEvent {}

class JoinChatRoom extends ChatEvent {
  final String roomId;

  JoinChatRoom(this.roomId);
}

class LoadRoomMessages extends ChatEvent {
  final String roomId;

  LoadRoomMessages(this.roomId);
}

/// Mark a room's messages as read (clears its unread badge).
class MarkRoomRead extends ChatEvent {
  final String roomId;

  MarkRoomRead(this.roomId);
}

class ChatRoomsLoaded extends ChatEvent {
  final List<Map<String, dynamic>> rooms;

  ChatRoomsLoaded(this.rooms);
}

class ChatError extends ChatEvent {
  final String error;

  ChatError(this.error);
}

class NewMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;

  NewMessageReceived(this.message);
}

class SendMessage extends ChatEvent {
  final String content;
  final String type;
  /// Required when sending image/audio (for API call).
  final String? roomId;
  /// File bytes for image or audio attachment.
  final List<int>? fileBytes;
  final String? mimeType;
  /// 'image' or 'audio' when sending attachment.
  final String? attachmentType;

  SendMessage(this.content,
      {this.type = 'text',
      this.roomId,
      this.fileBytes,
      this.mimeType,
      this.attachmentType});
}

class CreateChatRoom extends ChatEvent {
  final String adId;
  CreateChatRoom(this.adId);
}

class SendOffer extends ChatEvent {
  final String adId;
  final double amount;
  final String adTitle;
  final String adPosterName;

  SendOffer({
    required this.adId,
    required this.amount,
    required this.adTitle,
    required this.adPosterName,
  });
}

class DisposeChat extends ChatEvent {}
