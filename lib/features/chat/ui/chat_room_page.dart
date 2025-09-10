import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_room_bloc.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:ado_dad_user/features/chat/ui/widgets/message_bubble.dart';
import 'package:ado_dad_user/features/chat/utils/chat_error_handler.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;

  const ChatRoomPage({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Set the chat and load messages
    context.read<ChatRoomBloc>().add(ChatRoomEvent.setChat(widget.chatId));

    // Listen to text changes to update send button state
    _messageController.addListener(() {
      setState(() {
        // Trigger rebuild to update send button state
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat ${widget.chatId.substring(0, 8)}...',
          style: AppTextstyle.appbarText.copyWith(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.whiteColor),
            onPressed: () {
              // Show chat options
              _showChatOptions();
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatRoomBloc, ChatRoomState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (chatId, message) {
              // Reset sending state on error
              setState(() {
                _isSending = false;
              });

              final userFriendlyMessage =
                  ChatErrorHandler.getUserFriendlyMessage(message);
              final isRetryable = ChatErrorHandler.isRetryableError(message);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(userFriendlyMessage),
                  backgroundColor: Colors.red,
                  duration: isRetryable
                      ? const Duration(seconds: 5)
                      : const Duration(seconds: 3),
                  action: isRetryable
                      ? SnackBarAction(
                          label: 'Retry',
                          textColor: AppColors.whiteColor,
                          onPressed: () {
                            context.read<ChatRoomBloc>().add(
                                  ChatRoomEvent.loadMessages(widget.chatId),
                                );
                          },
                        )
                      : null,
                ),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.when(
                  initial: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  loading: (chatId) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  loaded: (chatId, messages, loading) =>
                      _buildMessageList(messages, loading),
                  error: (chatId, message) => _buildErrorState(message),
                ),
              ),
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, bool loading) {
    if (messages.isEmpty && !loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.greyColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: AppTextstyle.appbarText.copyWith(
                color: AppColors.greyColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: AppTextstyle.categoryLabelTextStyle.copyWith(
                color: AppColors.greyColor,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isCurrentUser = message.sender ==
                'current_user'; // This should come from auth provider

            return MessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
            );
          },
        ),
        if (loading)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Loading messages...',
                  style: TextStyle(color: AppColors.whiteColor),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.greyColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTextstyle.appbarText.copyWith(
              color: AppColors.greyColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextstyle.categoryLabelTextStyle.copyWith(
              color: AppColors.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context
                  .read<ChatRoomBloc>()
                  .add(ChatRoomEvent.loadMessages(widget.chatId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.greyColor.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: _canSendMessage()
                  ? AppColors.primaryColor
                  : AppColors.greyColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: AppColors.whiteColor,
                    ),
              onPressed: _canSendMessage() ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSendMessage() {
    return _messageController.text.trim().isNotEmpty && !_isSending;
  }

  void _sendMessage() {
    final message = _messageController.text.trim();

    // Validate message content
    final validationError = ChatErrorHandler.validateMessageContent(message);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (message.isNotEmpty && !_isSending) {
      setState(() {
        _isSending = true;
      });

      context.read<ChatRoomBloc>().add(
            ChatRoomEvent.sendMessage(widget.chatId, message),
          );
      _messageController.clear();
      _scrollToBottom();

      // Reset sending state after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark as read'),
              onTap: () {
                context.read<ChatRoomBloc>().add(
                      ChatRoomEvent.markAsRead(widget.chatId),
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Clear chat'),
              onTap: () {
                context.read<ChatRoomBloc>().add(
                      const ChatRoomEvent.clearChat(),
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
