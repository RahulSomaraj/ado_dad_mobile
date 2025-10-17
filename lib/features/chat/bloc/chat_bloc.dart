import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:ado_dad_user/features/chat/services/chat_socket_service.dart';
import 'package:ado_dad_user/features/chat/services/chat_api_service.dart';
import 'package:ado_dad_user/common/shared_pref.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatSocketService _socketService = ChatSocketService();
  final ChatApiService _apiService = ChatApiService();
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatEventSubscription;
  StreamSubscription<String>? _errorSubscription;

  ChatBloc() : super(const ChatState()) {
    // Connection events
    on<ConnectToChat>(_onConnectToChat);
    on<DisconnectFromChat>(_onDisconnectFromChat);
    on<ReconnectToChat>(_onReconnectToChat);
    on<SocketConnected>(_onSocketConnected);
    on<SocketDisconnected>(_onSocketDisconnected);
    on<SocketError>(_onSocketError);

    // Thread events
    on<JoinThread>(_onJoinThread);
    on<LeaveThread>(_onLeaveThread);
    on<LoadThreads>(_onLoadThreads);
    on<SelectThread>(_onSelectThread);

    // Message events
    on<SendMessage>(_onSendMessage);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMessagesFromApi>(_onLoadMessagesFromApi);
    on<MessagesReceived>(_onMessagesReceived);
    on<MessagesLoadedFromApi>(_onMessagesLoadedFromApi);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageSent>(_onMessageSent);

    // Typing events
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<TypingReceived>(_onTypingReceived);
    on<StopTypingReceived>(_onStopTypingReceived);

    // Offer events
    on<SendOffer>(_onSendOffer);
    on<GetUserChatRooms>(_onGetUserChatRooms);
    on<ChatRoomsReceived>(_onChatRoomsReceived);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen to connection state changes
    _connectionSubscription = _socketService.connectionStream.listen(
      (isConnected) {
        if (isConnected) {
          add(const ChatEvent.socketConnected());
        } else {
          add(const ChatEvent.socketDisconnected());
        }
      },
    );

    // Listen to chat events
    _chatEventSubscription = _socketService.chatEventStream.listen(
      (event) {
        _handleSocketEvent(event);
      },
    );

    // Listen to errors
    _errorSubscription = _socketService.errorStream.listen(
      (error) {
        add(ChatEvent.socketError(error));
      },
    );
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final data = event['data'];

    switch (type) {
      case 'new_message':
        if (data is Map<String, dynamic>) {
          try {
            final message = ChatMessage.fromJson(data);
            add(ChatEvent.newMessageReceived(message));
          } catch (e) {
            log('Error parsing new message: $e');
          }
        }
        break;
      case 'message_sent':
        if (data is Map<String, dynamic>) {
          try {
            final message = ChatMessage.fromJson(data);
            add(ChatEvent.messageSent(message));
          } catch (e) {
            log('Error parsing sent message: $e');
          }
        }
        break;
      case 'typing':
        if (data is Map<String, dynamic>) {
          try {
            final typing = TypingIndicator.fromJson(data);
            add(ChatEvent.typingReceived(typing));
          } catch (e) {
            log('Error parsing typing indicator: $e');
          }
        }
        break;
      case 'stop_typing':
        if (data is Map<String, dynamic>) {
          try {
            final typing = TypingIndicator.fromJson(data);
            add(ChatEvent.stopTypingReceived(typing));
          } catch (e) {
            log('Error parsing stop typing: $e');
          }
        }
        break;
      case 'getUserChatRoomsResponse':
        if (data is Map<String, dynamic>) {
          try {
            log('📋 Processing getUserChatRoomsResponse: $data');
            add(ChatEvent.chatRoomsReceived(data));
          } catch (e) {
            log('❌ Error parsing chat rooms response: $e');
            log('🔍 Response data: $data');
          }
        } else {
          log('⚠️ getUserChatRoomsResponse data is not Map<String, dynamic>: ${data.runtimeType}');
        }
        break;
      case 'loadRoomMessagesResponse':
        if (data is Map<String, dynamic>) {
          try {
            log('📨 Processing loadRoomMessagesResponse: $data');
            _handleLoadRoomMessagesResponse(data);
          } catch (e) {
            log('❌ Error parsing load room messages response: $e');
            log('🔍 Response data: $data');
          }
        } else {
          log('⚠️ loadRoomMessagesResponse data is not Map<String, dynamic>: ${data.runtimeType}');
        }
        break;
      case 'existingChatRoomResponse':
        log('🔍 Received existingChatRoomResponse: $data');
        // This event is handled by the socket service directly
        break;
      case 'chatRoomCreated':
        log('🏗️ Received chatRoomCreated: $data');
        // This event is handled by the socket service directly
        break;
      case 'chatRoomJoined':
        log('🚪 Received chatRoomJoined: $data');
        // This event is handled by the socket service directly
        break;
      default:
        log('Unhandled socket event: $type');
    }
  }

  // Connection event handlers
  Future<void> _onConnectToChat(
      ConnectToChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(connectionState: SocketConnectionState.connecting));
    await _socketService.connect();
  }

  Future<void> _onDisconnectFromChat(
      DisconnectFromChat event, Emitter<ChatState> emit) async {
    await _socketService.disconnect();
    emit(state.copyWith(
      connectionState: SocketConnectionState.disconnected,
      isConnected: false,
      socketId: null,
    ));
  }

  Future<void> _onReconnectToChat(
      ReconnectToChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(connectionState: SocketConnectionState.reconnecting));
    await _socketService.reconnect();
  }

  void _onSocketConnected(SocketConnected event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      connectionState: SocketConnectionState.connected,
      isConnected: true,
      socketId: _socketService.socketId,
      error: null,
    ));
  }

  void _onSocketDisconnected(
      SocketDisconnected event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      connectionState: SocketConnectionState.disconnected,
      isConnected: false,
      socketId: null,
    ));
  }

  void _onSocketError(SocketError event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      connectionState: SocketConnectionState.error,
      error: event.error,
    ));
  }

  // Thread event handlers
  Future<void> _onJoinThread(JoinThread event, Emitter<ChatState> emit) async {
    await _socketService.joinThread(event.threadId);
  }

  Future<void> _onLeaveThread(
      LeaveThread event, Emitter<ChatState> emit) async {
    await _socketService.leaveThread(event.threadId);
  }

  Future<void> _onLoadThreads(
      LoadThreads event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingThreads: true));

    try {
      // TODO: Load threads from API
      // For now, we'll use dummy data
      final threads = <ChatThread>[];
      emit(state.copyWith(
        threads: threads,
        isLoadingThreads: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingThreads: false,
        error: 'Failed to load threads: $e',
      ));
    }
  }

  void _onSelectThread(SelectThread event, Emitter<ChatState> emit) {
    final selectedThread = state.threads.firstWhere(
      (thread) => thread.id == event.threadId,
      orElse: () => throw Exception('Thread not found'),
    );

    emit(state.copyWith(
      selectedThreadId: event.threadId,
      currentThread: selectedThread,
    ));

    // Load messages for the selected thread
    add(ChatEvent.loadMessages(event.threadId));
  }

  // Message event handlers
  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isSendingMessage: true));

    try {
      await _socketService.sendMessage(
        threadId: event.threadId,
        message: event.content,
        messageType: event.messageType,
        metadata: event.metadata,
      );

      // Create a temporary message for immediate UI feedback
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        threadId: event.threadId,
        senderId: await _getCurrentUserId(),
        senderName: await _getCurrentUserName() ?? 'You',
        content: event.content,
        messageType: event.messageType ?? 'text',
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: false,
        metadata: event.metadata,
      );

      // Add to current messages
      final currentMessages =
          List<ChatMessage>.from(state.messages[event.threadId] ?? []);
      currentMessages.add(tempMessage);

      final updatedMessages =
          Map<String, List<ChatMessage>>.from(state.messages);
      updatedMessages[event.threadId] = currentMessages;

      emit(state.copyWith(
        messages: updatedMessages,
        selectedThreadId: event.threadId, // Ensure selectedThreadId is set
        isSendingMessage: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSendingMessage: false,
        error: 'Failed to send message: $e',
      ));
    }
  }

  Future<void> _onLoadMessages(
      LoadMessages event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingMessages: true));

    try {
      // Load messages from socket service
      await _socketService.loadRoomMessages(event.threadId);

      // The response will be handled by the socket listener
      // For now, we'll keep loading state until messages are received
    } catch (e) {
      log('❌ Error loading messages: $e');
      emit(state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to load messages: $e',
      ));
    }
  }

  Future<void> _onLoadMessagesFromApi(
      LoadMessagesFromApi event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoadingMessages: true));

    try {
      log('🔄 Loading messages from API for room: ${event.roomId}');

      // Fetch messages from API
      final response = await _apiService.getChatRoomMessages(event.roomId);

      // Convert API messages to ChatMessage objects
      final chatMessages = response.data.messages
          .map((apiMessage) => apiMessage.toChatMessage())
          .toList();

      // Sort messages by timestamp (oldest first)
      chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update state with loaded messages
      final updatedMessages =
          Map<String, List<ChatMessage>>.from(state.messages);
      updatedMessages[event.roomId] = chatMessages;

      emit(state.copyWith(
        messages: updatedMessages,
        selectedThreadId: event
            .roomId, // Set the selected thread ID so currentThreadMessages works
        isLoadingMessages: false,
        error: null,
      ));

      log('✅ Loaded ${chatMessages.length} messages from API');
    } catch (e) {
      log('❌ Error loading messages from API: $e');
      emit(state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to load messages: $e',
      ));
    }
  }

  void _onMessagesLoadedFromApi(
      MessagesLoadedFromApi event, Emitter<ChatState> emit) {
    try {
      log('📨 Processing messages loaded from API for room: ${event.roomId}');

      // Update state with loaded messages
      final updatedMessages =
          Map<String, List<ChatMessage>>.from(state.messages);
      updatedMessages[event.roomId] = event.messages;

      emit(state.copyWith(
        messages: updatedMessages,
        isLoadingMessages: false,
        error: null,
      ));

      log('✅ Updated state with ${event.messages.length} messages from API');
    } catch (e) {
      log('❌ Error processing messages from API: $e');
      emit(state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to process messages: $e',
      ));
    }
  }

  void _onMessagesReceived(MessagesReceived event, Emitter<ChatState> emit) {
    try {
      log('📨 Processing received messages for thread: ${event.threadId}');

      // Parse messages from server response
      final messages = event.messages.map((messageData) {
        return ChatMessage(
          id: messageData['id'] ?? messageData['messageId'] ?? '',
          threadId: event.threadId,
          senderId: messageData['senderId'] ?? messageData['userId'] ?? '',
          senderName:
              messageData['senderName'] ?? messageData['userName'] ?? 'Unknown',
          content: messageData['content'] ?? messageData['message'] ?? '',
          timestamp: DateTime.tryParse(
                  messageData['timestamp'] ?? messageData['createdAt'] ?? '') ??
              DateTime.now(),
          messageType:
              messageData['messageType'] ?? messageData['type'] ?? 'text',
          isRead: messageData['isRead'] as bool? ?? false,
          isDelivered: messageData['isDelivered'] as bool? ?? true,
          metadata: messageData['metadata'] as Map<String, dynamic>?,
        );
      }).toList();

      // Update messages for this thread
      final updatedMessages =
          Map<String, List<ChatMessage>>.from(state.messages);
      updatedMessages[event.threadId] = messages;

      emit(state.copyWith(
        messages: updatedMessages,
        isLoadingMessages: false,
        error: null,
      ));

      log('✅ Loaded ${messages.length} messages for thread: ${event.threadId}');
    } catch (e) {
      log('❌ Error processing received messages: $e');
      emit(state.copyWith(
        isLoadingMessages: false,
        error: 'Failed to process messages: $e',
      ));
    }
  }

  Future<void> _onMarkMessageAsRead(
      MarkMessageAsRead event, Emitter<ChatState> emit) async {
    // TODO: Implement mark as read functionality
    log('Marking message as read: ${event.messageId}');
  }

  Future<void> _onDeleteMessage(
      DeleteMessage event, Emitter<ChatState> emit) async {
    // TODO: Implement delete message functionality
    log('Deleting message: ${event.messageId}');
  }

  void _onNewMessageReceived(
      NewMessageReceived event, Emitter<ChatState> emit) {
    final message = event.message;
    final threadId = message.threadId;

    // Add message to the appropriate thread
    final currentMessages =
        List<ChatMessage>.from(state.messages[threadId] ?? []);
    currentMessages.add(message);

    final updatedMessages = Map<String, List<ChatMessage>>.from(state.messages);
    updatedMessages[threadId] = currentMessages;

    // Update thread's last message and unread count
    final updatedThreads = state.threads.map((thread) {
      if (thread.id == threadId) {
        return thread.copyWith(
          lastMessage: message,
          unreadCount: thread.unreadCount + 1,
          lastActivity: message.timestamp,
        );
      }
      return thread;
    }).toList();

    // Also update chatRooms list with new message count and last message
    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == threadId) {
        // Update message count in metadata
        final updatedMetadata = Map<String, dynamic>.from(room.metadata ?? {});
        final currentMessageCount =
            updatedMetadata['messageCount'] as int? ?? 0;
        updatedMetadata['messageCount'] = currentMessageCount + 1;

        return room.copyWith(
          lastMessage: message,
          unreadCount: room.unreadCount + 1,
          lastActivity: message.timestamp,
          metadata: updatedMetadata,
        );
      }
      return room;
    }).toList();

    emit(state.copyWith(
      messages: updatedMessages,
      selectedThreadId:
          threadId, // Ensure selectedThreadId is set for new messages
      threads: updatedThreads,
      chatRooms: updatedChatRooms,
    ));
  }

  void _onMessageSent(MessageSent event, Emitter<ChatState> emit) {
    // Update the temporary message with the actual message from server
    final message = event.message;
    final threadId = message.threadId;

    final currentMessages =
        List<ChatMessage>.from(state.messages[threadId] ?? []);
    final messageIndex =
        currentMessages.indexWhere((m) => m.content == message.content);

    if (messageIndex != -1) {
      currentMessages[messageIndex] = message;
    } else {
      currentMessages.add(message);
    }

    final updatedMessages = Map<String, List<ChatMessage>>.from(state.messages);
    updatedMessages[threadId] = currentMessages;

    // Also update chatRooms list with new message count and last message
    final updatedChatRooms = state.chatRooms.map((room) {
      if (room.id == threadId) {
        // Update message count in metadata
        final updatedMetadata = Map<String, dynamic>.from(room.metadata ?? {});
        final currentMessageCount =
            updatedMetadata['messageCount'] as int? ?? 0;
        updatedMetadata['messageCount'] = currentMessageCount + 1;

        return room.copyWith(
          lastMessage: message,
          lastActivity: message.timestamp,
          metadata: updatedMetadata,
        );
      }
      return room;
    }).toList();

    emit(state.copyWith(
      messages: updatedMessages,
      selectedThreadId: threadId, // Ensure selectedThreadId is set
      chatRooms: updatedChatRooms,
    ));
  }

  // Typing event handlers
  Future<void> _onStartTyping(
      StartTyping event, Emitter<ChatState> emit) async {
    await _socketService.sendTyping(event.threadId);
    emit(state.copyWith(isTyping: true));
  }

  Future<void> _onStopTyping(StopTyping event, Emitter<ChatState> emit) async {
    await _socketService.stopTyping(event.threadId);
    emit(state.copyWith(isTyping: false));
  }

  void _onTypingReceived(TypingReceived event, Emitter<ChatState> emit) {
    final typing = event.typing;
    final updatedTypingUsers =
        Map<String, TypingIndicator>.from(state.typingUsers);
    updatedTypingUsers[typing.threadId] = typing;

    emit(state.copyWith(typingUsers: updatedTypingUsers));
  }

  void _onStopTypingReceived(
      StopTypingReceived event, Emitter<ChatState> emit) {
    final typing = event.typing;
    final updatedTypingUsers =
        Map<String, TypingIndicator>.from(state.typingUsers);
    updatedTypingUsers[typing.threadId] = typing.copyWith(isTyping: false);

    emit(state.copyWith(typingUsers: updatedTypingUsers));
  }

  // Offer event handlers
  Future<void> _onSendOffer(SendOffer event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isSendingOffer: true));

    try {
      final response = await _socketService.sendOfferMessage(
        adId: event.adId,
        amount: event.amount,
        adTitle: event.adTitle,
        adPosterName: event.adPosterName,
      );

      if (response != null && response['success']) {
        emit(state.copyWith(
          isSendingOffer: false,
          lastOfferRoomId: response['roomId'],
          error: null, // Clear any previous errors
        ));

        // Log warning if present but don't treat as error
        if (response['warning'] != null) {
          log('⚠️ Offer sent with warning: ${response['warning']}');
        }

        // Optionally navigate to the chat room
        // You can emit a navigation event here if needed
      } else {
        emit(state.copyWith(
          isSendingOffer: false,
          error: response?['error'] ?? 'Failed to send offer',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isSendingOffer: false,
        error: 'Failed to send offer: $e',
      ));
    }
  }

  Future<void> _onGetUserChatRooms(
      GetUserChatRooms event, Emitter<ChatState> emit) async {
    try {
      log('📋 Getting user chat rooms...');
      emit(state.copyWith(isLoadingChatRooms: true, error: null));

      // Ensure socket is connected before requesting chat rooms
      if (!state.isConnected) {
        log('🔌 Socket not connected, connecting first...');
        emit(state.copyWith(connectionState: SocketConnectionState.connecting));
        await _socketService.connect();

        // Wait a bit for connection to establish
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if connection was successful
        if (!_socketService.isConnected) {
          log('❌ Failed to connect to socket');
          emit(state.copyWith(
            isLoadingChatRooms: false,
            connectionState: SocketConnectionState.error,
            error: 'Failed to connect to chat server',
          ));
          return;
        }
      }

      await _socketService.getUserChatRooms();

      // Set a timeout to prevent infinite loading
      Timer(const Duration(seconds: 10), () {
        if (state.isLoadingChatRooms) {
          log('⏰ Chat rooms loading timeout');
          emit(state.copyWith(
            isLoadingChatRooms: false,
            error: 'Request timeout - please try again',
          ));
        }
      });

      // The response will be handled by the socket listener
    } catch (e) {
      log('❌ Error getting user chat rooms: $e');
      emit(state.copyWith(
        isLoadingChatRooms: false,
        error: 'Failed to get chat rooms: $e',
      ));
    }
  }

  void _handleLoadRoomMessagesResponse(Map<String, dynamic> response) {
    try {
      log('🔍 Handling loadRoomMessagesResponse: $response');

      if (response['success'] == true && response['messages'] != null) {
        final roomId = response['roomId'] as String?;
        final messagesList = response['messages'] as List<dynamic>? ?? [];

        if (roomId != null) {
          // Convert to List<Map<String, dynamic>>
          final messages = messagesList.cast<Map<String, dynamic>>();
          add(ChatEvent.messagesReceived(roomId, messages));
        } else {
          log('⚠️ No roomId in loadRoomMessagesResponse');
        }
      } else {
        log('⚠️ loadRoomMessagesResponse indicates failure or no messages');
        log('🔍 Response: $response');
      }
    } catch (e) {
      log('❌ Error handling loadRoomMessagesResponse: $e');
    }
  }

  void _onChatRoomsReceived(ChatRoomsReceived event, Emitter<ChatState> emit) {
    try {
      final response = event.response;
      log('🔍 Processing getUserChatRoomsResponse: $response');

      if (response['success'] == true && response['chatRooms'] != null) {
        final chatRoomsList = response['chatRooms'] as List;
        final List<ChatThread> chatRooms = [];

        for (int i = 0; i < chatRoomsList.length; i++) {
          try {
            final roomData = chatRoomsList[i] as Map<String, dynamic>;
            log('🔍 Processing room data: $roomData');

            // Map server response to ChatThread format
            final roomId = roomData['roomId'] as String?;
            final adId = roomData['adId'] as String?;
            final participants =
                roomData['participants'] as List<dynamic>? ?? [];
            final messageCount = roomData['messageCount'] as int? ?? 0;
            final status = roomData['status'] as String? ?? 'active';
            final createdAt = roomData['createdAt'] as String?;
            final lastMessageAt = roomData['lastMessageAt'] as String?;
            final otherUserData =
                roomData['otherUser'] as Map<String, dynamic>?;
            final latestMessageData =
                roomData['latestMessage'] as Map<String, dynamic>?;
            final adDetailsData =
                roomData['adDetails'] as Map<String, dynamic>?;

            if (roomId == null) {
              log('⚠️ Skipping room with missing roomId');
              continue;
            }

            // Convert participants list to participantIds and participantNames
            final participantIds =
                participants.map((p) => p.toString()).toList();
            final participantNames = <String, String>{};

            // For now, use participant IDs as names (can be enhanced later)
            for (final participantId in participantIds) {
              participantNames[participantId] = 'User $participantId';
            }

            // Parse otherUser
            OtherUser? otherUser;
            if (otherUserData != null) {
              otherUser = OtherUser(
                id: otherUserData['id']?.toString() ?? '',
                name: otherUserData['name']?.toString() ?? 'Unknown User',
                profilePic: otherUserData['profilePic']?.toString(),
                email: otherUserData['email']?.toString(),
              );
            }

            // Parse latestMessage
            LatestMessage? latestMessage;
            if (latestMessageData != null) {
              latestMessage = LatestMessage(
                content: latestMessageData['content']?.toString() ?? '',
                type: latestMessageData['type']?.toString() ?? 'text',
                createdAt: latestMessageData['createdAt'] != null
                    ? DateTime.tryParse(
                            latestMessageData['createdAt'].toString()) ??
                        DateTime.now()
                    : DateTime.now(),
              );
            }

            // Parse adDetails
            AdDetails? adDetails;
            if (adDetailsData != null) {
              adDetails = AdDetails(
                id: adDetailsData['id']?.toString() ?? '',
                title: adDetailsData['title']?.toString() ?? '',
                description: adDetailsData['description']?.toString() ?? '',
                price: adDetailsData['price'] as int? ?? 0,
                images: (adDetailsData['images'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                category: adDetailsData['category']?.toString() ?? '',
              );
            }

            // Create ChatThread with mapped data
            final room = ChatThread(
              id: roomId,
              name: otherUser?.name ??
                  'Ad: ${adId?.substring(0, 8) ?? 'Unknown'}...',
              avatarUrl: otherUser?.profilePic,
              participantIds: participantIds,
              participantNames: participantNames,
              participantAvatars: null,
              lastMessage: null, // We'll use latestMessage instead
              unreadCount: 0, // TODO: Calculate from server data if available
              lastActivity: lastMessageAt != null
                  ? DateTime.tryParse(lastMessageAt) ?? DateTime.now()
                  : DateTime.now(),
              isActive: status == 'active',
              threadType: 'direct',
              metadata: {
                'adId': adId,
                'messageCount': messageCount,
                'status': status,
                'originalData': roomData,
              },
              // New fields from API response
              roomId: roomId,
              initiatorId: roomData['initiatorId']?.toString(),
              adId: adId,
              adPosterId: roomData['adPosterId']?.toString(),
              participants: participantIds,
              status: status,
              lastMessageAt: lastMessageAt != null
                  ? DateTime.tryParse(lastMessageAt)
                  : null,
              messageCount: messageCount,
              createdAt:
                  createdAt != null ? DateTime.tryParse(createdAt) : null,
              updatedAt: roomData['updatedAt'] != null
                  ? DateTime.tryParse(roomData['updatedAt'].toString())
                  : null,
              otherUser: otherUser,
              latestMessage: latestMessage,
              adDetails: adDetails,
            );

            chatRooms.add(room);
            log('✅ Successfully parsed room: $roomId');
          } catch (e) {
            log('❌ Error parsing room at index $i: $e');
            // Continue processing other rooms instead of failing completely
          }
        }

        emit(state.copyWith(
          chatRooms: chatRooms,
          isLoadingChatRooms: false,
          error: null,
        ));

        if (chatRooms.isEmpty) {
          log('📭 No chat rooms found');
        } else {
          log('📋 Loaded ${chatRooms.length} chat rooms');
        }
      } else {
        log('❌ Failed to load chat rooms: ${response['error'] ?? 'Unknown error'}');
        emit(state.copyWith(
          isLoadingChatRooms: false,
          error: response['error'] ?? 'Failed to load chat rooms',
        ));
      }
    } catch (e) {
      log('❌ Error processing chat rooms: $e');
      emit(state.copyWith(
        isLoadingChatRooms: false,
        error: 'Error processing chat rooms: $e',
      ));
    }
  }

  /// Helper method to parse last message from server data
  ChatMessage? _parseLastMessage(
      Map<String, dynamic> messageData, String threadId) {
    try {
      return ChatMessage(
        id: messageData['id']?.toString() ??
            messageData['_id']?.toString() ??
            '',
        threadId: threadId,
        senderId: messageData['senderId']?.toString() ?? '',
        senderName: messageData['senderName']?.toString() ?? 'Unknown',
        senderAvatar: messageData['senderAvatar']?.toString(),
        content: messageData['content']?.toString() ?? '',
        messageType: messageData['type']?.toString() ??
            messageData['messageType']?.toString() ??
            'text',
        timestamp: messageData['createdAt'] != null
            ? DateTime.tryParse(messageData['createdAt'].toString()) ??
                DateTime.now()
            : DateTime.now(),
        isRead: messageData['isRead'] as bool? ?? false,
        isDelivered: messageData['isDelivered'] as bool? ?? true,
        metadata: messageData['metadata'] as Map<String, dynamic>?,
        replyToMessageId: messageData['replyToMessageId']?.toString(),
        attachments: messageData['attachments'] as List<String>?,
      );
    } catch (e) {
      log('❌ Error parsing last message: $e');
      return null;
    }
  }

  // Helper methods
  Future<String> _getCurrentUserId() async {
    return await SharedPrefs().getUserId() ?? 'unknown';
  }

  Future<String?> _getCurrentUserName() async {
    return await SharedPrefs().getString('userName');
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _chatEventSubscription?.cancel();
    _errorSubscription?.cancel();
    _socketService.dispose();
    return super.close();
  }
}
