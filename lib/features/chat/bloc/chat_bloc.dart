import 'dart:async';
import 'package:ado_dad_user/features/chat/auth/auth_provider.dart';
import 'package:ado_dad_user/features/chat/data/chat_repository.dart';
import 'package:ado_dad_user/features/chat/data/chat_socket_service.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_event.dart';
part 'chat_state.dart';
part 'chat_bloc.freezed.dart';

/// Main chat BLoC for managing chat list and operations
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final ChatAuthProvider _authProvider;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _newChatSubscription;

  ChatBloc({
    required ChatRepository chatRepository,
    required ChatAuthProvider authProvider,
  })  : _chatRepository = chatRepository,
        _authProvider = authProvider,
        super(const ChatState.initial()) {
    on<ChatEvent>((event, emit) async {
      event.map(
        initialize: (e) => _onInitialize(e, emit),
        loadChats: (e) => _onLoadChats(e, emit),
        refreshChats: (e) => _onRefreshChats(e, emit),
        connect: (e) => _onConnect(e, emit),
        disconnect: (e) => _onDisconnect(e, emit),
        newMessage: (e) => _onNewMessage(e, emit),
        newChat: (e) => _onNewChat(e, emit),
        createAdChat: (e) => _onCreateAdChat(e, emit),
        joinChat: (e) => _onJoinChat(e, emit),
        sendMessage: (e) => _onSendMessage(e, emit),
        markAsRead: (e) => _onMarkAsRead(e, emit),
        error: (_Error value) {},
      );
    });
  }

  Future<void> _onInitialize(_Initialize event, Emitter<ChatState> emit) async {
    emit(const ChatState.loading());

    try {
      // Connect to chat service
      await _chatRepository.connect();

      // Setup message subscriptions
      _setupMessageSubscriptions();

      // Load initial chats
      await _onLoadChats(_LoadChats(), emit);
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onLoadChats(_LoadChats event, Emitter<ChatState> emit) async {
    if (state == const ChatState.loading()) {
      return; // Prevent multiple simultaneous loads
    }

    emit(const ChatState.loading());

    try {
      final chats = await _chatRepository.getUserChats();
      emit(ChatState.loaded(chats: chats));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onRefreshChats(
      _RefreshChats event, Emitter<ChatState> emit) async {
    try {
      final chats = await _chatRepository.getUserChats();
      emit(ChatState.loaded(chats: chats));
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onConnect(_Connect event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.connect();
      _setupMessageSubscriptions();
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onDisconnect(_Disconnect event, Emitter<ChatState> emit) async {
    _messageSubscription?.cancel();
    _newChatSubscription?.cancel();
    _chatRepository.disconnect();
  }

  void _onNewMessage(_NewMessage event, Emitter<ChatState> emit) {
    // Update chat list with new message
    state.maybeWhen(
      loaded: (chats) {
        final updatedChats = chats.map((chat) {
          if (chat.id == event.message.chat) {
            return chat.copyWith(
              lastMessage: event.message.content,
              updatedAt: event.message.createdAt,
            );
          }
          return chat;
        }).toList();

        // Sort by most recent
        updatedChats.sort((a, b) => (b.updatedAt ?? DateTime(1900))
            .compareTo(a.updatedAt ?? DateTime(1900)));

        emit(ChatState.loaded(chats: updatedChats));
      },
      orElse: () {},
    );
  }

  void _onNewChat(_NewChat event, Emitter<ChatState> emit) {
    // Handle new chat creation
    // This would typically add the new chat to the list
    // Implementation depends on the server response structure
  }

  Future<void> _onCreateAdChat(
      _CreateAdChat event, Emitter<ChatState> emit) async {
    try {
      final newChat = await _chatRepository.createAdChat(event.adId);

      // Add new chat to the list
      state.maybeWhen(
        loaded: (chats) {
          final updatedChats = [
            ...chats,
            ChatSummary(
              id: newChat.id,
              lastMessage: null,
              updatedAt: DateTime.now(),
            )
          ];
          emit(ChatState.loaded(chats: updatedChats));
        },
        orElse: () {},
      );
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onJoinChat(_JoinChat event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.joinChat(event.chatId);
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onSendMessage(
      _SendMessage event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.sendMessage(event.chatId, event.content);
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(_MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.markAsRead(event.chatId);
    } catch (e) {
      emit(ChatState.error(message: e.toString()));
    }
  }

  void _setupMessageSubscriptions() {
    _messageSubscription?.cancel();
    _newChatSubscription?.cancel();

    _messageSubscription = _chatRepository.messages.listen(
      (message) => add(ChatEvent.newMessage(message)),
      onError: (error) => add(ChatEvent.error(error.toString())),
    );

    _newChatSubscription = _chatRepository.newChats.listen(
      (chatData) => add(ChatEvent.newChat(chatData)),
      onError: (error) => add(ChatEvent.error(error.toString())),
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _newChatSubscription?.cancel();
    _chatRepository.dispose();
    return super.close();
  }
}
