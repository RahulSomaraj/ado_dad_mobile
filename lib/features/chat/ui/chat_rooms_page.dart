import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/widgets/skeleton.dart';
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

  // ---- Search ----
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        if (_isSearching) {
          _stopSearch();
          return;
        }
        _handleBackNavigation(); // Use our custom navigation
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _buildAppBar(),
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
                  return const SkeletonList();
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

  // ---------------------------------------------------------------------------
  // App bar (title + search)
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    final titleFontSize = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: 20,
      tablet: 24,
      largeTablet: 28,
      desktop: 32,
    );
    final iconSize = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 24,
      tablet: 30,
      largeTablet: 32,
      desktop: 36,
    );

    return AppBar(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(
          (!kIsWeb && Platform.isIOS) ? Icons.arrow_back_ios : Icons.arrow_back,
          size: iconSize,
        ),
        onPressed: () {
          if (_isSearching) {
            _stopSearch();
          } else {
            _handleBackNavigation();
          }
        },
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Search messages…',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
            )
          : Text(
              'Messages',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, size: iconSize),
          onPressed: () {
            if (_isSearching) {
              _stopSearch();
            } else {
              setState(() => _isSearching = true);
            }
          },
        ),
      ],
    );
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
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
            Text(
              'Connection Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: AppColors.greyColor),
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
    // Apply search filter (name or last message)
    final filtered = _searchQuery.isEmpty
        ? rooms
        : rooms.where((room) {
            final otherUser = room['otherUser'] as Map<String, dynamic>?;
            final name = (otherUser?['name'] ?? '').toString().toLowerCase();
            final lastMessage =
                (room['lastMessage'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) ||
                lastMessage.contains(_searchQuery);
          }).toList();

    if (rooms.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Conversations with buyers and sellers appear here.',
      );
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No results',
        subtitle: 'No chats match "${_searchController.text.trim()}".',
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: () async {
        print('🔄 Manual refresh triggered');
        context.read<ChatBloc>().add(LoadChatRooms());
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => Divider(
          height: 0.5,
          thickness: 0.5,
          indent: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 67,
            tablet: 87,
            largeTablet: 107,
            desktop: 125,
          ),
          color: AppColors.dividerColor,
        ),
        itemBuilder: (context, index) {
          return _buildRoomCard(filtered[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.greyColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.greyColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final timestamp = room['timestamp'] as DateTime;
    final otherUser = room['otherUser'] as Map<String, dynamic>?;
    final lastMessage = room['lastMessage'] as String;
    final lastMessageType = room['lastMessageType'] as String? ?? 'text';
    final unreadCount = (room['unreadCount'] as int?) ?? 0;
    final hasUnread = unreadCount > 0;
    // Wireframe avatar (.av) is a 42px circle → radius 21.
    final avatarRadius = GetResponsiveSize.getResponsiveSize(
      context,
      mobile: 21,
      tablet: 28,
      largeTablet: 34,
      desktop: 40,
    );

    return InkWell(
      onTap: () => _openRoom(room),
      child: Padding(
        // Wireframe .list-it padding: 11px 14px.
        padding: EdgeInsets.symmetric(
          horizontal: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 14,
            tablet: 22,
            largeTablet: 30,
            desktop: 38,
          ),
          vertical: GetResponsiveSize.getResponsivePadding(
            context,
            mobile: 11,
            tablet: 13,
            largeTablet: 15,
            desktop: 18,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: AppColors.primaryColor.withOpacity(0.12),
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
                        color: AppColors.primaryColor,
                      ),
                    )
                  : null,
            ),
            SizedBox(
              width: GetResponsiveSize.getResponsiveSize(
                context,
                mobile: 11,
                tablet: 15,
                largeTablet: 19,
                desktop: 23,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: name (bold) + time — matches wireframe .list-it top row.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUser?['name'] ?? 'Unknown User',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 13.5,
                              tablet: 18,
                              largeTablet: 22,
                              desktop: 26,
                            ),
                            color: AppColors.blackColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          color: hasUnread
                              ? AppColors.primaryColor
                              : AppColors.greyColor,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Row 2: last-message preview + unread badge — wireframe bottom row.
                  Row(
                    children: [
                      Expanded(
                        child: _buildPreview(
                          lastMessage: lastMessage,
                          lastMessageType: lastMessageType,
                          hasUnread: hasUnread,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        // Accent pill: bg accent, white, 10px, radius 10, padding 1x7.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview({
    required String lastMessage,
    required String lastMessageType,
    required bool hasUnread,
  }) {
    final previewColor =
        hasUnread ? AppColors.blackColor1 : AppColors.greyColor;
    final fontSize = GetResponsiveSize.getResponsiveFontSize(
      context,
      mobile: 12.5,
      tablet: 16,
      largeTablet: 18,
      desktop: 22,
    );
    final fontWeight = hasUnread ? FontWeight.w600 : FontWeight.w400;

    if (lastMessageType == 'image' || lastMessageType == 'audio') {
      final isImage = lastMessageType == 'image';
      return Row(
        children: [
          Icon(
            isImage ? Icons.image : Icons.mic,
            size: GetResponsiveSize.getResponsiveSize(
              context,
              mobile: 16,
              tablet: 20,
              largeTablet: 22,
              desktop: 26,
            ),
            color: previewColor,
          ),
          const SizedBox(width: 6),
          Text(
            isImage ? 'Photo' : 'Voice message',
            style: TextStyle(
              fontSize: fontSize,
              color: previewColor,
              fontWeight: fontWeight,
            ),
          ),
        ],
      );
    }

    return Text(
      lastMessage,
      style: TextStyle(
        fontSize: fontSize,
        color: previewColor,
        fontWeight: fontWeight,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _openRoom(Map<String, dynamic> room) {
    // Resolve the room id defensively. Different sources/payloads may key it
    // differently ('id', 'roomId', '_id'); an empty value cannot be routed to
    // (it would produce '/chat/' which GoRouter can't match) so we stop early
    // with a clear message instead of throwing an unreadable exception.
    final roomId = (room['id'] ?? room['roomId'] ?? room['_id'] ?? '')
        .toString()
        .trim();
    if (roomId.isEmpty) {
      print('❌ Cannot open chat: missing room id in $room');
      _showOpenError('This conversation can’t be opened right now.');
      return;
    }

    final otherUser = room['otherUser'] as Map<String, dynamic>?;
    final otherUserName = otherUser?['name'] ?? 'Chat';
    final otherUserProfilePic = otherUser?['profilePic'];
    final countryCode = otherUser?['countryCode']?.toString().trim();
    final rawPhone = (otherUser?['phoneNumber'] ??
            otherUser?['phone'] ??
            otherUser?['mobile'])
        ?.toString()
        .trim();
    String? otherUserPhone;
    if (rawPhone != null && rawPhone.isNotEmpty) {
      if (countryCode != null && countryCode.isNotEmpty) {
        otherUserPhone = '$countryCode$rawPhone';
      } else {
        otherUserPhone = rawPhone;
      }
    }
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

    // Pass ad price through when the room payload includes it, so the chat
    // page's pinned card can render it without a second network fetch.
    final adPrice = room['adPrice'] as int?;
    if (adPrice != null) {
      queryParams['price'] = adPrice.toString();
    }

    // Add phone parameter if available
    if (otherUserPhone != null && otherUserPhone.toString().trim().isNotEmpty) {
      queryParams['phone'] = otherUserPhone.toString();
    }

    // Add fromPage parameter if available
    if (widget.fromPage != null) {
      queryParams['from'] = widget.fromPage!;
    }

    // Build query string
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    try {
      context.push('/chat/${Uri.encodeComponent(roomId)}?$queryString');
    } catch (e) {
      print('❌ Failed to open chat room $roomId: $e');
      _showOpenError('Could not open this conversation. Please try again.');
    }
  }

  void _showOpenError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.redColor,
        behavior: SnackBarBehavior.floating,
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
    _searchController.dispose();
    // Don't dispose ChatBloc as it's global and shared across pages
    super.dispose();
  }
}
