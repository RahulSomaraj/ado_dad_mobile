class ChatItem {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String profileUrl;

  ChatItem({
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.profileUrl,
  });
}
