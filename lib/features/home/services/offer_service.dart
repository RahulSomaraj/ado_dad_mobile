// Make an offer: the existing offer popup collects the amount, then the offer
// is sent as the first message of the (get-or-created) conversation and the
// thread opens, so the buyer sees it go from "Sending" to delivered.

import 'package:ado_dad_user/features/chat/widgets/chat_format.dart';
import 'package:flutter/material.dart';

import '../ui/offer_popup.dart' as offer_popup;
import 'chat_service.dart';

class OfferService {
  static Future<void> showOfferPopup({
    required BuildContext context,
    required String adId,
    required String adTitle,
    required String adPosterName,
    required String otherUserId,
    int? adPrice,
  }) async {
    await offer_popup.showOfferPopup(
      context: context,
      adId: adId,
      adTitle: adTitle,
      adPosterName: adPosterName,
      adPrice: adPrice,
      onOfferSubmitted: (amount) async {
        Navigator.of(context).pop(); // close the popup
        if (!context.mounted) return;
        await ChatService.openChatForAd(
          context,
          adId: adId,
          initialMessage: 'Hello! I\'m interested in your ad and would like to '
              'make an offer of ${formatInr(amount)}.',
        );
      },
    );
  }
}
