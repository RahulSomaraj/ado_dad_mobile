// Screens 06–12 — pure view over ChatThreadState.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/chat_models.dart';
import '../state/chat_thread_cubit.dart';
import '../widgets/chat_copy.dart';
import '../widgets/chat_format.dart';
import '../widgets/chat_intro.dart';
import '../widgets/chat_skeletons.dart';
import '../widgets/chat_state_views.dart';
import '../widgets/chat_thread_header.dart';
import '../widgets/chat_tokens.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';

class ChatThreadCallbacks {
  const ChatThreadCallbacks({
    required this.onBack,
    required this.onOpenDetails,
    required this.onOpenAd,
    required this.onRetryLoad,
    required this.onLoadOlder,
    required this.onSendText,
    required this.onSendImages,
    required this.onSendVoice,
    required this.onRetryMessage,
    required this.onEditMessage,
    required this.onDeleteMessage,
    required this.onOpenImage,
    this.onCall,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenAd;
  final VoidCallback onRetryLoad;
  final VoidCallback onLoadOlder;
  final ValueChanged<String> onSendText;
  final void Function(List<PickedChatImage> images, String caption) onSendImages;
  final void Function(Uint8List bytes, String mimeType, int seconds) onSendVoice;
  final ValueChanged<ChatMessage> onRetryMessage;
  final ValueChanged<ChatMessage> onEditMessage;
  final ValueChanged<ChatMessage> onDeleteMessage;
  final ValueChanged<String> onOpenImage;
  final VoidCallback? onCall;
}

class ChatThreadView extends StatelessWidget {
  const ChatThreadView({
    super.key,
    required this.state,
    required this.composerController,
    required this.callbacks,
    this.composerFocus,
    this.fallbackTitle,
  });

  final ChatThreadState state;
  final TextEditingController composerController;
  final FocusNode? composerFocus;
  final ChatThreadCallbacks callbacks;
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final room = state.room;
    final banner = connectionBannerFor(state.connection);
    final online = state.connection == ChatConnectionStatus.online || state.connection == ChatConnectionStatus.connecting;

    return ColoredBox(
      color: c.background,
      child: Column(
        children: [
          ChatThreadHeader(
            room: room,
            fallbackTitle: fallbackTitle,
            onBack: callbacks.onBack,
            onOpenDetails: callbacks.onOpenDetails,
            onCall: callbacks.onCall,
          ),
          if (banner != null) banner,
          if (room?.ad != null) ChatListingStrip(ad: room!.ad!, role: room.myRole, onTap: callbacks.onOpenAd),
          Expanded(child: _body(context, c)),
          if (state.status != ChatThreadStatus.error)
            MessageComposer(
              controller: composerController,
              focusNode: composerFocus,
              closed: state.isClosed,
              attachmentsEnabled: online || state.connection == ChatConnectionStatus.reconnecting,
              onSendText: callbacks.onSendText,
              onSendImages: callbacks.onSendImages,
              onSendVoice: callbacks.onSendVoice,
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ChatColors c) {
    if (state.status == ChatThreadStatus.error && state.messages.isEmpty) {
      return ChatErrorView(
        title: ChatCopy.threadErrorTitle(state.failure),
        body: ChatCopy.listErrorBody(state.failure),
        onRetry: callbacks.onRetryLoad,
      );
    }
    if (state.status == ChatThreadStatus.loading && state.messages.isEmpty) {
      return const BubbleSkeleton();
    }
    if (state.messages.isEmpty && state.room != null && !state.isClosed) {
      return ChatIntro(
        room: state.room!,
        onOpenAd: callbacks.onOpenAd,
        onStarter: (text) {
          composerController
            ..text = text
            ..selection = TextSelection.collapsed(offset: text.length);
          composerFocus?.requestFocus();
        },
      );
    }
    return _MessageList(state: state, callbacks: callbacks);
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state, required this.callbacks});

  final ChatThreadState state;
  final ChatThreadCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final c = ChatColors.of(context);
    final msgs = state.messages; // newest first
    final me = state.myUserId;
    final showTop = state.hasMore || state.loadingOlder || state.olderFailed;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Reversed list: "after" is the top (older messages).
        if (n.metrics.extentAfter < 600 && state.hasMore && !state.loadingOlder && !state.olderFailed) {
          callbacks.onLoadOlder();
        }
        return false;
      },
      child: ListView.builder(
        reverse: true,
        padding: ChatSize.messagesPadding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: msgs.length + (showTop ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == msgs.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: state.olderFailed
                    ? TextButton(
                        onPressed: callbacks.onLoadOlder,
                        child: Text('Couldn\'t load older messages · Retry',
                            style: TextStyle(color: c.brandText, fontSize: ChatSize.failFont)),
                      )
                    : const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          final m = msgs[i];
          final older = i + 1 < msgs.length ? msgs[i + 1] : null;
          final newer = i > 0 ? msgs[i - 1] : null;
          final mine = m.isMine(me);
          final newDay = older == null || !isSameDay(older.createdAt, m.createdAt);
          final sameAsOlder = older != null && !newDay && older.senderId == m.senderId;
          final tail = newer == null || newer.senderId != m.senderId || !isSameDay(newer.createdAt, m.createdAt);

          return Column(
            key: ValueKey(m.key),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (newDay) ChatDateSeparator(date: m.createdAt),
              Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: MessageBubble(
                  message: m,
                  mine: mine,
                  tail: tail,
                  topGap: newDay ? 0 : (sameAsOlder ? ChatSize.sameSenderGap : ChatSize.senderSwitchGap),
                  onRetry: () => callbacks.onRetryMessage(m),
                  onEdit: () => callbacks.onEditMessage(m),
                  onDelete: () => callbacks.onDeleteMessage(m),
                  onOpenImage: callbacks.onOpenImage,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
