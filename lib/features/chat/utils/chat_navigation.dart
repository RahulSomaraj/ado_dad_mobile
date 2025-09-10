import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helper class for chat navigation and deep linking
class ChatNavigation {
  /// Navigate to chat list page
  static void navigateToChatList(BuildContext context) {
    context.go('/chats');
  }

  /// Navigate to specific chat room
  static void navigateToChatRoom(BuildContext context, String chatId) {
    context.go('/chats/$chatId');
  }

  /// Navigate to chat room and replace current route
  static void navigateToChatRoomAndReplace(
      BuildContext context, String chatId) {
    context.go('/chats/$chatId');
  }

  /// Push to chat room (adds to navigation stack)
  static void pushToChatRoom(BuildContext context, String chatId) {
    context.push('/chats/$chatId');
  }

  /// Check if current route is a chat route
  static bool isChatRoute(String route) {
    return route.startsWith('/chats');
  }

  /// Extract chat ID from route
  static String? extractChatIdFromRoute(String route) {
    if (route.startsWith('/chats/')) {
      final parts = route.split('/');
      if (parts.length >= 3) {
        return parts[2];
      }
    }
    return null;
  }

  /// Handle deep link for chat
  static void handleDeepLink(BuildContext context, String link) {
    if (link.startsWith('/chats/')) {
      final chatId = extractChatIdFromRoute(link);
      if (chatId != null) {
        navigateToChatRoom(context, chatId);
      }
    } else if (link == '/chats') {
      navigateToChatList(context);
    }
  }

  /// Generate deep link for chat room
  static String generateChatRoomDeepLink(String chatId) {
    return '/chats/$chatId';
  }

  /// Generate deep link for chat list
  static String generateChatListDeepLink() {
    return '/chats';
  }
}
