// User-facing copy for chat failures. Never show raw exceptions (audit screen 04).

import '../data/chat_models.dart';

class ChatCopy {
  static String listErrorTitle(ChatFailure? f) => switch (f?.kind) {
        ChatFailureKind.session => 'Log in to see your chats',
        ChatFailureKind.suspended => 'Chat is unavailable for your account',
        _ => 'Couldn\'t load your chats',
      };

  static String listErrorBody(ChatFailure? f) => switch (f?.kind) {
        ChatFailureKind.offline => 'You\'re offline. Check your mobile data or Wi-Fi, then try again.',
        ChatFailureKind.timeout => 'This is taking too long. Check your connection and try again.',
        ChatFailureKind.server => 'Chats are having trouble right now. Try again in a minute.',
        ChatFailureKind.session => 'Your session ended. Log in again to continue.',
        ChatFailureKind.suspended => 'Contact support if you think this is a mistake.',
        _ => 'Something went wrong. Try again.',
      };

  static String threadErrorTitle(ChatFailure? f) => switch (f?.kind) {
        ChatFailureKind.notFound => 'This conversation doesn\'t exist',
        ChatFailureKind.notParticipant => 'You can\'t open this conversation',
        _ => 'Couldn\'t load messages',
      };

  /// Short reason shown under a failed bubble: "Not sent · {reason}".
  static String failReason(ChatFailure? f) => switch (f?.kind) {
        ChatFailureKind.offline || ChatFailureKind.timeout => 'No connection',
        ChatFailureKind.blocked => 'Message not allowed',
        ChatFailureKind.closed => 'Chat is closed',
        ChatFailureKind.rateLimited => 'Sending too fast',
        ChatFailureKind.invalid when f?.code == 'ATTACHMENT_LOST' => 'File no longer available',
        ChatFailureKind.invalid => 'Couldn\'t send this',
        ChatFailureKind.session => 'Session expired',
        ChatFailureKind.suspended => 'Account restricted',
        _ => 'Something went wrong',
      };

  /// Retry makes sense for transient failures; Edit for policy ones.
  static bool canRetry(ChatFailure? f) => f == null || f.isRetryable || f.kind == ChatFailureKind.unknown;

  static const offlineBanner = 'You\'re offline. Messages send when you\'re back.';
  static const reconnectingBanner = 'Reconnecting…';
  static const sessionBanner = 'Session expired. Log in again to keep chatting.';
  static const suspendedBanner = 'Your account can\'t send messages right now.';
  static const closedComposer = 'This ad is no longer available';
  static const safetyTip = 'Meet in a public place and check the documents before paying. Never pay in advance.';

  static List<String> starters({required bool buying}) => buying
      ? const ['Is it still available?', 'Best price?', 'Can I see it this weekend?', 'Where can I see it?']
      : const ['Yes, it\'s available', 'When can you come?', 'Price is slightly negotiable'];
}
