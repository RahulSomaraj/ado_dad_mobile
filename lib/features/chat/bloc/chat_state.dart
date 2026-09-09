abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatRoomsSuccess extends ChatState {
  final List<Map<String, dynamic>> rooms;

  ChatRoomsSuccess(this.rooms);
}

class ChatRoomJoined extends ChatState {
  final String roomId;
  final String message;

  ChatRoomJoined(this.roomId, this.message);
}

class ChatRoomCreated extends ChatState {
  final String roomId;

  ChatRoomCreated(this.roomId);
}

class MessagesLoaded extends ChatState {
  final String roomId;
  final List<Map<String, dynamic>> messages;

  MessagesLoaded(this.roomId, this.messages);
}

class NewMessageReceivedState extends ChatState {
  final Map<String, dynamic> message;

  /// Room the message belongs to (when the payload carries one), so pages can
  /// ignore messages meant for other rooms.
  final String? roomId;

  NewMessageReceivedState(this.message, {this.roomId});
}

class ChatErrorState extends ChatState {
  final String error;

  ChatErrorState(this.error);
}
