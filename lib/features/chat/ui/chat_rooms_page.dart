import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';
import 'package:go_router/go_router.dart';

class ChatRoomsPage extends StatefulWidget {
  final String? fromPage; // Track where user came from
  const ChatRoomsPage({super.key, this.fromPage});

  @override
  State<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    // Store ChatBloc reference
    _chatBloc = context.read<ChatBloc>();
    // Initialize chat when page loads
    print('🚀 Chat rooms page initialized');
    _chatBloc.add(InitializeChat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload chat rooms when returning to this page
    print('🔄 Chat rooms page dependencies changed - reloading rooms');
    if (mounted) {
      context.read<ChatBloc>().add(LoadChatRooms());
    }
  }

  @override
  void didUpdateWidget(ChatRoomsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force reload when widget updates (e.g., when returning from chat page)
    print('🔄 Chat rooms page widget updated - force reloading rooms');
    if (mounted) {
      context.read<ChatBloc>().add(LoadChatRooms());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger a reload if we're not in a success state
    final chatBloc = context.read<ChatBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentState = chatBloc.state;
        if (currentState is! ChatRoomsSuccess) {
          print(
              '🔄 Chat rooms page build - triggering reload (current state: ${currentState.runtimeType})');
          chatBloc.add(LoadChatRooms());
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(),
        ),
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatRoomJoined) {
            print('✅ Room joined successfully: ${state.roomId}');

            // Load messages for the joined room
            context.read<ChatBloc>().add(LoadRoomMessages(state.roomId));
          } else if (state is MessagesLoaded) {
            print(
                '✅ Messages loaded: ${state.messages.length} messages for room ${state.roomId}');
          } else if (state is ChatErrorState) {
            print('❌ Error: ${state.error}');
          }
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ChatErrorState) {
              return _buildErrorState(state.error);
            }

            if (state is ChatRoomsSuccess) {
              return _buildRoomsList(state.rooms);
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Connection Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<ChatBloc>().add(LoadChatRooms()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        print('🔄 Manual refresh triggered');
        context.read<ChatBloc>().add(LoadChatRooms());
      },
      child: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final timestamp = room['timestamp'] as DateTime;
    final otherUser = room['otherUser'] as Map<String, dynamic>?;
    final lastMessage = room['lastMessage'] as String;
    final adId = room['adId'] as String?;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          backgroundImage: otherUser?['profilePic'] != null &&
                  otherUser!['profilePic'] != 'default-profile-pic-url'
              ? NetworkImage(otherUser['profilePic'])
              : null,
          child: otherUser?['profilePic'] == null ||
                  otherUser!['profilePic'] == 'default-profile-pic-url'
              ? Text(
                  (otherUser?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                room['adTitle'] ?? 'Ad #${adId ?? 'Unknown'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          // Navigate to chat page
          final roomId = room['id'] as String;
          final otherUser = room['otherUser'] as Map<String, dynamic>?;
          final otherUserName = otherUser?['name'] ?? 'Chat';
          final otherUserProfilePic = otherUser?['profilePic'];
          final adId = room['adId'] as String?;
          final adTitle = room['adTitle'] as String?;

          print('🖱️ Navigating to chat page for room: $roomId');
          print('👤 Other user: $otherUserName');
          print('🏷️ Ad ID: $adId');
          print('📝 Ad Title: $adTitle');
          print('📍 From page: ${widget.fromPage}');

          // Build query parameters
          final queryParams = <String, String>{
            'name': otherUserName,
            'profilePic': otherUserProfilePic ?? '',
          };

          // Add adId parameter if available
          if (adId != null) {
            queryParams['adId'] = adId;
          }

          // Add adTitle parameter if available
          if (adTitle != null) {
            queryParams['adTitle'] = adTitle;
          }

          // Add fromPage parameter if available
          if (widget.fromPage != null) {
            queryParams['from'] = widget.fromPage!;
          }

          // Build query string
          final queryString = queryParams.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');

          context.push('/chat/$roomId?$queryString');
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
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

  void _handleBackNavigation() {
    // Use the fromPage parameter to determine where to go back
    print('🔙 Navigating back from: ${widget.fromPage}');

    // Navigate back to the appropriate page based on fromPage
    if (widget.fromPage == 'profile') {
      context.go('/profile');
    } else if (widget.fromPage == 'home') {
      context.go('/home');
    } else if (widget.fromPage == 'ad-detail') {
      // If came from ad detail page, go to home
      context.go('/home');
    } else {
      // Default fallback
      context.pop();
    }
  }

  @override
  void dispose() {
    // Don't dispose ChatBloc as it's global and shared across pages
    super.dispose();
  }
}
