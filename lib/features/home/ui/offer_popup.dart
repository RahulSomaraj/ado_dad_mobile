import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

/// Show the offer popup dialog
Future<void> showOfferPopup({
  required BuildContext context,
  required String adId,
  required String adTitle,
  required String adPosterName,
  required Function(double) onOfferSubmitted,
}) async {
  final isIOS = !kIsWeb && Platform.isIOS;

  if (isIOS) {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _OfferPopupDialog(
          adId: adId,
          adTitle: adTitle,
          adPosterName: adPosterName,
          onOfferSubmitted: onOfferSubmitted,
          isIOS: true,
        );
      },
    );
  } else {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _OfferPopupDialog(
          adId: adId,
          adTitle: adTitle,
          adPosterName: adPosterName,
          onOfferSubmitted: onOfferSubmitted,
          isIOS: false,
        );
      },
    );
  }
}

class _OfferPopupDialog extends StatefulWidget {
  final String adId;
  final String adTitle;
  final String adPosterName;
  final Function(double) onOfferSubmitted;
  final bool isIOS;

  const _OfferPopupDialog({
    required this.adId,
    required this.adTitle,
    required this.adPosterName,
    required this.onOfferSubmitted,
    required this.isIOS,
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
    if (widget.isIOS) {
      // iOS-friendly Cupertino dialog - matching delete account popup design
      return StatefulBuilder(
        builder: (stateContext, setState) => CupertinoAlertDialog(
          title: Text(
            'Make an Offer',
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 18, tablet: 22, largeTablet: 26, desktop: 30),
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Container(
            padding: EdgeInsets.only(
              top: GetResponsiveSize.getResponsivePadding(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ad info
                Text(
                  'Ad: ${widget.adTitle}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
                  ),
                ),
                SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 4, tablet: 6, largeTablet: 8, desktop: 10),
                ),
                Text(
                  'Seller: ${widget.adPosterName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                ),
                // Amount input label
                Text(
                  'Enter your offer amount:',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 13, tablet: 15, largeTablet: 17, desktop: 19),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
                ),
                // Amount input field
                CupertinoTextField(
                  controller: amountController,
                  focusNode: amountFocusNode,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  placeholder: 'Enter amount (e.g., 15000)',
                  padding: EdgeInsets.symmetric(
                    horizontal: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                    vertical: GetResponsiveSize.getResponsivePadding(context,
                        mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
                  ),
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 16, tablet: 18, largeTablet: 20, desktop: 22),
                  ),
                  prefix: Padding(
                    padding: EdgeInsets.only(
                      left: GetResponsiveSize.getResponsivePadding(context,
                          mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                    ),
                    child: Text(
                      '₹ ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            largeTablet: 20,
                            desktop: 22),
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onChanged: (value) {
                    _validateAmount(value);
                    setState(() {}); // Update the dialog state
                  },
                ),
                // Error text
                if (errorText != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                    ),
                    child: Text(
                      errorText!,
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 12,
                            tablet: 14,
                            largeTablet: 16,
                            desktop: 18),
                      ),
                    ),
                  ),
                // Message preview
                if (amount != null && errorText == null) ...[
                  SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                  ),
                  Text(
                    'I will make an offer for an amount ₹${amount!.toStringAsFixed(0)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: false,
              onPressed: () => Navigator.pop(stateContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 16, tablet: 18, largeTablet: 20, desktop: 22),
                ),
              ),
            ),
            CupertinoDialogAction(
              isDefaultAction: false,
              onPressed: amount != null && errorText == null
                  ? () {
                      widget.onOfferSubmitted(amount!);
                      Navigator.pop(stateContext);
                    }
                  : null,
              child: Text(
                'Send Offer',
                style: TextStyle(
                  color: amount != null && errorText == null
                      ? AppColors.primaryColor
                      : CupertinoColors.placeholderText,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 16, tablet: 18, largeTablet: 20, desktop: 22),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Material Design dialog for Android/Web
      return AlertDialog(
        titlePadding: EdgeInsets.fromLTRB(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 24, tablet: 32, largeTablet: 40, desktop: 48),
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 24, tablet: 32, largeTablet: 40, desktop: 48),
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 0, tablet: 6, largeTablet: 12, desktop: 18),
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 16, tablet: 24, largeTablet: 32, desktop: 40),
        ),
        contentPadding: EdgeInsets.fromLTRB(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 24, tablet: 32, largeTablet: 40, desktop: 48),
          0,
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 24, tablet: 32, largeTablet: 40, desktop: 48),
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 16, tablet: 24, largeTablet: 32, desktop: 40),
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 8, tablet: 16, largeTablet: 24, desktop: 32),
          0,
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 8, tablet: 16, largeTablet: 24, desktop: 32),
          GetResponsiveSize.getResponsivePadding(context,
              mobile: 8, tablet: 16, largeTablet: 24, desktop: 32),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            GetResponsiveSize.getResponsiveBorderRadius(context,
                mobile: 16, tablet: 18, largeTablet: 20, desktop: 22),
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.monetization_on,
              color: Colors.blue.shade600,
              size: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 28, tablet: 42, largeTablet: 52, desktop: 62),
            ),
            SizedBox(
                width: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 12, tablet: 14, largeTablet: 16, desktop: 18)),
            Expanded(
              child: Text(
                'Make an Offer',
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 20, tablet: 30, largeTablet: 36, desktop: 42),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: _buildContent(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                vertical: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 14, tablet: 22, largeTablet: 28, desktop: 34),
              ),
            ),
          ),
          SizedBox(
            height: GetResponsiveSize.getResponsiveSize(context,
                mobile: 48, tablet: 65, largeTablet: 75, desktop: 85),
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
                  borderRadius: BorderRadius.circular(
                    GetResponsiveSize.getResponsiveBorderRadius(context,
                        mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
                  ),
                ),
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
                  vertical: GetResponsiveSize.getResponsivePadding(context,
                      mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                ),
              ),
              child: Text(
                'Send Offer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.whiteColor,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 22, largeTablet: 28, desktop: 34),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isIOS) {
      // Simplified iOS content - cleaner, matching CupertinoAlertDialog style
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad info (simplified for iOS)
          Text(
            'Ad: ${widget.adTitle}',
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
            ),
          ),
          SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 4, tablet: 6, largeTablet: 8, desktop: 10)),
          Text(
            'Seller: ${widget.adPosterName}',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
            ),
          ),
          SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28)),

          // Amount input label
          Text(
            'Enter your offer amount:',
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
            ),
          ),
          SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
          CupertinoTextField(
            controller: amountController,
            focusNode: amountFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            ),
            placeholder: 'Enter amount (e.g., 15000)',
            placeholderStyle: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
              color: CupertinoColors.placeholderText,
            ),
            prefix: Padding(
              padding: EdgeInsets.only(
                left: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
              ),
              child: Text(
                '₹ ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
              vertical: GetResponsiveSize.getResponsivePadding(context,
                  mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(
                GetResponsiveSize.getResponsiveBorderRadius(context,
                    mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
              ),
            ),
            onChanged: _validateAmount,
          ),
          if (errorText != null) ...[
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
            Text(
              errorText!,
              style: TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
              ),
            ),
          ],

          if (amount != null) ...[
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 16, tablet: 20, largeTablet: 24, desktop: 28)),
            Text(
              'I will make an offer for an amount ₹${amount!.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                color: CupertinoColors.label,
              ),
            ),
          ],
        ],
      );
    } else {
      // Material Design content for Android/Web
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad info
          Container(
            padding: EdgeInsets.all(
              GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 20, largeTablet: 28, desktop: 36),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                GetResponsiveSize.getResponsiveBorderRadius(context,
                    mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ad: ${widget.adTitle}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 22, largeTablet: 28, desktop: 34),
                  ),
                ),
                SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 4, tablet: 8, largeTablet: 12, desktop: 16)),
                Text(
                  'Seller: ${widget.adPosterName}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 12, tablet: 20, largeTablet: 26, desktop: 32),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 20, tablet: 28, largeTablet: 36, desktop: 44)),

          // Amount input
          Text(
            'Enter your offer amount:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 16, tablet: 24, largeTablet: 30, desktop: 36),
            ),
          ),
          SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
          TextField(
            controller: amountController,
            focusNode: amountFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
            ),
            decoration: InputDecoration(
              hintText: 'Enter amount (e.g., 15000)',
              hintStyle: TextStyle(
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
              ),
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
                vertical: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                ),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                ),
                borderSide: BorderSide(
                  color: Colors.blue.shade600,
                  width: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 2, tablet: 2.5, largeTablet: 3, desktop: 3.5),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                ),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                ),
                borderSide: BorderSide(
                  color: Colors.red,
                  width: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 2, tablet: 2.5, largeTablet: 3, desktop: 3.5),
                ),
              ),
            ),
            onChanged: _validateAmount,
          ),
          if (errorText != null) ...[
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 8, tablet: 10, largeTablet: 12, desktop: 14)),
            Text(
              errorText!,
              style: TextStyle(
                color: Colors.red,
                fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                    mobile: 12, tablet: 20, largeTablet: 26, desktop: 32),
              ),
            ),
          ],

          SizedBox(
              height: GetResponsiveSize.getResponsiveSize(context,
                  mobile: 16, tablet: 20, largeTablet: 24, desktop: 28)),

          // Message preview
          if (amount != null) ...[
            Container(
              padding: EdgeInsets.all(
                GetResponsiveSize.getResponsivePadding(context,
                    mobile: 12, tablet: 20, largeTablet: 28, desktop: 36),
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
                ),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your offer message:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: 12, tablet: 20, largeTablet: 26, desktop: 32),
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(
                      height: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 4, tablet: 8, largeTablet: 12, desktop: 16)),
                  Text(
                    'I will make an offer for an amount ₹${amount!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                          mobile: 14, tablet: 22, largeTablet: 28, desktop: 34),
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
                height: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 16, tablet: 20, largeTablet: 24, desktop: 28)),
          ],
        ],
      );
    }
  }
}
