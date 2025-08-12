import 'package:ado_dad_user/repositories/socket_service.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_event.dart';
part 'chat_state.dart';
part 'chat_bloc.freezed.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SocketService socketService;
  ChatBloc({required this.socketService}) : super(ChatBlocState()) {
    // Listen to incoming messages
    socketService.listenToMessages((data) {
      add(ChatEvent.receiveMessage(data['username'], data['message']));
    });

    socketService.listenToChatList((data) {
      // ✅ FIX: Convert List<dynamic> to List<Map<String, dynamic>>
      add(ChatEvent.updateChatList(List<Map<String, dynamic>>.from(data)));
    });

    on<FetchChatList>((event, emit) {});

    on<UpdateChatList>((event, emit) {
      emit(state.copyWith(chats: event.chats));
    });

    on<SendMessage>((event, emit) {
      socketService.sendMessage(event.username, event.message);
      emit(state.copyWith(messages: [
        ...state.messages,
        {'username': event.username, 'message': event.message}
      ]));
    });

    on<ReceiveMessage>((event, emit) {
      emit(state.copyWith(messages: [
        ...state.messages,
        {'username': event.username, 'message': event.message}
      ]));

      // Update chat list with new message
      final updatedChats = state.chats.map((chat) {
        if (chat["username"] == event.username) {
          return {
            ...chat,
            "message": event.message,
            "time": "Just now",
            "unread": (chat["unread"] as int) + 1,
          };
        }
        return chat;
      }).toList();

      emit(state.copyWith(chats: updatedChats));
    });

    on<MarkChatAsRead>((event, emit) {
      socketService.markChatAsRead(event.username);
      final updatedChats = state.chats.map((chat) {
        if (chat["username"] == event.username) {
          return {...chat, "unread": 0};
        }
        return chat;
      }).toList();
      emit(state.copyWith(chats: updatedChats));
    });
  }
}
