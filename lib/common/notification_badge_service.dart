import 'package:flutter/foundation.dart';

/// Single notification item for display in the bottom sheet.
class NotificationItem {
  final String title;
  final String body;
  final DateTime receivedAt;

  NotificationItem({
    required this.title,
    required this.body,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
}

/// Tracks unread notification state and list of received notifications.
class NotificationBadgeService {
  static final ValueNotifier<bool> hasUnread = ValueNotifier(false);
  static final ValueNotifier<List<NotificationItem>> notificationsList =
      ValueNotifier([]);

  static void markAsUnread() {
    hasUnread.value = true;
  }

  static void markAsRead() {
    hasUnread.value = false;
  }

  static void addNotification({
    required String title,
    required String body,
  }) {
    final item = NotificationItem(title: title, body: body);
    notificationsList.value = [item, ...notificationsList.value];
    markAsUnread();
  }

  /// Read state for API notifications (list page): opened vs not opened.
  static final ValueNotifier<Set<String>> readNotificationIds =
      ValueNotifier(<String>{});

  static void markNotificationAsRead(String id) {
    if (id.isEmpty) return;
    readNotificationIds.value = {...readNotificationIds.value, id};
  }

  static bool isNotificationRead(String id) =>
      readNotificationIds.value.contains(id);
}
