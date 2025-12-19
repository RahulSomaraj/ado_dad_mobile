import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/common/auth_guard.dart';
import 'package:ado_dad_user/repositories/chat_repository.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository = ChatRepository();
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _errorSubscription;

  ChatBloc() : super(ChatInitial()) {
    print('🔧 ChatBloc constructor called - registering event handlers');
    on<InitializeChat>(_onInitializeChat);
    on<LoadChatRooms>(_onLoadChatRooms);
    on<JoinChatRoom>(_onJoinChatRoom);
    on<LoadRoomMessages>(_onLoadRoomMessages);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<SendMessage>(_onSendMessage);
    on<CreateChatRoom>(_onCreateChatRoom);
    on<SendOffer>(_onSendOffer);
    on<ChatRoomsLoaded>(_onChatRoomsLoaded);
    on<ChatError>(_onChatError);
    on<DisposeChat>(_onDisposeChat);
    print('✅ ChatBloc event handlers registered successfully');
  }

  Future<void> _onInitializeChat(
      InitializeChat event, Emitter<ChatState> emit) async {
    // Check authentication before initializing chat
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(ChatErrorState('Please login to access chat features.'));
      return;
    }

    try {
      emit(ChatLoading());

      await _chatRepository.initialize();

      // Connect to WebSocket
      print('🔌 Connecting to WebSocket...');
      final connected = await _chatRepository.connect();
      if (!connected) {
        print('⚠️ WebSocket connection failed, but continuing with HTTP API');
      } else {
        print('✅ WebSocket connected successfully');
      }

      // Listen to rooms stream
      _roomsSubscription = _chatRepository.roomsStream.listen((rooms) {
        add(ChatRoomsLoaded(rooms));
      });

      // Listen to error stream
      _errorSubscription = _chatRepository.errorStream.listen((error) {
        add(ChatError(error));
      });

      // Listen to messages stream for real-time messages
      _chatRepository.messagesStream.listen((messageList) {
        print('🔍 ChatBloc received message list: ${messageList.length} items');
        print('📦 Message list data: $messageList');

        // Process each message in the list (each item is a single message object)
        for (final message in messageList) {
          print('🔍 Processing individual message: $message');
          print('✅ Dispatching NewMessageReceived event');
          add(NewMessageReceived(message));
        }
      });

      // Load rooms
      await _chatRepository.getUserChatRooms();
    } catch (e) {
      emit(ChatErrorState('Initialization failed: $e'));
    }
  }

  Future<void> _onLoadChatRooms(
      LoadChatRooms event, Emitter<ChatState> emit) async {
    // Check authentication before loading chat rooms
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(ChatErrorState('Please login to view your chat rooms.'));
      return;
    }

    try {
      emit(ChatLoading());
      await _chatRepository.getUserChatRooms();
    } catch (e) {
      emit(ChatErrorState('Failed to load chat rooms: $e'));
    }
  }

  Future<void> _onJoinChatRoom(
      JoinChatRoom event, Emitter<ChatState> emit) async {
    print('🎯 _onJoinChatRoom method called with roomId: ${event.roomId}');

    // Check authentication before joining chat room
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(ChatErrorState('Please login to join chat rooms.'));
      return;
    }

    try {
      print('🚪 Attempting to join room: ${event.roomId}');

      // Get and log current user ID
      final currentUserId = await _chatRepository.getCurrentUserId();
      print('👤 Current user ID: $currentUserId');

      emit(ChatLoading());

      // Use WebSocket to join the room
      await _chatRepository.joinChatRoom(event.roomId);

      print('✅ Successfully joined room: ${event.roomId}');
      emit(ChatRoomJoined(event.roomId, 'Successfully joined room'));
    } catch (e) {
      print('❌ Failed to join room: $e');
      emit(ChatErrorState('Failed to join room: $e'));
    }
  }

  Future<void> _onLoadRoomMessages(
      LoadRoomMessages event, Emitter<ChatState> emit) async {
    print('🎯 _onLoadRoomMessages method called with roomId: ${event.roomId}');

    // Check authentication before loading messages
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(ChatErrorState('Please login to view messages.'));
      return;
    }

    try {
      print('📨 Loading messages for room: ${event.roomId}');
      emit(ChatLoading());

      // Load messages for the room
      final messages = await _chatRepository.getRoomMessages(event.roomId);

      print(
          '✅ Successfully loaded ${messages.length} messages for room: ${event.roomId}');
      emit(MessagesLoaded(event.roomId, messages));
    } catch (e) {
      print('❌ Failed to load messages: $e');
      emit(ChatErrorState('Failed to load messages: $e'));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    // Check authentication before sending message
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(ChatErrorState('Please login to send messages.'));
      return;
    }

    try {
      print('📤 Sending message through Bloc: ${event.content}');
      _chatRepository.sendMessage(event.content, type: event.type);
    } catch (e) {
      emit(ChatErrorState('Failed to send message: $e'));
    }
  }

  Future<void> _onCreateChatRoom(
      CreateChatRoom event, Emitter<ChatState> emit) async {
    // Check authentication before creating chat room
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(ChatErrorState('Please login to create chat rooms.'));
      return;
    }

    try {
      print('🏠 Creating new chat room for ad: ${event.adId}');
      emit(ChatLoading());

      // Ensure socket connected
      final connected = await _chatRepository.connect();
      if (!connected) {
        throw Exception('Failed to connect to WebSocket');
      }

      // Ask repository to create room
      final roomId = await _chatRepository.createChatRoom(event.adId);

      if (roomId != null) {
        print('✅ Chat room created successfully: $roomId');
        emit(ChatRoomCreated(roomId));
      } else {
        emit(ChatErrorState('Failed to create chat room'));
      }
    } catch (e) {
      print('❌ Error creating chat room: $e');
      emit(ChatErrorState('Failed to create chat room: $e'));
    }
  }

  Future<void> _onSendOffer(SendOffer event, Emitter<ChatState> emit) async {
    // Check authentication before sending offer
    final isAuthenticated = await AuthGuard.isAuthenticated();
    if (!isAuthenticated) {
      emit(ChatErrorState('Please login to send offers.'));
      return;
    }

    try {
      emit(ChatLoading());
      print('💬 Sending offer for ad: ${event.adId}');

      // 1️⃣ Ensure socket connection
      final connected = await _chatRepository.connect();
      if (!connected) throw Exception('Unable to connect to chat server');
      print('✅ Socket connected');

      // 2️⃣ Send offer message (handles room creation, joining, and sending)
      await _chatRepository.sendOfferMessage(event.adId, event.amount);

      emit(ChatRoomJoined('', 'Offer sent successfully'));
    } catch (e) {
      print('❌ SendOffer failed: $e');
      emit(ChatErrorState('Failed to send offer: $e'));
    }
  }

  void _onChatRoomsLoaded(ChatRoomsLoaded event, Emitter<ChatState> emit) {
    emit(ChatRoomsSuccess(event.rooms));
  }

  void _onChatError(ChatError event, Emitter<ChatState> emit) {
    emit(ChatErrorState(event.error));
  }

  void _onNewMessageReceived(
      NewMessageReceived event, Emitter<ChatState> emit) {
    print('💬 New message received: ${event.message['content']}');
    emit(NewMessageReceivedState(event.message));
  }

  Future<void> _onDisposeChat(
      DisposeChat event, Emitter<ChatState> emit) async {
    await _roomsSubscription?.cancel();
    await _errorSubscription?.cancel();
    _chatRepository.dispose();
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    _errorSubscription?.cancel();
    _chatRepository.dispose();
    return super.close();
  }
}
