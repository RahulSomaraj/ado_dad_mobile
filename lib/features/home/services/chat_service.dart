import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ado_dad_user/services/chat_api_service.dart';
import 'package:ado_dad_user/repositories/chat_repository.dart';
import 'package:go_router/go_router.dart';

class ChatService {
  /// Start direct chat flow without offer popup
  static Future<void> startDirectChat({
    required BuildContext context,
    required String adId,
    required String adTitle,
    required String adPosterName,
    required String otherUserId,
  }) async {

    // Show loading indicator
    _showLoadingDialog(context, 'Checking chat room...');

    try {
      // Check room existence
      await _checkRoomExists(
        context,
        adId,
        otherUserId,
        adTitle: adTitle,
        adPosterName: adPosterName,
      );
    } catch (e) {
      // Close loading dialog (guarded)
      _closeLoadingDialog(context);

      // Show error
      _showErrorDialog(context, 'Failed to check chat room: $e');
    }
  }

  /// Check if room exists for the ad and other user
  static Future<void> _checkRoomExists(
      BuildContext context, String adId, String otherUserId,
      {required String adTitle, required String adPosterName}) async {
    try {

      // Import the chat API service
      final chatApiService = ChatApiService();
      final result = await chatApiService.checkRoomExists(adId, otherUserId);

      // Close loading dialog (guarded)
      _closeLoadingDialog(context);

      if (result['success'] == true && result['data']?['exists'] == true) {
        final roomId = result['data']?['roomId'];
        final initiatorId = result['data']?['initiatorId'];
        final adIdFromResult = result['data']?['adId'];

        // Join the existing room
        await _joinRoom(
          context,
          roomId,
          adId,
          otherUserId,
          adTitle: adTitle,
          adPosterName: adPosterName,
          isNewRoom: false,
        );
      } else {
        // Create a new room since none exists
        await _createRoomAndJoin(
          context,
          adId,
          otherUserId,
          adTitle: adTitle,
          adPosterName: adPosterName,
        );
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Create room and join when no room exists
  static Future<void> _createRoomAndJoin(
      BuildContext context, String adId, String otherUserId,
      {required String adTitle, required String adPosterName}) async {
    try {

      // Get chat repository
      final chatRepository = ChatRepository();

      // Connect to chat service
      final connected = await chatRepository.connect();
      if (!connected) {
        _showErrorDialog(context, 'Failed to connect to chat service');
        return;
      }

      // Create room for the ad
      final roomId = await chatRepository.createChatRoom(adId);

      if (roomId != null) {

        // Join the newly created room
        await _joinRoom(
          context,
          roomId,
          adId,
          otherUserId,
          adTitle: adTitle,
          adPosterName: adPosterName,
          isNewRoom: true,
        );
      } else {
        _showErrorDialog(context, 'Failed to create chat room');
      }
    } catch (e) {
      // Close loading dialog if still visible (guarded — normally already
      // closed after the room check; an unguarded pop removed the page)
      _closeLoadingDialog(context);
      _showErrorDialog(context, 'Failed to create room: $e');
    }
  }

  /// Join room and navigate to chat page
  static Future<void> _joinRoom(
    BuildContext context,
    String roomId,
    String adId,
    String otherUserId, {
    required bool isNewRoom,
    required String adTitle,
    required String adPosterName,
  }) async {
    try {

      // Get chat repository
      final chatRepository = ChatRepository();

      // Join the room
      await chatRepository.joinChatRoom(roomId);

      // Single proper log for room join result

      // Navigate to chat page with all necessary parameters
      if (context.mounted) {
        final queryParams = <String, String>{
          'from': 'ad-detail',
          'name': adPosterName,
          'adTitle': adTitle,
          'adId': adId,
        };
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        context.push('/chat/$roomId?$queryString');
      }
    } catch (e) {

      // Show error dialog with delay to ensure context is stable
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if context is still mounted
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to join room: $e');
      } else {
        // Fallback: Print error to console
      }
    }
  }

  // Guards the loading dialog so a stray pop can never remove a page route
  // (QA audit 2026-07-10).
  static bool _loadingDialogShown = false;

  static void _closeLoadingDialog(BuildContext context) {
    if (_loadingDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
    _loadingDialogShown = false;
  }

  /// Show loading dialog
  static void _showLoadingDialog(BuildContext context, String message) {
    _loadingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Show error dialog
  static void _showErrorDialog(BuildContext context, String message) {

    // Ensure we're on the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
      }
    });
  }
}
