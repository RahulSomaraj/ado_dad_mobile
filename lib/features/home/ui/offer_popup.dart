import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ado_dad_user/common/app_colors.dart';

/// Show the offer popup dialog
Future<void> showOfferPopup({
  required BuildContext context,
  required String adId,
  required String adTitle,
  required String adPosterName,
  required Function(double) onOfferSubmitted,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return _OfferPopupDialog(
        adId: adId,
        adTitle: adTitle,
        adPosterName: adPosterName,
        onOfferSubmitted: onOfferSubmitted,
      );
    },
  );
}

class _OfferPopupDialog extends StatefulWidget {
  final String adId;
  final String adTitle;
  final String adPosterName;
  final Function(double) onOfferSubmitted;

  const _OfferPopupDialog({
    required this.adId,
    required this.adTitle,
    required this.adPosterName,
    required this.onOfferSubmitted,
  });

  @override
  State<_OfferPopupDialog> createState() => _OfferPopupDialogState();
}

class _OfferPopupDialogState extends State<_OfferPopupDialog> {
  final TextEditingController amountController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();
  double? amount;
  String? errorText;

  void _validateAmount(String value) {
    if (value.isEmpty) {
      setState(() {
        amount = null;
        errorText = null;
      });
      return;
    }

    final parsedAmount = double.tryParse(value);
    if (parsedAmount == null) {
      setState(() {
        amount = null;
        errorText = 'Please enter a valid amount';
      });
    } else if (parsedAmount <= 0) {
      setState(() {
        amount = null;
        errorText = 'Amount must be greater than 0';
      });
    } else {
      setState(() {
        amount = parsedAmount;
        errorText = null;
      });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.monetization_on,
            color: Colors.blue.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Make an Offer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ad info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ad: ${widget.adTitle}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seller: ${widget.adPosterName}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount input
            const Text(
              'Enter your offer amount:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              focusNode: amountFocusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter amount (e.g., 15000)',
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              onChanged: _validateAmount,
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Message preview
            if (amount != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your offer message:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'I will make an offer for an amount ₹${amount!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: amount != null && errorText == null
                ? () {
                    widget.onOfferSubmitted(amount!);
                    Navigator.of(context).pop();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: amount != null && errorText == null
                  ? AppColors.primaryColor
                  : Colors.grey.shade400,
              foregroundColor: AppColors.whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Send Offer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.whiteColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
