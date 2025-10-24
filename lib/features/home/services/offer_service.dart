import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/offer_popup.dart' as offer_popup;
import 'package:ado_dad_user/services/chat_api_service.dart';
import 'package:ado_dad_user/repositories/chat_repository.dart';

class OfferService {
  /// Show the offer popup and handle the complete offer flow
  static Future<void> showOfferPopup({
    required BuildContext context,
    required String adId,
    required String adTitle,
    required String adPosterName,
    required String otherUserId,
  }) async {
    print('💰 Starting offer flow...');
    print('📋 Offer details:');
    print('   Ad ID: $adId');
    print('   Ad Title: $adTitle');
    print('   Ad Poster: $adPosterName');
    print('   Other User ID: $otherUserId');
    print('   Flow started at: ${DateTime.now().toIso8601String()}');

    // Show the offer popup
    await offer_popup.showOfferPopup(
      context: context,
      adId: adId,
      adTitle: adTitle,
      adPosterName: adPosterName,
      onOfferSubmitted: (amount) async {
        print('💵 Offer submitted with amount: ₹${amount.toStringAsFixed(0)}');
        print('🔄 Starting room check and creation flow...');

        // Close the popup
        Navigator.of(context).pop();

        // Show loading indicator
        _showLoadingDialog(context, 'Checking room...');

        try {
          // Check room existence instead of sending offer
          await _checkRoomExists(context, adId, otherUserId);
        } catch (e) {
          print('💥 Error in offer flow: $e');
          // Close loading dialog
          Navigator.of(context).pop();

          // Show error
          _showErrorDialog(context, 'Failed to check room: $e');
        }
      },
    );
  }

  /// Check if room exists for the ad and other user
  static Future<void> _checkRoomExists(
      BuildContext context, String adId, String otherUserId) async {
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

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success'] == true && result['data']?['exists'] == true) {
        final roomId = result['data']?['roomId'];
        final initiatorId = result['data']?['initiatorId'];
        final adIdFromResult = result['data']?['adId'];

        print('✅ Room exists with details:');
        print('   Room ID: $roomId');
        print('   Initiator ID: $initiatorId');
        print('   Ad ID: $adIdFromResult');
        print('   Status: Existing room found');

        // Show success dialog with room details
        _showRoomExistsDialog(context, roomId, initiatorId, adIdFromResult);
      } else {
        print('❌ No room exists for this ad and user combination');
        print('🔄 Proceeding to create new room...');
        // Create a new room since none exists
        await _createRoomAndJoin(context, adId, otherUserId);
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

  /// Show room exists dialog
  static void _showRoomExistsDialog(
      BuildContext context, String roomId, String? initiatorId, String? adId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Exists'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A chat room already exists for this ad:'),
            const SizedBox(height: 12),
            Text('Room ID: $roomId'),
            if (initiatorId != null) Text('Initiator ID: $initiatorId'),
            if (adId != null) Text('Ad ID: $adId'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Create room and join when no room exists
  static Future<void> _createRoomAndJoin(
      BuildContext context, String adId, String otherUserId) async {
    try {
      print('🏠 Starting room creation process...');
      print('📋 Room creation details:');
      print('   Ad ID: $adId');
      print('   Other User ID: $otherUserId');
      print('   Timestamp: ${DateTime.now().toIso8601String()}');

      // Show loading dialog
      _showLoadingDialog(context, 'Creating room...');

      // Get chat repository
      final chatRepository = ChatRepository();
      print('🔗 Chat repository initialized');

      // Connect to chat service
      print('🔌 Attempting to connect to chat service...');
      final connected = await chatRepository.connect();
      if (!connected) {
        print('❌ Failed to connect to chat service');
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Failed to connect to chat service');
        return;
      }
      print('✅ Successfully connected to chat service');

      // Create room for the ad
      print('🏗️ Creating chat room for ad: $adId');
      final roomId = await chatRepository.createChatRoom(adId);

      // Close loading dialog
      Navigator.of(context).pop();

      if (roomId != null) {
        print('🎉 Room created successfully!');
        print('📊 Newly created room details:');
        print('   Room ID: $roomId');
        print('   Ad ID: $adId');
        print('   Other User ID: $otherUserId');
        print('   Created At: ${DateTime.now().toIso8601String()}');
        print('   Status: Active');
        print('   Participants: Current user + Other user ($otherUserId)');

        _showRoomCreatedDialog(context, roomId, adId);
      } else {
        print('❌ Room creation failed - no room ID returned');
        _showErrorDialog(context, 'Failed to create chat room');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
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

  /// Show room created dialog
  static void _showRoomCreatedDialog(
      BuildContext context, String roomId, String adId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A new chat room has been created:'),
            const SizedBox(height: 12),
            Text('Room ID: $roomId'),
            Text('Ad ID: $adId'),
            const SizedBox(height: 12),
            const Text('You can now start chatting!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog
  static void _showLoadingDialog(BuildContext context, String message) {
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
  }
}
