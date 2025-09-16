import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';

class MessagesPage extends StatefulWidget {
  final String? previousRoute;
  const MessagesPage({super.key, this.previousRoute});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _search = TextEditingController();
  List<ChatThread> _filteredRooms = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(_applyFilter);

    // Load chat rooms when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const ChatEvent.getUserChatRooms());
    });
  }

  @override
  void dispose() {
    _search.removeListener(_applyFilter);
    _search.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    final state = context.read<ChatBloc>().state;

    setState(() {
      if (q.isEmpty) {
        _filteredRooms = List.of(state.chatRooms);
      } else {
        _filteredRooms = state.chatRooms.where((room) {
          return room.participantIds.any(
                  (participant) => participant.toLowerCase().contains(q)) ||
              room.id.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _search.clear();
    FocusScope.of(context).unfocus();
  }

  void _refreshChatRooms() {
    context.read<ChatBloc>().add(const ChatEvent.getUserChatRooms());
  }

  void _handleBackNavigation() {
    // If previousRoute is provided, navigate to that specific route
    if (widget.previousRoute != null) {
      context.go(widget.previousRoute!);
    } else {
      // Fallback to pop if no previous route is specified
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            // Update filtered rooms when state changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_filteredRooms.length != state.chatRooms.length) {
                _applyFilter();
              }
            });

            return Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _handleBackNavigation,
                        icon: const Icon(Icons.arrow_back, size: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Messages (${state.chatRooms.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _refreshChatRooms,
                        icon: state.isLoadingChatRooms
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search conversations',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearSearch,
                            ),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF4F4F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildChatRoomsList(state),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatRoomsList(ChatState state) {
    if (state.isLoadingChatRooms) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chat rooms...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading chat rooms',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshChatRooms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredRooms.isEmpty) {
      return const _EmptyResults();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshChatRooms();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.separated(
        itemCount: _filteredRooms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final room = _filteredRooms[index];
          return ChatRoomTile(
            room: room,
            onTap: () => context.push('/chat/${room.id}', extra: room),
          );
        },
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by making an offer on an ad',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatRoomTile extends StatelessWidget {
  const ChatRoomTile({super.key, required this.room, this.onTap});

  final ChatThread room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = Colors.white;

    // Extract information from the API response
    final otherUser = room.otherUser;
    final latestMessage = room.latestMessage;
    final lastMessageAt = room.lastMessageAt;
    final adDetails = room.adDetails;
    final isActive = room.status == 'active';

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Profile picture circle avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: otherUser?.profilePic != null
                    ? NetworkImage(otherUser!.profilePic!)
                    : null,
                child: otherUser?.profilePic == null
                    ? Icon(
                        Icons.person,
                        color: Colors.grey.shade600,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and timestamp
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // otherUser?.name ?? 'Unknown User',
                            adDetails?.title ?? 'Unknown Ad',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(lastMessageAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8E8E93),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Latest message and unread count
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            latestMessage?.content ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (room.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: room.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3C5BFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
