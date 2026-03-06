import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_state.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/repositories/chat_repository.dart';
import 'package:ado_dad_user/repositories/add_repo.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:dio/dio.dart';

class ChatPage extends StatefulWidget {
  final String roomId;
  final String? otherUserName;
  final String? otherUserProfilePic;
  final String? otherUserPhone;
  final String? fromPage; // Track where user came from
  final String? adId; // Ad ID for this chat
  final String? adTitle; // Ad title for this chat

  const ChatPage({
    super.key,
    required this.roomId,
    this.otherUserName,
    this.otherUserProfilePic,
    this.otherUserPhone,
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

  /// Staged images to send when user taps Send (each: bytes + mime type).
  final List<List<int>> _stagedImagesBytes = [];
  final List<String> _stagedImagesMimeTypes = [];

  /// Inline voice note: hold to record, release to preview; send only when Send is tapped.
  final AudioRecorder _voiceRecorder = AudioRecorder();
  bool _isRecordingVoice = false;
  String? _voiceRecordPath;
  Timer? _voiceRecordTimer;
  int _voiceRecordDurationSeconds = 0;
  bool? _hasMicPermission;

  /// Staged voice (path + duration) for preview before send. Send via Send button.
  String? _stagedVoicePath;
  int _stagedVoiceDurationSeconds = 0;
  final just_audio.AudioPlayer _stagedVoicePlayer = just_audio.AudioPlayer();
  bool _stagedVoicePlaying = false;

  /// Which chat audio message is currently playing (by url). Stops others when one starts.
  String? _playingAudioMessageUrl;

  @override
  void initState() {
    super.initState();
    print('🚀 Chat page initialized for room: ${widget.roomId}');
    print('👤 Other user: ${widget.otherUserName}');
    print('🖼️ Profile pic: ${widget.otherUserProfilePic}');
    print('📞 Phone: ${widget.otherUserPhone}');
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
    _stagedVoicePlayer.playerStateStream.listen((state) {
      if (state.processingState == just_audio.ProcessingState.completed) {
        if (mounted) setState(() => _stagedVoicePlaying = false);
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
              child: GestureDetector(
                onTap: widget.adId != null ? () => _navigateToAdDetail() : null,
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
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
          if (widget.otherUserPhone != null &&
              widget.otherUserPhone!.trim().isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.phone,
                size: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 22,
                  tablet: 28,
                  largeTablet: 32,
                  desktop: 36,
                ),
              ),
              onPressed: _callUser,
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
    final type = message['type'] ?? 'text';
    final attachments = (message['attachments'] as List<dynamic>?) ?? [];
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
                  _buildMessageContent(
                    type: type,
                    content: content,
                    attachments: attachments,
                    isMe: isMe,
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

  Widget _buildMessageContent({
    required String type,
    required String content,
    required List<dynamic> attachments,
    required bool isMe,
  }) {
    if (type == 'image' && attachments.isNotEmpty) {
      final att = attachments.first as Map<String, dynamic>;
      final url = att['url'] as String?;
      if (url != null && url.isNotEmpty) {
        return GestureDetector(
          onTap: () => _openImageFullScreen(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 48),
            ),
          ),
        );
      }
    }
    if (type == 'audio' && attachments.isNotEmpty) {
      final att = attachments.first as Map<String, dynamic>;
      final url = att['url'] as String?;
      final mimeType = att['mimeType'] as String?;
      if (url != null && url.isNotEmpty) {
        return _AudioMessagePlayer(
          url: url,
          isMe: isMe,
          mimeType: mimeType,
          currentlyPlayingUrl: _playingAudioMessageUrl,
          onPlayingUrlChanged: (url) =>
              setState(() => _playingAudioMessageUrl = url),
        );
      }
    }
    return Text(
      content.isNotEmpty ? content : '',
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
    );
  }

  void _openImageFullScreen(String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Photo'),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_stagedVoicePath != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _stagedVoicePlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppColors.primaryColor,
                      size: 36,
                    ),
                    onPressed: _toggleStagedVoicePlay,
                  ),
                  Text(
                    _formatVoiceDuration(_stagedVoiceDurationSeconds),
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        largeTablet: 18,
                        desktop: 20,
                      ),
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                    onPressed: _clearStagedVoice,
                    tooltip: 'Delete recording',
                  ),
                ],
              ),
            ),
          ],
          if (_stagedImagesBytes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stagedImagesBytes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      alignment: Alignment.topRight,
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            Uint8List.fromList(_stagedImagesBytes[index]),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _stagedImagesBytes.removeAt(index);
                              _stagedImagesMimeTypes.removeAt(index);
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primaryColor,
                  size: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 26,
                    tablet: 30,
                    largeTablet: 32,
                    desktop: 36,
                  ),
                ),
                onPressed: _showAttachOptions,
              ),
              SizedBox(
                width: GetResponsiveSize.getResponsiveSize(
                  context,
                  mobile: 4,
                  tablet: 8,
                  largeTablet: 12,
                  desktop: 16,
                ),
              ),
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
              if (_stagedImagesBytes.isEmpty && _stagedVoicePath == null) ...[
                SizedBox(
                  width: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 4,
                    tablet: 8,
                    largeTablet: 12,
                    desktop: 16,
                  ),
                ),
                GestureDetector(
                  onLongPressStart: (_) => _startVoiceRecording(),
                  onLongPressEnd: (_) => _stopVoiceRecording(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.mic,
                      color: _isRecordingVoice
                          ? Colors.red
                          : AppColors.primaryColor,
                      size: GetResponsiveSize.getResponsiveSize(
                        context,
                        mobile: 26,
                        tablet: 30,
                        largeTablet: 32,
                        desktop: 36,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: GetResponsiveSize.getResponsiveSize(
                    context,
                    mobile: 4,
                    tablet: 8,
                    largeTablet: 12,
                    desktop: 16,
                  ),
                ),
              ],
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
        ],
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndStageImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Image from camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndStageImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startVoiceRecording() async {
    if (_hasMicPermission == false) return;
    if (_hasMicPermission != true) {
      final granted = await _voiceRecorder.hasPermission();
      if (!mounted) return;
      setState(() => _hasMicPermission = granted);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Microphone access is needed to record.')),
          );
        }
        return;
      }
    }
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(
          dir.path, 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _voiceRecorder.start(
          const RecordConfig(
              encoder: AudioEncoder.aacLc,
              sampleRate: 44100,
              numChannels: 1,
              bitRate: 64000),
          path: path);
      if (!mounted) return;
      setState(() {
        _isRecordingVoice = true;
        _voiceRecordPath = path;
        _voiceRecordDurationSeconds = 0;
      });
      _voiceRecordTimer?.cancel();
      _voiceRecordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _voiceRecordDurationSeconds += 1);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    _voiceRecordTimer?.cancel();
    _voiceRecordTimer = null;
    final duration = _voiceRecordDurationSeconds;
    final path = _voiceRecordPath;
    if (!mounted) return;
    setState(() {
      _isRecordingVoice = false;
      _voiceRecordPath = null;
    });
    try {
      if (duration < 1) {
        await _voiceRecorder.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Hold longer to record (at least 1 second)')),
          );
        }
        return;
      }
      await _voiceRecorder.stop();
    } catch (_) {}
    if (path == null || !mounted) return;
    setState(() {
      _stagedVoicePath = path;
      _stagedVoiceDurationSeconds = duration;
    });
  }

  void _clearStagedVoice() {
    _stagedVoicePlayer.stop();
    setState(() {
      _stagedVoicePlaying = false;
      _stagedVoicePath = null;
    });
  }

  Future<void> _toggleStagedVoicePlay() async {
    final path = _stagedVoicePath;
    if (path == null) return;
    if (_stagedVoicePlaying) {
      await _stagedVoicePlayer.pause();
      if (mounted) setState(() => _stagedVoicePlaying = false);
    } else {
      try {
        await _stagedVoicePlayer.setFilePath(path);
        await _stagedVoicePlayer.play();
        if (mounted) setState(() => _stagedVoicePlaying = true);
      } catch (_) {
        if (mounted) setState(() => _stagedVoicePlaying = false);
      }
    }
  }

  void _sendStagedVoice() {
    final path = _stagedVoicePath;
    if (path == null) return;
    final file = File(path);
    file.exists().then((exists) {
      if (!exists || !mounted) return;
      file.readAsBytes().then((bytes) async {
        if (!mounted) return;
        await _stagedVoicePlayer.stop();
        setState(() {
          _stagedVoicePath = null;
          _stagedVoicePlaying = false;
        });
        context.read<ChatBloc>().add(SendMessage('',
            type: 'audio',
            roomId: widget.roomId,
            fileBytes: bytes,
            mimeType: 'audio/m4a',
            attachmentType: 'audio'));
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send voice note: $e')),
          );
        }
      });
    });
  }

  Future<void> _pickAndStageImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await picker.pickMultiImage(imageQuality: 85);
      } else {
        final xFile = await picker.pickImage(source: source, imageQuality: 85);
        picked = xFile != null ? [xFile] : [];
      }
      if (picked.isEmpty || !mounted) return;
      final toAddBytes = <List<int>>[];
      final toAddMimes = <String>[];
      for (final xFile in picked) {
        final bytes = await xFile.readAsBytes();
        final mimeType = 'image/${xFile.path.split('.').last.toLowerCase()}';
        toAddMimes.add(mimeType == 'image/jpg' ? 'image/jpeg' : mimeType);
        toAddBytes.add(bytes);
      }
      if (!mounted) return;
      setState(() {
        _stagedImagesBytes.addAll(toAddBytes);
        _stagedImagesMimeTypes.addAll(toAddMimes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  void _sendStagedImages() {
    if (_stagedImagesBytes.isEmpty) return;
    final bytesList = List<List<int>>.from(_stagedImagesBytes);
    final mimesList = List<String>.from(_stagedImagesMimeTypes);
    setState(() {
      _stagedImagesBytes.clear();
      _stagedImagesMimeTypes.clear();
    });
    for (var i = 0; i < bytesList.length; i++) {
      context.read<ChatBloc>().add(SendMessage('',
          type: 'image',
          roomId: widget.roomId,
          fileBytes: bytesList[i],
          mimeType: mimesList[i],
          attachmentType: 'image'));
    }
  }

  void _sendMessage() {
    // If there is a staged voice note, send it and return.
    if (_stagedVoicePath != null) {
      _sendStagedVoice();
      return;
    }
    // If there are staged images, send them and return.
    if (_stagedImagesBytes.isNotEmpty) {
      _sendStagedImages();
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    print('📤 Sending message: $text');
    _messageController.clear();

    // Dispatch event to Bloc
    context.read<ChatBloc>().add(SendMessage(text));
  }

  String _formatVoiceDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

  Future<void> _callUser() async {
    final rawPhone = widget.otherUserPhone?.trim() ?? '';
    if (rawPhone.isEmpty) return;

    // Copy to clipboard for user convenience
    await Clipboard.setData(ClipboardData(text: rawPhone));

    final uri = Uri(scheme: 'tel', path: rawPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone app')),
      );
    }
  }

  Future<void> _navigateToAdDetail() async {
    if (widget.adId == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch ad details
      final repository = AddRepository();
      final ad = await repository.fetchAdDetail(widget.adId!);

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to ad detail page
      if (mounted) {
        context.push('/add-detail-page', extra: ad);
      }
    } catch (e) {
      // Close loading indicator if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load ad details: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade300.withOpacity(0.9),
          ),
        );
      }
      print('❌ Error fetching ad details: $e');
    }
  }

  @override
  void dispose() {
    print('🧹 Disposing chat page for room: ${widget.roomId}');
    _voiceRecordTimer?.cancel();
    _voiceRecorder.dispose();
    _stagedVoicePlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Inline audio player for chat audio messages (WhatsApp-style progress, single active voice).
class _AudioMessagePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  final String? mimeType;
  final String? currentlyPlayingUrl;
  final void Function(String?) onPlayingUrlChanged;

  const _AudioMessagePlayer({
    required this.url,
    required this.isMe,
    this.mimeType,
    required this.currentlyPlayingUrl,
    required this.onPlayingUrlChanged,
  });

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  /// URL we have already loaded (so we can resume from pause without re-downloading).
  String? _loadedUrl;
  StreamSubscription<just_audio.PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  Duration _position = Duration.zero;
  Duration? _duration;

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AudioMessagePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another voice started playing — stop this one.
    if (widget.currentlyPlayingUrl != null &&
        widget.currentlyPlayingUrl != widget.url &&
        (_playing || _loadedUrl == widget.url)) {
      _player.stop();
      if (mounted) setState(() {
        _playing = false;
        _loadedUrl = null;
      });
    }
  }

  /// Download remote audio to a temp file and play locally. Avoids streaming issues on some devices.
  Future<String?> _downloadToTempFile(String url) async {
    final dir = await getTemporaryDirectory();
    final ext = url.toLowerCase().contains('.webm') ? 'webm' : 'm4a';
    final path = p.join(dir.path, 'chat_audio_${DateTime.now().millisecondsSinceEpoch}.$ext');
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null) return null;
    final file = File(path);
    await file.writeAsBytes(response.data!);
    return path;
  }

  void _handlePlaybackError() {
    if (mounted) {
      setState(() {
        _playing = false;
        _loading = false;
        _loadedUrl = null;
      });
      widget.onPlayingUrlChanged(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio playback failed. The file may be unsupported or unavailable.')),
      );
    }
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(1)}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      widget.onPlayingUrlChanged(null);
      return;
    }
    // Resume from pause: same URL already loaded, just play from current position.
    if (_loadedUrl == widget.url) {
      await _player.play();
      if (mounted) {
        setState(() => _playing = true);
        widget.onPlayingUrlChanged(widget.url);
      }
      return;
    }
    final url = widget.url;
    final isRemote = url.startsWith('http://') || url.startsWith('https://');
    if (mounted) setState(() => _loading = true);
    try {
      String? path;
      if (isRemote) {
        path = await _downloadToTempFile(url);
        if (!mounted) return;
        if (path == null) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load audio.')),
          );
          return;
        }
      } else {
        path = url;
      }
      await _player.setAudioSource(just_audio.AudioSource.file(path));
      await _player.play();
      if (mounted) {
        setState(() {
          _playing = true;
          _loading = false;
          _loadedUrl = widget.url;
        });
        widget.onPlayingUrlChanged(widget.url);
      }
    } catch (e) {
      _handlePlaybackError();
    }
  }

  @override
  void initState() {
    super.initState();
    _stateSub = _player.playerStateStream.listen((state) async {
      if (!mounted) return;
      if (state.playing && _loading) {
        setState(() => _loading = false);
      }
      if (state.processingState == just_audio.ProcessingState.completed) {
        await _player.stop();
        if (!mounted) return;
        setState(() {
          _playing = false;
          _position = Duration.zero;
          _loadedUrl = null;
        });
        widget.onPlayingUrlChanged(null);
      }
    });
    _positionSub = _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSub = _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _duration?.inMilliseconds ?? 0;
    final posMs = _position.inMilliseconds;
    final progress = totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final fg = widget.isMe ? Colors.white : AppColors.primaryColor;
    final fg70 = widget.isMe ? Colors.white70 : Colors.black54;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: _loading ? fg.withOpacity(0.6) : fg,
              size: 40,
            ),
            // Keep button enabled when playing so user can pause; disable only while loading (and not yet playing).
            onPressed: (_loading && !_playing) ? null : _togglePlay,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WhatsApp-style progress bar (based on position/duration when playing)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _playing ? progress : (_loading ? null : progress),
                    backgroundColor: fg70.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (_playing || _position > Duration.zero)
                      ? '${_formatDuration(_position)} / ${_duration != null ? _formatDuration(_duration!) : '--'}'
                      : _loading
                          ? 'Loading...'
                          : _duration != null
                              ? '${_formatDuration(_position)} / ${_formatDuration(_duration!)}'
                              : 'Audio',
                  style: TextStyle(
                    color: fg70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
