import 'dart:async';
import 'package:ado_dad_user/features/chat/data/chat_repository.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room_event.dart';
part 'chat_room_state.dart';
part 'chat_room_bloc.freezed.dart';

/// BLoC for managing individual chat room state
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ChatRepository _chatRepository;
  StreamSubscription<ChatMessage>? _messageSubscription;

  ChatRoomBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(const ChatRoomState.initial()) {
    on<ChatRoomEvent>((event, emit) async {
      event.map(
        setChat: (e) => _onSetChat(e, emit),
        loadMessages: (e) => _onLoadMessages(e, emit),
        sendMessage: (e) => _onSendMessage(e, emit),
        markAsRead: (e) => _onMarkAsRead(e, emit),
        newMessage: (e) => _onNewMessage(e, emit),
        clearChat: (e) => _onClearChat(e, emit),
      );
    });
  }

  Future<void> _onSetChat(_SetChat event, Emitter<ChatRoomState> emit) async {
    emit(ChatRoomState.loading(chatId: event.chatId));

    try {
      // Join the chat
      await _chatRepository.joinChat(event.chatId);

      // Load messages
      final messages = await _chatRepository.getChatMessages(event.chatId);

      // Setup message subscription for this chat
      _setupMessageSubscription(event.chatId);

      emit(ChatRoomState.loaded(
        chatId: event.chatId,
        messages: messages,
        loading: false,
      ));

      // Mark messages as read
      await _chatRepository.markAsRead(event.chatId);
    } catch (e) {
      emit(ChatRoomState.error(
        chatId: event.chatId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMessages(
      _LoadMessages event, Emitter<ChatRoomState> emit) async {
    state.maybeWhen(
      loaded: (chatId, messages, loading) {
        emit(ChatRoomState.loaded(
          chatId: chatId,
          messages: messages,
          loading: true,
        ));
      },
      orElse: () {},
    );

    try {
      final messages = await _chatRepository.getChatMessages(event.chatId);

      state.maybeWhen(
        loaded: (chatId, _, __) {
          emit(ChatRoomState.loaded(
            chatId: chatId,
            messages: messages,
            loading: false,
          ));
        },
        orElse: () {},
      );
    } catch (e) {
      state.maybeWhen(
        loaded: (chatId, messages, _) {
          emit(ChatRoomState.error(
            chatId: chatId,
            message: e.toString(),
          ));
        },
        orElse: () {},
      );
    }
  }

  Future<void> _onSendMessage(
      _SendMessage event, Emitter<ChatRoomState> emit) async {
    // Validate message content
    if (event.content.trim().isEmpty) {
      return; // Don't send empty or whitespace-only messages
    }

    try {
      await _chatRepository.sendMessage(event.chatId, event.content);

      // Optimistically add message to state
      state.maybeWhen(
        loaded: (chatId, messages, loading) {
          final newMessage = ChatMessage(
            id: DateTime.now()
                .millisecondsSinceEpoch
                .toString(), // Temporary ID
            chat: chatId,
            sender: 'current_user', // This should come from auth provider
            content: event.content,
            createdAt: DateTime.now(),
            read: false,
          );

          emit(ChatRoomState.loaded(
            chatId: chatId,
            messages: [...messages, newMessage],
            loading: loading,
          ));
        },
        orElse: () {},
      );
    } catch (e) {
      // Handle error - emit error state
      state.maybeWhen(
        loaded: (chatId, messages, loading) {
          emit(ChatRoomState.error(
            chatId: chatId,
            message: e.toString(),
          ));
        },
        orElse: () {},
      );
    }
  }

  Future<void> _onMarkAsRead(
      _MarkAsRead event, Emitter<ChatRoomState> emit) async {
    try {
      await _chatRepository.markAsRead(event.chatId);

      // Update messages to mark them as read
      state.maybeWhen(
        loaded: (chatId, messages, loading) {
          final updatedMessages = messages.map((message) {
            if (message.chat == event.chatId) {
              return message.copyWith(read: true);
            }
            return message;
          }).toList();

          emit(ChatRoomState.loaded(
            chatId: chatId,
            messages: updatedMessages,
            loading: loading,
          ));
        },
        orElse: () {},
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _onNewMessage(_NewMessage event, Emitter<ChatRoomState> emit) {
    // Only add message if it belongs to current chat
    state.maybeWhen(
      loaded: (chatId, messages, loading) {
        if (event.message.chat == chatId) {
          // Check if message already exists to avoid duplicates
          final messageExists =
              messages.any((msg) => msg.id == event.message.id);

          if (!messageExists) {
            emit(ChatRoomState.loaded(
              chatId: chatId,
              messages: [...messages, event.message],
              loading: loading,
            ));

            // Mark as read if it's not from current user
            if (event.message.sender != 'current_user') {
              _chatRepository.markAsRead(chatId);
            }
          }
        }
      },
      orElse: () {},
    );
  }

  void _onClearChat(_ClearChat event, Emitter<ChatRoomState> emit) {
    _messageSubscription?.cancel();
    emit(const ChatRoomState.initial());
  }

  void _setupMessageSubscription(String chatId) {
    _messageSubscription?.cancel();

    _messageSubscription = _chatRepository.messages.listen(
      (message) {
        if (message.chat == chatId) {
          add(ChatRoomEvent.newMessage(message));
        }
      },
      onError: (error) {
        print('Error in message subscription: $error');
      },
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
