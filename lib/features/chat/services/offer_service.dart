import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_bloc.dart';
import 'package:ado_dad_user/features/chat/bloc/chat_event.dart';
import 'package:ado_dad_user/features/chat/ui/offer_popup.dart' as offer_popup;

class OfferService {
  /// Show the offer popup and handle the complete offer flow
  static Future<void> showOfferPopup({
    required BuildContext context,
    required String adId,
    required String adTitle,
    required String adPosterName,
  }) async {
    // Show the offer popup
    await offer_popup.showOfferPopup(
      context: context,
      adId: adId,
      adTitle: adTitle,
      adPosterName: adPosterName,
      onOfferSubmitted: (amount) async {
        // Close the popup
        Navigator.of(context).pop();

        // Show loading indicator
        _showLoadingDialog(context, 'Sending offer...');

        try {
          // Ensure socket is connected before sending offer
          final chatBloc = context.read<ChatBloc>();
          if (!chatBloc.state.isConnected) {
            log('🔄 Socket not connected, attempting to connect...');
            chatBloc.add(const ChatEvent.connect());

            // Wait a moment for connection
            await Future.delayed(const Duration(seconds: 2));
          }

          // Send the offer through the chat bloc
          chatBloc.add(ChatEvent.sendOffer(
            adId: adId,
            amount: amount,
            adTitle: adTitle,
            adPosterName: adPosterName,
          ));

          // Listen for the result
          await _waitForOfferResult(context, adId);
        } catch (e) {
          // Close loading dialog
          Navigator.of(context).pop();

          // Show error
          _showErrorDialog(context, 'Failed to send offer: $e');
        }
      },
    );
  }

  /// Wait for the offer result and handle success/error
  static Future<void> _waitForOfferResult(
      BuildContext context, String adId) async {
    // Listen to chat bloc state changes
    final chatBloc = context.read<ChatBloc>();

    // Wait for the offer to complete (with longer timeout to match socket service)
    int attempts = 0;
    const maxAttempts = 20; // 20 * 1 second = 20 seconds total
    const checkInterval = Duration(seconds: 1);

    while (attempts < maxAttempts) {
      await Future.delayed(checkInterval);
      final state = chatBloc.state;

      if (!state.isSendingOffer) {
        // Offer completed, check result
        break;
      }
      attempts++;
    }

    // Close loading dialog
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final finalState = chatBloc.state;

    if (finalState.isSendingOffer) {
      // Still sending after max attempts - timeout
      _showErrorDialog(context, 'Request timeout. Please try again.');
      return;
    }

    if (finalState.error != null) {
      // Show error
      _showErrorDialog(context, finalState.error!);
    } else if (finalState.lastOfferRoomId != null) {
      // Success - show success message
      _showSuccessDialog(context, 'Offer sent successfully!');

      // Optionally navigate to the chat room
      // You can add navigation logic here
    }
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

  /// Show success dialog
  static void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
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

  /// Quick method to send offer without popup (for testing)
  static Future<void> sendQuickOffer({
    required BuildContext context,
    required String adId,
    required String amount,
    String? adTitle,
    String? adPosterName,
  }) async {
    context.read<ChatBloc>().add(ChatEvent.sendOffer(
          adId: adId,
          amount: amount,
          adTitle: adTitle,
          adPosterName: adPosterName,
        ));
  }
}
