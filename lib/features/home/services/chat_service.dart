// Ad detail → chat entry (Chat / Make an offer). Uses the new chat stack:
// one idempotent get-or-create call, then the thread page with the room as
// `extra` (F-15, F-23). No socket round-trips or room-exists checks.

import 'package:ado_dad_user/features/chat/data/chat_models.dart';
import 'package:ado_dad_user/features/chat/data/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatService {
  /// Kept for existing callers (ad detail page). [otherUserId] etc. are no
  /// longer needed — the server resolves the seller from the ad.
  static Future<void> startDirectChat({
    required BuildContext context,
    required String adId,
    required String adTitle,
    required String adPosterName,
    required String otherUserId,
  }) =>
      openChatForAd(context, adId: adId);

  /// Get-or-create the room for [adId], optionally queue [initialMessage]
  /// (optimistic, retried by the outbox), then open the thread.
  static Future<ChatRoom?> openChatForAd(
    BuildContext context, {
    required String adId,
    String? initialMessage,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    var dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ).whenComplete(() => dialogOpen = false);

    void closeDialog() {
      if (dialogOpen && navigator.mounted) navigator.pop();
      dialogOpen = false;
    }

    try {
      final room = await ChatRepository.instance.openChatForAd(adId);
      closeDialog();
      final text = initialMessage?.trim();
      if (text != null && text.isNotEmpty) {
        ChatRepository.instance.sendText(room.roomId, text);
      }
      if (context.mounted) {
        context.push('/chat/${Uri.encodeComponent(room.roomId)}', extra: room);
      }
      return room;
    } on ChatFailure catch (f) {
      closeDialog();
      messenger?.showSnackBar(SnackBar(
        content: Text(_openError(f)),
        behavior: SnackBarBehavior.floating,
      ));
      return null;
    }
  }

  static String _openError(ChatFailure f) => switch (f.kind) {
        ChatFailureKind.offline || ChatFailureKind.timeout =>
          'You\'re offline. Check your connection and try again.',
        ChatFailureKind.closed || ChatFailureKind.notFound =>
          'This ad is no longer available for chat.',
        ChatFailureKind.invalid => f.serverMessage ?? 'You can\'t chat about this ad.',
        ChatFailureKind.session => 'Your session ended. Log in again to chat.',
        ChatFailureKind.suspended => 'Your account can\'t start chats right now.',
        ChatFailureKind.rateLimited => 'Too many chats opened. Try again in a minute.',
        _ => 'Couldn\'t open the chat. Try again.',
      };
}
