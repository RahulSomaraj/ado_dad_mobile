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

    // Store ScaffoldMessenger from the page context (more stable than dialog context)
    ScaffoldMessengerState? pageScaffoldMessenger;
    try {
      pageScaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    } catch (e) {
      print('⚠️ Could not get ScaffoldMessenger from page context: $e');
    }

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
          // Pass the ScaffoldMessenger reference through the chain
          await _checkRoomExists(context, adId, otherUserId, amount, pageScaffoldMessenger);
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
  static Future<void> _checkRoomExists(BuildContext context, String adId,
      String otherUserId, double offerAmount, ScaffoldMessengerState? scaffoldMessenger) async {
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

        // Join the existing room
        await _joinRoom(context, roomId, adId, otherUserId, offerAmount,
            isNewRoom: false, scaffoldMessenger: scaffoldMessenger);
      } else {
        print('❌ No room exists for this ad and user combination');
        print('🔄 Proceeding to create new room...');
        // Create a new room since none exists
        await _createRoomAndJoin(context, adId, otherUserId, offerAmount, scaffoldMessenger: scaffoldMessenger);
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
  static Future<void> _createRoomAndJoin(BuildContext context, String adId,
      String otherUserId, double offerAmount, {ScaffoldMessengerState? scaffoldMessenger}) async {
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

        // Join the newly created room (no loading dialog shown)
        await _joinRoom(context, roomId, adId, otherUserId, offerAmount,
            isNewRoom: true, scaffoldMessenger: scaffoldMessenger);
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

  /// Join room and provide single proper log
  static Future<void> _joinRoom(BuildContext context, String roomId,
      String adId, String otherUserId, double offerAmount,
      {required bool isNewRoom, ScaffoldMessengerState? scaffoldMessenger}) async {
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

      // Send message to the room after successful join
      await _sendMessageToRoom(
          context, roomId, adId, otherUserId, offerAmount, isNewRoom, scaffoldMessenger: scaffoldMessenger);
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

  /// Send message to room after successful join
  static Future<void> _sendMessageToRoom(
      BuildContext context,
      String roomId,
      String adId,
      String otherUserId,
      double offerAmount,
      bool isNewRoom,
      {ScaffoldMessengerState? scaffoldMessenger}) async {
    // Use the passed ScaffoldMessenger if available, otherwise try to get it
    if (scaffoldMessenger == null) {
      try {
        // Try to get from root navigator first (more stable)
        final rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
        if (rootNavigator != null && rootNavigator.context.mounted) {
          scaffoldMessenger = ScaffoldMessenger.maybeOf(rootNavigator.context);
        }
        // Fallback to passed context if root navigator doesn't work
        if (scaffoldMessenger == null) {
          scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        }
      } catch (e) {
        print('⚠️ Could not get ScaffoldMessenger: $e');
      }
    }
    
    try {
      print('📤 Sending message to room: $roomId');
      print('📋 Message details:');
      print('   Room ID: $roomId');
      print('   Ad ID: $adId');
      print('   Other User ID: $otherUserId');
      print('   Offer Amount: ₹${offerAmount.toStringAsFixed(0)}');
      print('   Room Type: ${isNewRoom ? "Newly Created" : "Existing"}');
      print('   Message attempt at: ${DateTime.now().toIso8601String()}');

      // Get chat repository
      final chatRepository = ChatRepository();

      // Create the message content with actual offer amount
      final messageContent =
          'Hello! I\'m interested in your ad and would like to make an offer of ₹${offerAmount.toStringAsFixed(0)}.';

      print('💬 Message content: $messageContent');

      // Send the message
      chatRepository.sendMessage(messageContent, type: 'text');

      // Wait a moment for message to be sent
      await Future.delayed(const Duration(milliseconds: 1000));

      // Single proper log for message send result
      print(
          '✅ MESSAGE SENT SUCCESS - Room ID: $roomId | Status: Sent | Type: ${isNewRoom ? "New" : "Existing"} | Timestamp: ${DateTime.now().toIso8601String()}');

      // Show success snackbar using postFrameCallback to ensure context is stable
      print('🎉 Showing message success snackbar for room: $roomId');

      // Show snackbar using the stored ScaffoldMessenger reference
      // Use addPostFrameCallback to ensure we're on the main thread
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // Try to use the stored ScaffoldMessenger if it's still valid
          if (scaffoldMessenger != null && scaffoldMessenger.mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offer message sent successfully!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
            print('✅ Message success snackbar displayed for room: $roomId');
          } else {
            // Fallback: Try to get ScaffoldMessenger from root navigator
            try {
              final rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
              ScaffoldMessengerState? fallbackMessenger;
              
              if (rootNavigator != null && rootNavigator.context.mounted) {
                fallbackMessenger = ScaffoldMessenger.maybeOf(rootNavigator.context);
              }
              
              // If still null, try the passed context
              if (fallbackMessenger == null) {
                fallbackMessenger = ScaffoldMessenger.maybeOf(context);
              }
              
              if (fallbackMessenger != null) {
                fallbackMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Offer message sent successfully!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                print(
                    '✅ Message success snackbar displayed via fallback for room: $roomId');
              } else {
                print('❌ ScaffoldMessenger not available for room: $roomId');
                print(
                    '🚨 FALLBACK: Message sent successfully but snackbar could not be shown');
              }
            } catch (e) {
              print('❌ Error in fallback snackbar: $e');
              print(
                  '🚨 FALLBACK: Message sent successfully but snackbar could not be shown');
            }
          }
        } catch (e) {
          print('❌ Error showing snackbar: $e');
          print(
              '🚨 FALLBACK: Message sent successfully but snackbar could not be shown');
          print(
              '🚨 Room ID: $roomId | Status: Message Sent | Type: ${isNewRoom ? "New" : "Existing"}');
        }
      });
    } catch (e) {
      print(
          '❌ MESSAGE SEND FAILED - Room ID: $roomId | Error: $e | Timestamp: ${DateTime.now().toIso8601String()}');

      // Show error dialog with delay to ensure context is stable
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if context is still mounted
      if (context.mounted) {
        _showMessageErrorDialog(context, 'Failed to send message: $e');
        print('❌ Message error popup displayed for room: $roomId');
      } else {
        print(
            '❌ Context not mounted, cannot show message error popup for room: $roomId');
        // Fallback: Print error to console
        print(
            '🚨 FALLBACK: Message send failed but error popup could not be shown');
        print('🚨 Room ID: $roomId | Error: $e');
      }
    }
  }

  /// Show room joined dialog
  static void _showRoomJoinedDialog(
      BuildContext context, String roomId, String adId, bool isNewRoom) {
    print('🎯 Attempting to show room joined dialog for room: $roomId');

    // Ensure we're on the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isNewRoom
                        ? 'Room Created & Joined!'
                        : 'Room Joined Successfully!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNewRoom
                            ? '🎉 A new chat room has been created and you have joined it!'
                            : '✅ You have successfully joined the existing room!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Room ID', roomId),
                      _buildInfoRow('Ad ID', adId),
                      _buildInfoRow('Status', 'Active'),
                      _buildInfoRow(
                          'Type', isNewRoom ? 'New Room' : 'Existing Room'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'You can now start chatting!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Great! Let\'s Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        print('✅ Room joined dialog shown successfully for room: $roomId');
      } else {
        print(
            '❌ Context not mounted when trying to show room joined dialog for room: $roomId');
      }
    });
  }

  /// Show message error dialog
  static void _showMessageErrorDialog(BuildContext context, String message) {
    print('🎯 Attempting to show message error dialog: $message');

    // Ensure we're on the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Message Send Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '❌ Failed to send message to the chat room.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: $message',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'You can try sending the message again.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        print('✅ Message error dialog shown successfully');
      } else {
        print('❌ Context not mounted when trying to show message error dialog');
      }
    });
  }

  /// Build info row for dialog
  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
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
