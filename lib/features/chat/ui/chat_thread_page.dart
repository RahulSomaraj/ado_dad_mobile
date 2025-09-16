import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';
import 'package:ado_dad_user/features/chat/models/chat_models.dart';
import 'package:ado_dad_user/common/shared_pref.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    super.key,
    required this.peerName,
    required this.avatarUrl,
    required this.threadId,
  });

  final String peerName;
  final String avatarUrl;
  final String threadId;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final TextEditingController _composer = TextEditingController();
  late ChatBloc _chatBloc;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Get current user ID
    _currentUserId = await SharedPrefs().getUserId();

    // Connect to socket if not already connected
    if (!_chatBloc.state.isConnected) {
      _chatBloc.add(const ChatEvent.connect());
    }

    // Join the thread
    _chatBloc.add(ChatEvent.joinThread(widget.threadId));

    // Load messages for this thread
    _chatBloc.add(ChatEvent.loadMessages(widget.threadId));
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.avatarUrl)
                  : null,
              child: widget.avatarUrl.isEmpty
                  ? Text(_initials(widget.peerName),
                      style: const TextStyle(fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.peerName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          return Column(
            children: [
              // Connection status indicator
              if (state.connectionState == SocketConnectionState.connecting)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.orange.shade100,
                  child: Text(
                    'Connecting to chat...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                )
              else if (state.connectionState == SocketConnectionState.error)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.red.shade100,
                  child: Text(
                    'Connection error: ${state.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              // Messages list
              Expanded(
                child: state.isLoadingMessages
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: state.currentThreadMessages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) return const _DayChip(label: 'Today');
                          final msg = state.currentThreadMessages[index - 1];
                          final isMe = msg.senderId == _currentUserId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  _Bubble(message: msg, isMe: isMe),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTime(msg.timestamp),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF8E8E93),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Typing indicator
              if (state.currentThreadTypingUsers.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${state.currentThreadTypingUsers.first.userName} is typing...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF8E8E93),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 6),
              _Composer(
                controller: _composer,
                onSend: _handleSend,
                isSending: state.isSendingMessage,
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  void _handleSend(String value) {
    if (value.trim().isEmpty) return;

    // Send message through the chat bloc
    _chatBloc.add(ChatEvent.sendMessage(
      threadId: widget.threadId,
      content: value.trim(),
      messageType: 'text',
    ));

    _composer.clear();
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Show time for today's messages
      final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
      final hourDisplay = hour == 0 ? 12 : hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      return '$hourDisplay:$minute $period';
    } else {
      // Show date for older messages
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final textColor = isMe ? Colors.white : const Color(0xFF111827);
    final radius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .74),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF5A62FF) : const Color(0xFFEFF0FF),
          borderRadius: radius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            message.content,
            style: TextStyle(
              color: textColor,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool isSending;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    if (_hasText && !widget.isSending) {
      widget.onSend(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.add,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: widget.controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  enabled: !widget.isSending,
                  decoration: const InputDecoration(
                    hintText: 'Type your message..',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              onTap: _hasText && !widget.isSending ? _handleSend : null,
              isSending: widget.isSending,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.onTap,
    this.isSending = false,
  });
  final VoidCallback? onTap;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFF5A62FF) : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.onTap,
  });
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7FB),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3C3C43),
        ),
      ),
    );
  }
}
