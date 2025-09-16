import 'package:flutter/material.dart';
import 'package:ado_dad_user/features/chat/services/offer_service.dart';

class MakeOfferButton extends StatelessWidget {
  final String adId;
  final String adTitle;
  final String adPosterName;
  final String? adPrice;
  final VoidCallback? onOfferSent;
  final bool isLoading;

  const MakeOfferButton({
    super.key,
    required this.adId,
    required this.adTitle,
    required this.adPosterName,
    this.adPrice,
    this.onOfferSent,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : () => _handleMakeOffer(context),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.monetization_on),
        label: Text(
          isLoading ? 'Sending Offer...' : 'Make an Offer',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _handleMakeOffer(BuildContext context) {
    // Show the offer popup
    OfferService.showOfferPopup(
      context: context,
      adId: adId,
      adTitle: adTitle,
      adPosterName: adPosterName,
    );
  }
}

/// Compact version of the make offer button
class MakeOfferButtonCompact extends StatelessWidget {
  final String adId;
  final String adTitle;
  final String adPosterName;
  final VoidCallback? onOfferSent;
  final bool isLoading;

  const MakeOfferButtonCompact({
    super.key,
    required this.adId,
    required this.adTitle,
    required this.adPosterName,
    this.onOfferSent,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : () => _handleMakeOffer(context),
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.monetization_on, size: 18),
      label: Text(
        isLoading ? 'Sending...' : 'Make Offer',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: Colors.blue.shade600),
        foregroundColor: Colors.blue.shade600,
      ),
    );
  }

  void _handleMakeOffer(BuildContext context) {
    // Show the offer popup
    OfferService.showOfferPopup(
      context: context,
      adId: adId,
      adTitle: adTitle,
      adPosterName: adPosterName,
    );
  }
}

/// Floating action button version
class MakeOfferFAB extends StatelessWidget {
  final String adId;
  final String adTitle;
  final String adPosterName;
  final VoidCallback? onOfferSent;
  final bool isLoading;

  const MakeOfferFAB({
    super.key,
    required this.adId,
    required this.adTitle,
    required this.adPosterName,
    this.onOfferSent,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isLoading ? null : () => _handleMakeOffer(context),
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.monetization_on),
      label: Text(
        isLoading ? 'Sending...' : 'Make Offer',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
    );
  }

  void _handleMakeOffer(BuildContext context) {
    // Show the offer popup
    OfferService.showOfferPopup(
      context: context,
      adId: adId,
      adTitle: adTitle,
      adPosterName: adPosterName,
    );
  }
}
