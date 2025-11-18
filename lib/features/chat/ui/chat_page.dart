import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/repositories/chat_repository.dart';
import 'package:go_router/go_router.dart';

class ChatPage extends StatefulWidget {
  final String roomId;
  final String? otherUserName;
  final String? otherUserProfilePic;
  final String? fromPage; // Track where user came from
  final String? adId; // Ad ID for this chat
  final String? adTitle; // Ad title for this chat

  const ChatPage({
    super.key,
    required this.roomId,
    this.otherUserName,
    this.otherUserProfilePic,
    this.fromPage,
    this.adId,
    this.adTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    print('🚀 Chat page initialized for room: ${widget.roomId}');
    print('👤 Other user: ${widget.otherUserName}');
    print('🖼️ Profile pic: ${widget.otherUserProfilePic}');
    print('📝 Ad title: ${widget.adTitle}');

    // Get current user ID
    _getCurrentUserId();

    // Join the room and load messages when page loads
    print('🚪 Dispatching JoinChatRoom event...');
    context.read<ChatBloc>().add(JoinChatRoom(widget.roomId));

    // Also directly load messages to ensure they refresh when room opens
    // This ensures messages are always loaded even if room was already joined
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🔄 Silently refreshing messages for room: ${widget.roomId}');
        context.read<ChatBloc>().add(LoadRoomMessages(widget.roomId));
      }
    });
  }

  Future<void> _getCurrentUserId() async {
    try {
      final chatRepository = ChatRepository();
      _currentUserId = await chatRepository.getCurrentUserId();
      print('👤 Current user ID in chat page: $_currentUserId');
    } catch (e) {
      print('❌ Error getting current user ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building chat page for room: ${widget.roomId}');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 16,
                tablet: 20,
                largeTablet: 24,
                desktop: 28,
              ),
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.otherUserProfilePic != null &&
                      widget.otherUserProfilePic != 'default-profile-pic-url'
                  ? NetworkImage(widget.otherUserProfilePic!)
                  : null,
              child: widget.otherUserProfilePic == null ||
                      widget.otherUserProfilePic == 'default-profile-pic-url'
                  ? Text(
                      (widget.otherUserName ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 18,
                          largeTablet: 22,
                          desktop: 26,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 12,
                tablet: 16,
                largeTablet: 20,
                desktop: 24,
              ),
            ),
            Expanded(
              child: Text(
                widget.adTitle ?? (widget.otherUserName ?? 'Chat'),
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 20,
                    largeTablet: 24,
                    desktop: 28,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            (!kIsWeb && Platform.isIOS)
                ? Icons.arrow_back_ios
                : Icons.arrow_back,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 24,
              tablet: 30,
              largeTablet: 32,
              desktop: 36,
            ),
          ),
          onPressed: () => _handleBackNavigation(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              size: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 24,
                tablet: 30,
                largeTablet: 32,
                desktop: 36,
              ),
            ),
            onPressed: () {
              // TODO: Add more options menu
            },
          ),
        ],
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (!mounted) return; // Check if widget is still mounted

          if (state is ChatRoomJoined) {
            print('✅ Room joined successfully: ${state.roomId}');
            print('📨 Dispatching LoadRoomMessages event...');
            context.read<ChatBloc>().add(LoadRoomMessages(widget.roomId));
          } else if (state is MessagesLoaded) {
            if (mounted) {
              setState(() {
                // Reverse messages to show oldest first (top to bottom)
                _messages = List.from(state.messages.reversed);
              });
            }
            print('✅ Messages loaded: ${state.messages.length} messages');

            // Scroll to bottom after messages are loaded
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          } else if (state is NewMessageReceivedState) {
            print('💬 New message received: ${state.message['content']}');
            // Check if message already exists to prevent duplicates
            final messageId = state.message['id'] ?? state.message['_id'];
            final existingMessage =
                _messages.any((msg) => (msg['id'] ?? msg['_id']) == messageId);

            if (!existingMessage) {
              // Add the new message to the local list
              if (mounted) {
                setState(() {
                  _messages.add(state.message);
                });

                // Scroll to bottom to show the new message
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            } else {
              print('⚠️ Duplicate message detected, skipping: $messageId');
            }
          } else if (state is ChatErrorState) {
            print('❌ Chat error: ${state.error}');
          }
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            // Only show loading indicator if messages are empty (initial load)
            // Don't show loading during refreshes when messages already exist
            if (state is ChatLoading && _messages.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 64,
                                  tablet: 80,
                                  largeTablet: 96,
                                  desktop: 112,
                                ),
                                color: Colors.grey,
                              ),
                              SizedBox(
                                height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 16,
                                  tablet: 20,
                                  largeTablet: 24,
                                  desktop: 28,
                                ),
                              ),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                    context,
                                    mobile: 18,
                                    tablet: 22,
                                    largeTablet: 26,
                                    desktop: 30,
                                  ),
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(
                                height: GetResponsiveSize.getResponsiveSize(
                                  context,
                                  mobile: 8,
                                  tablet: 12,
                                  largeTablet: 16,
                                  desktop: 20,
                                ),
                              ),
                              Text(
                                'Start a conversation!',
                                style: TextStyle(
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                    context,
                                    mobile: 14,
                                    tablet: 18,
                                    largeTablet: 20,
                                    desktop: 24,
                                  ),
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(
                            GetResponsiveSize.getResponsivePadding(
                              context,
                              mobile: 16,
                              tablet: 24,
                              largeTablet: 32,
                              desktop: 40,
                            ),
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message, index);
                          },
                        ),
                ),

                // Message input
                SafeArea(
                  top: false,
                  minimum: EdgeInsets.only(
                    bottom: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 50,
                      tablet: 50,
                      largeTablet: 50,
                      desktop: 50,
                    ),
                  ),
                  child: _buildMessageInput(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final sender = message['sender'] as Map<String, dynamic>?;
    final senderId = message['senderId'] ?? '';
    final content = message['content'] ?? '';
    final timestamp = message['createdAt'] != null
        ? DateTime.tryParse(message['createdAt'])
        : DateTime.now();

    // Determine if message is from current user
    final isMe = _currentUserId != null && senderId == _currentUserId;

    return Container(
      margin: EdgeInsets.only(
        bottom: GetResponsiveSize.getResponsiveSize(
          context,
          mobile: 8,
          tablet: 12,
          largeTablet: 16,
          desktop: 20,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 16,
                tablet: 20,
                largeTablet: 24,
                desktop: 28,
              ),
              backgroundColor: Colors.grey[300],
              backgroundImage: sender?['profilePic'] != null &&
                      sender!['profilePic'] != 'default-profile-pic-url'
                  ? NetworkImage(sender['profilePic'])
                  : null,
              child: sender?['profilePic'] == null ||
                      sender?['profilePic'] == 'default-profile-pic-url'
                  ? Text(
                      (sender?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 16,
                          largeTablet: 18,
                          desktop: 20,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 8,
                tablet: 12,
                largeTablet: 16,
                desktop: 20,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                vertical: GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 12,
                  tablet: 16,
                  largeTablet: 20,
                  desktop: 24,
                ),
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(
                    context,
                    mobile: 20,
                    tablet: 24,
                    largeTablet: 28,
                    desktop: 32,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 20,
                        largeTablet: 22,
                        desktop: 26,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(
                      context,
                      mobile: 4,
                      tablet: 6,
                      largeTablet: 8,
                      desktop: 10,
                    ),
                  ),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 16,
                        largeTablet: 18,
                        desktop: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 8,
                tablet: 12,
                largeTablet: 16,
                desktop: 20,
              ),
            ),
            CircleAvatar(
              radius: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 16,
                tablet: 20,
                largeTablet: 24,
                desktop: 28,
              ),
              backgroundColor: AppColors.primaryColor,
              child: Icon(
                Icons.person,
                size: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 24,
                  desktop: 28,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(
        GetResponsiveSize.getResponsivePadding(
          context,
          mobile: 16,
          tablet: 20,
          largeTablet: 24,
          desktop: 28,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 1,
              tablet: 1.5,
              largeTablet: 2,
              desktop: 2.5,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 20,
                    largeTablet: 22,
                    desktop: 26,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(
                      context,
                      mobile: 25,
                      tablet: 30,
                      largeTablet: 35,
                      desktop: 40,
                    ),
                  ),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 16,
                    tablet: 20,
                    largeTablet: 24,
                    desktop: 28,
                  ),
                  vertical: GetResponsiveSize.getResponsivePadding(
                    context,
                    mobile: 12,
                    tablet: 16,
                    largeTablet: 20,
                    desktop: 24,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 20,
                  largeTablet: 22,
                  desktop: 26,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          SizedBox(
            width: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 8,
              tablet: 12,
              largeTablet: 16,
              desktop: 20,
            ),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(
                GetResponsiveSize.getResponsivePadding(
                  context,
                  mobile: 12,
                  tablet: 16,
                  largeTablet: 20,
                  desktop: 24,
                ),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 20,
                  tablet: 26,
                  largeTablet: 30,
                  desktop: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    print('📤 Sending message: $text');
    _messageController.clear();

    // Dispatch event to Bloc
    context.read<ChatBloc>().add(SendMessage(text));
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleBackNavigation() {
    print('🔙 Navigating back from chat page');
    print('📍 From page: ${widget.fromPage}');

    // Always navigate back to chat rooms page
    // Pass the fromPage parameter so chat rooms knows where to go back
    print('💬 Navigating to chat rooms page');
    final fromPage = widget.fromPage ?? 'home';
    context.go('/chat-rooms?from=$fromPage');
  }

  @override
  void dispose() {
    print('🧹 Disposing chat page for room: ${widget.roomId}');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
