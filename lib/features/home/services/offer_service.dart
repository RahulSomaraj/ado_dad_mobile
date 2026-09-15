import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/offer_popup.dart' as offer_popup;
import 'package:ado_dad_user/services/chat_api_service.dart';
import 'package:ado_dad_user/repositories/chat_repository.dart';
import 'package:ado_dad_user/common/app_colors.dart';

class OfferService {
  /// Show the offer popup and handle the complete offer flow
  static Future<void> showOfferPopup({
    required BuildContext context,
    required String adId,
    required String adTitle,
    required String adPosterName,
    required String otherUserId,
    int? adPrice,
  }) async {
    // Store ScaffoldMessenger from the page context (more stable than dialog context)
    ScaffoldMessengerState? pageScaffoldMessenger;
    try {
      pageScaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    } catch (_) {}

    // Show the offer popup
    await offer_popup.showOfferPopup(
      context: context,
      adId: adId,
      adTitle: adTitle,
      adPosterName: adPosterName,
      adPrice: adPrice,
      onOfferSubmitted: (amount) async {
        // Close the popup
        Navigator.of(context).pop();

        // Show loading indicator
        _showLoadingDialog(context, 'Checking room...');

        try {
          // Check room existence instead of sending offer
          // Pass the ScaffoldMessenger reference through the chain
          await _checkRoomExists(
              context, adId, otherUserId, amount, pageScaffoldMessenger);
        } catch (e) {
          if (!context.mounted) {
            _loadingDialogShown = false;
            return;
          }
          // Close loading dialog (guarded — never pops a page route)
          _closeLoadingDialog(context);

          // Show error
          _showErrorDialog(context, 'Failed to check room: $e');
        }
      },
    );
  }

  /// Check if room exists for the ad and other user
  static Future<void> _checkRoomExists(
      BuildContext context,
      String adId,
      String otherUserId,
      double offerAmount,
      ScaffoldMessengerState? scaffoldMessenger) async {
    try {
      // Import the chat API service
      final chatApiService = ChatApiService();
      final result = await chatApiService.checkRoomExists(adId, otherUserId);
      if (!context.mounted) {
        _loadingDialogShown = false;
        return;
      }

      // Close loading dialog (guarded)
      _closeLoadingDialog(context);

      if (result['success'] == true && result['data']?['exists'] == true) {
        final roomId = result['data']?['roomId'];

        // Join the existing room
        await _joinRoom(context, roomId, adId, otherUserId, offerAmount,
            isNewRoom: false, scaffoldMessenger: scaffoldMessenger);
      } else {
        // Create a new room since none exists
        await _createRoomAndJoin(context, adId, otherUserId, offerAmount,
            scaffoldMessenger: scaffoldMessenger);
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Create room and join when no room exists
  static Future<void> _createRoomAndJoin(
      BuildContext context, String adId, String otherUserId, double offerAmount,
      {ScaffoldMessengerState? scaffoldMessenger}) async {
    try {
      // Get chat repository
      final chatRepository = ChatRepository();

      // Connect to chat service
      final connected = await chatRepository.connect();
      if (!context.mounted) return;
      if (!connected) {
        _showErrorDialog(context, 'Failed to connect to chat service');
        return;
      }

      // Create room for the ad
      final roomId = await chatRepository.createChatRoom(adId);
      if (!context.mounted) return;

      if (roomId != null) {
        // Join the newly created room (no loading dialog shown)
        await _joinRoom(context, roomId, adId, otherUserId, offerAmount,
            isNewRoom: true, scaffoldMessenger: scaffoldMessenger);
      } else {
        _showErrorDialog(context, 'Failed to create chat room');
      }
    } catch (e) {
      if (!context.mounted) {
        _loadingDialogShown = false;
        return;
      }
      // Close loading dialog if still visible (guarded — it was normally
      // closed already after the room check, so an unguarded pop here used
      // to remove the underlying page)
      _closeLoadingDialog(context);
      _showErrorDialog(context, 'Failed to create room: $e');
    }
  }

  /// Join room and provide single proper log
  static Future<void> _joinRoom(BuildContext context, String roomId,
      String adId, String otherUserId, double offerAmount,
      {required bool isNewRoom,
      ScaffoldMessengerState? scaffoldMessenger}) async {
    try {
      // Get chat repository
      final chatRepository = ChatRepository();

      // Join the room
      await chatRepository.joinChatRoom(roomId);
      if (!context.mounted) return;

      // Send message to the room after successful join
      await _sendMessageToRoom(
          context, roomId, adId, otherUserId, offerAmount, isNewRoom,
          scaffoldMessenger: scaffoldMessenger);
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

  /// Send message to room after successful join
  static Future<void> _sendMessageToRoom(BuildContext context, String roomId,
      String adId, String otherUserId, double offerAmount, bool isNewRoom,
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
        scaffoldMessenger ??= ScaffoldMessenger.maybeOf(context);
      } catch (_) {}
    }

    try {
      // Get chat repository
      final chatRepository = ChatRepository();

      // Create the message content with actual offer amount
      final messageContent =
          'Hello! I\'m interested in your ad and would like to make an offer of ₹${offerAmount.toStringAsFixed(0)}.';

      // Send the message
      chatRepository.sendMessage(messageContent, type: 'text');

      // Wait a moment for message to be sent
      await Future.delayed(const Duration(milliseconds: 1000));

      // Single proper log for message send result

      // Show success snackbar using postFrameCallback to ensure context is stable

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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            // Fallback: Try to get ScaffoldMessenger from root navigator
            try {
              final rootNavigator =
                  Navigator.maybeOf(context, rootNavigator: true);
              ScaffoldMessengerState? fallbackMessenger;

              if (rootNavigator != null && rootNavigator.context.mounted) {
                fallbackMessenger =
                    ScaffoldMessenger.maybeOf(rootNavigator.context);
              }

              // If still null, try the passed context
              fallbackMessenger ??= ScaffoldMessenger.maybeOf(context);

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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {}
            } catch (_) {}
          }
        } catch (_) {}
      });
    } catch (e) {
      // Show error dialog with delay to ensure context is stable
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if context is still mounted
      if (context.mounted) {
        _showMessageErrorDialog(context, 'Failed to send message: $e');
      } else {
        // Fallback: Print error to console
      }
    }
  }

  /// Show message error dialog
  static void _showMessageErrorDialog(BuildContext context, String message) {
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
      } else {}
    });
  }

  // Tracks whether the offer-flow loading dialog is on screen, so a stray
  // "close loading" pop can never remove a page route (QA audit 2026-07-10).
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
      } else {}
    });
  }
}
