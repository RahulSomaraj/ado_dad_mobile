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
    print('💬 Starting direct chat flow...');
    print('📋 Chat details:');
    print('   Ad ID: $adId');
    print('   Ad Title: $adTitle');
    print('   Ad Poster: $adPosterName');
    print('   Other User ID: $otherUserId');
    print('   Flow started at: ${DateTime.now().toIso8601String()}');

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
      print('💥 Error in chat flow: $e');
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
      print('🔍 Starting room existence check...');
      print('📋 Room check details:');
      print('   Ad ID: $adId');
      print('   Other User ID: $otherUserId');
      print('   Check timestamp: ${DateTime.now().toIso8601String()}');

      // Import the chat API service
      final chatApiService = ChatApiService();
      print('🌐 Calling API: /chats/rooms/check/$adId/$otherUserId');
      final result = await chatApiService.checkRoomExists(adId, otherUserId);

      print('📡 API response received:');
      print('   Success: ${result['success']}');
      print('   Data: ${result['data']}');

      // Close loading dialog (guarded)
      _closeLoadingDialog(context);

      if (result['success'] == true && result['data']?['exists'] == true) {
        final roomId = result['data']?['roomId'];
        final initiatorId = result['data']?['initiatorId'];
        final adIdFromResult = result['data']?['adId'];

        print('✅ Room exists with details:');
        print('   Room ID: $roomId');
        print('   Initiator ID: $initiatorId');
        print('   Ad ID: $adIdFromResult');
        print('   Status: Existing room found');

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
        print('❌ No room exists for this ad and user combination');
        print('🔄 Proceeding to create new room...');
        // Create a new room since none exists
        await _createRoomAndJoin(
          context,
          adId,
          otherUserId,
          adTitle: adTitle,
          adPosterName: adPosterName,
        );
      }
    } catch (e) {
      print('💥 Error checking room existence: $e');
      print('📋 Error details:');
      print('   Error type: ${e.runtimeType}');
      print('   Error message: $e');
      print('   Ad ID: $adId');
      print('   Other User ID: $otherUserId');
      rethrow;
    }
  }

  /// Create room and join when no room exists
  static Future<void> _createRoomAndJoin(
      BuildContext context, String adId, String otherUserId,
      {required String adTitle, required String adPosterName}) async {
    try {
      print('🏠 Starting room creation process...');
      print('📋 Room creation details:');
      print('   Ad ID: $adId');
      print('   Other User ID: $otherUserId');
      print('   Timestamp: ${DateTime.now().toIso8601String()}');

      // Get chat repository
      final chatRepository = ChatRepository();
      print('🔗 Chat repository initialized');

      // Connect to chat service
      print('🔌 Attempting to connect to chat service...');
      final connected = await chatRepository.connect();
      if (!connected) {
        print('❌ Failed to connect to chat service');
        _showErrorDialog(context, 'Failed to connect to chat service');
        return;
      }
      print('✅ Successfully connected to chat service');

      // Create room for the ad
      print('🏗️ Creating chat room for ad: $adId');
      final roomId = await chatRepository.createChatRoom(adId);

      if (roomId != null) {
        print('🎉 Room created successfully!');
        print('📊 Newly created room details:');
        print('   Room ID: $roomId');
        print('   Ad ID: $adId');
        print('   Other User ID: $otherUserId');
        print('   Created At: ${DateTime.now().toIso8601String()}');
        print('   Status: Active');
        print('   Participants: Current user + Other user ($otherUserId)');

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
        print('❌ Room creation failed - no room ID returned');
        _showErrorDialog(context, 'Failed to create chat room');
      }
    } catch (e) {
      // Close loading dialog if still visible (guarded — normally already
      // closed after the room check; an unguarded pop removed the page)
      _closeLoadingDialog(context);
      print('💥 Error creating room: $e');
      print('📋 Error details:');
      print('   Error type: ${e.runtimeType}');
      print('   Error message: $e');
      print('   Ad ID: $adId');
      print('   Other User ID: $otherUserId');
      print('   Timestamp: ${DateTime.now().toIso8601String()}');
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
      print('🚪 Attempting to join room: $roomId');
      print('📋 Join details:');
      print('   Room ID: $roomId');
      print('   Ad ID: $adId');
      print('   Other User ID: $otherUserId');
      print('   Room Type: ${isNewRoom ? "Newly Created" : "Existing"}');
      print('   Join attempt at: ${DateTime.now().toIso8601String()}');

      // Get chat repository
      final chatRepository = ChatRepository();

      // Join the room
      await chatRepository.joinChatRoom(roomId);

      // Single proper log for room join result
      print(
          '✅ ROOM JOIN SUCCESS - Room ID: $roomId | Status: Joined | Type: ${isNewRoom ? "New" : "Existing"} | Timestamp: ${DateTime.now().toIso8601String()}');

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
        print('✅ Navigated to chat page for room: $roomId');
        print('👤 Other user name: $adPosterName');
        print('📝 Ad title: $adTitle');
      }
    } catch (e) {
      print(
          '❌ ROOM JOIN FAILED - Room ID: $roomId | Error: $e | Timestamp: ${DateTime.now().toIso8601String()}');

      // Show error dialog with delay to ensure context is stable
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if context is still mounted
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to join room: $e');
        print('❌ Error popup displayed for room: $roomId');
      } else {
        print(
            '❌ Context not mounted, cannot show error popup for room: $roomId');
        // Fallback: Print error to console
        print(
            '🚨 FALLBACK: Room join failed but error popup could not be shown');
        print('🚨 Room ID: $roomId | Error: $e');
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
    print('🎯 Attempting to show error dialog: $message');

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
        print('✅ Error dialog shown successfully');
      } else {
        print('❌ Context not mounted when trying to show error dialog');
      }
    });
  }
}
