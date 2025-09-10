import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/app_textstyle.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:ado_dad_user/features/chat/ui/chat_room_page.dart';
import 'package:ado_dad_user/features/chat/ui/widgets/message_bubble.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    // Initialize chat list when page loads
    context.read<ChatBloc>().add(const ChatEvent.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: AppTextstyle.appbarText.copyWith(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.whiteColor),
            onPressed: () {
              context.read<ChatBloc>().add(const ChatEvent.refreshChats());
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => const Center(
              child: CircularProgressIndicator(),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            loaded: (chats) => _buildChatList(chats),
            error: (message) => _buildErrorState(message),
          );
        },
      ),
    );
  }

  Widget _buildChatList(List<ChatSummary> chats) {
    if (chats.isEmpty) {
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
              'No chats yet',
              style: AppTextstyle.categoryLabelTextStyle.copyWith(
                color: AppColors.greyColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by messaging a seller',
              style: AppTextstyle.categoryLabelTextStyle.copyWith(
                color: AppColors.greyColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatBloc>().add(const ChatEvent.refreshChats());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _ChatListItem(
            chat: chat,
            onTap: () => _navigateToChatRoom(chat.id),
          );
        },
      ),
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
            style: AppTextstyle.categoryLabelTextStyle.copyWith(
              color: AppColors.greyColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextstyle.categoryLabelTextStyle.copyWith(
              color: AppColors.greyColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ChatBloc>().add(const ChatEvent.loadChats());
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

  void _navigateToChatRoom(String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(chatId: chatId),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Icon(
            Icons.person,
            color: AppColors.whiteColor,
          ),
        ),
        title: Text(
          'Chat ${chat.id.substring(0, 8)}...',
          style: AppTextstyle.categoryLabelTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.lastMessage != null)
              Text(
                chat.lastMessage!,
                style: AppTextstyle.categoryLabelTextStyle.copyWith(
                  color: AppColors.greyColor,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            if (chat.updatedAt != null)
              Text(
                _formatTimestamp(chat.updatedAt!),
                style: AppTextstyle.categoryLabelTextStyle.copyWith(
                  color: AppColors.greyColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.greyColor,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
