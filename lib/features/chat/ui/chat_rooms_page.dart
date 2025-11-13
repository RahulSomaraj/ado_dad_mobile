import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
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

  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Store ChatBloc reference
    _chatBloc = context.read<ChatBloc>();
    // Initialize chat when page loads - use addPostFrameCallback to ensure context is ready
    print('🚀 Chat rooms page initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        // Always initialize/load fresh data when page opens
        // This fixes the issue where the bloc might be stuck in Loading or Error state
        // from a previous session when the app is reopened
        final currentState = _chatBloc.state;
        print('📊 Current chat state: ${currentState.runtimeType}');

        if (currentState is ChatErrorState ||
            currentState is ChatInitial ||
            currentState is ChatLoading) {
          // If in error, initial, or loading state (might be stuck from previous session),
          // do a full initialization to ensure WebSocket connection is established
          // This is especially important after app restart
          print(
              '🔄 Full initialization needed (state: ${currentState.runtimeType})');
          _chatBloc.add(InitializeChat());
        } else if (currentState is MessagesLoaded ||
            currentState is ChatRoomJoined ||
            currentState is ChatRoomCreated ||
            currentState is NewMessageReceivedState) {
          // When returning from chat page, these states indicate we need to reload rooms
          print('🔄 Returning from chat page, reloading chat rooms');
          _chatBloc.add(LoadChatRooms());
        } else if (currentState is! ChatRoomsSuccess) {
          // For any other state, reload rooms
          print('🔄 Loading chat rooms');
          _chatBloc.add(LoadChatRooms());
        } else {
          print('✅ Chat rooms already loaded');
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When page becomes visible again (e.g., returning from chat page),
    // refresh the chat rooms list to show any updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasInitialized) {
        final currentState = _chatBloc.state;
        // If we're in a state from chat page (MessagesLoaded, ChatRoomJoined, etc.)
        // or if rooms haven't been loaded, trigger a reload
        if (currentState is MessagesLoaded ||
            currentState is ChatRoomJoined ||
            currentState is ChatRoomCreated ||
            currentState is NewMessageReceivedState) {
          print('🔄 Page visible again, reloading chat rooms');
          _chatBloc.add(LoadChatRooms());
        } else if (currentState is ChatErrorState) {
          print('🔄 Error state detected, attempting to reload');
          _chatBloc.add(LoadChatRooms());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This callback runs every time build is called, so we need to be careful
    // We only want to reload if we're in a bad state and not already loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasInitialized) {
        final currentState = _chatBloc.state;
        // Only trigger reload if in error state (to allow retry)
        // Don't reload if already loading or if we have success
        if (currentState is ChatErrorState) {
          print('🔄 Detected error state, attempting to reload');
          _chatBloc.add(LoadChatRooms());
        }
      }
    });

    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // System already handled the pop
        _handleBackNavigation(); // Use our custom navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Chats',
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(
                context,
                mobile: 20,
                tablet: 24,
                largeTablet: 28,
                desktop: 32,
              ),
            ),
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
        ),
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 30),
          child: BlocListener<ChatBloc, ChatState>(
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

                // Handle states from chat page - trigger reload and show loading
                if (state is MessagesLoaded ||
                    state is ChatRoomJoined ||
                    state is ChatRoomCreated ||
                    state is NewMessageReceivedState) {
                  // Trigger reload if we're in a chat-related state
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      print(
                          '🔄 Triggering chat rooms reload from ${state.runtimeType} state');
                      context.read<ChatBloc>().add(LoadChatRooms());
                    }
                  });
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // For any other state (including ChatInitial), show loading
                // and trigger load if not already loading
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && state is! ChatLoading) {
                    print('🔄 Triggering initial chat rooms load');
                    context.read<ChatBloc>().add(LoadChatRooms());
                  }
                });

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
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
              onPressed: () {
                // Retry with full initialization if connection might be lost
                context.read<ChatBloc>().add(InitializeChat());
              },
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

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 16,
            tablet: 24,
            largeTablet: 32,
            desktop: 40,
          ),
          vertical: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 8,
            tablet: 12,
            largeTablet: 16,
            desktop: 20,
          ),
        ),
        leading: CircleAvatar(
          radius: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 28,
            tablet: 36,
            largeTablet: 42,
            desktop: 48,
          ),
          backgroundColor: Colors.grey[300],
          backgroundImage: otherUser?['profilePic'] != null &&
                  otherUser!['profilePic'] != 'default-profile-pic-url'
              ? NetworkImage(otherUser['profilePic'])
              : null,
          child: otherUser?['profilePic'] == null ||
                  otherUser!['profilePic'] == 'default-profile-pic-url'
              ? Text(
                  (otherUser?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(
                      context,
                      mobile: 20,
                      tablet: 24,
                      largeTablet: 28,
                      desktop: 32,
                    ),
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
                otherUser?['name'] ?? 'Unknown User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 20,
                    largeTablet: 24,
                    desktop: 28,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 16,
                  largeTablet: 18,
                  desktop: 20,
                ),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Text(
          lastMessage,
          style: TextStyle(
            fontSize: GetResponsiveSize.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 18,
              largeTablet: 20,
              desktop: 24,
            ),
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
      // If came from ad detail page (via chat page), go to home
      context.go('/home');
    } else {
      // Default fallback - check if we can pop, otherwise go to home
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    // Don't dispose ChatBloc as it's global and shared across pages
    super.dispose();
  }
}
