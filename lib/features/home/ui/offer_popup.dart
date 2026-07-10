import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

/// Make-an-offer bottom sheet (wireframe: docs/ado_dad_wireframes_missing_pages.html
/// → "Make an offer"). Pinned listing context, big amount input with
/// quick-percent chips (computed client-side from the asking price), and a
/// primary Send offer action.
Future<void> showOfferPopup({
  required BuildContext context,
  required String adId,
  required String adTitle,
  required String adPosterName,
  required Function(double) onOfferSubmitted,
  int? adPrice,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return _OfferSheet(
        adId: adId,
        adTitle: adTitle,
        adPosterName: adPosterName,
        adPrice: adPrice,
        onOfferSubmitted: onOfferSubmitted,
      );
    },
  );
}

class _OfferSheet extends StatefulWidget {
  final String adId;
  final String adTitle;
  final String adPosterName;
  final int? adPrice;
  final Function(double) onOfferSubmitted;

  const _OfferSheet({
    required this.adId,
    required this.adTitle,
    required this.adPosterName,
    required this.adPrice,
    required this.onOfferSubmitted,
  });

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final TextEditingController amountController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();
  double? amount;
  String? errorText;
  int? _selectedPercent; // 5, 8, 10 or null (custom / none)

  static const List<int> _percentOptions = [5, 8, 10];

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

  void _applyPercent(int percent) {
    final price = widget.adPrice;
    if (price == null || price <= 0) return;
    final discounted = (price * (100 - percent) / 100).roundToDouble();
    setState(() {
      _selectedPercent = percent;
      amountController.text = discounted.toStringAsFixed(0);
      amount = discounted;
      errorText = null;
    });
  }

  String _formatPrice(int price) {
    final s = price.toString();
    // Simple Indian-style grouping (e.g. 5,40,000).
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  @override
  void dispose() {
    amountController.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  TextStyle _sectionLabelStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: GetResponsiveSize.getResponsiveFontSize(context,
            mobile: 11, tablet: 13, largeTablet: 14, desktop: 15),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.greyColor,
      );

  @override
  Widget build(BuildContext context) {
    final canSend = amount != null && errorText == null;

    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
            8,
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Make an offer',
                      style: GoogleFonts.poppins(
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 20,
                            largeTablet: 22,
                            desktop: 24),
                        fontWeight: FontWeight.w600,
                        color: AppColors.blackColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.greyColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pinned listing context
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.greyColor.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.sell_outlined,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.adPrice != null)
                            Text.rich(
                              TextSpan(
                                text: '₹ ${_formatPrice(widget.adPrice!)} ',
                                style: GoogleFonts.poppins(
                                  fontSize:
                                      GetResponsiveSize.getResponsiveFontSize(
                                          context,
                                          mobile: 13.5,
                                          tablet: 16,
                                          largeTablet: 18,
                                          desktop: 20),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blackColor,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'asking',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.greyColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            widget.adTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize:
                                  GetResponsiveSize.getResponsiveFontSize(
                                      context,
                                      mobile: 12.5,
                                      tablet: 15,
                                      largeTablet: 17,
                                      desktop: 19),
                              color: AppColors.blackColor,
                            ),
                          ),
                          Text(
                            'Seller: ${widget.adPosterName}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: AppColors.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text('YOUR OFFER', style: _sectionLabelStyle(context)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                focusNode: amountFocusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: GoogleFonts.poppins(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 18, tablet: 22, largeTablet: 24, desktop: 26),
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter amount (e.g., 15000)',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 17, largeTablet: 19, desktop: 21),
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyColor,
                  ),
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 18, tablet: 22, largeTablet: 24, desktop: 26),
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackColor,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(
                        color: AppColors.greyColor.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                        color: AppColors.primaryColor, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  _selectedPercent = null;
                  _validateAmount(value);
                },
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorText!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.redColor,
                    ),
                  ),
                ),

              // Quick percent chips (only when the asking price is known)
              if (widget.adPrice != null && widget.adPrice! > 0) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  children: [
                    ..._percentOptions.map((p) {
                      final selected = _selectedPercent == p;
                      return ChoiceChip(
                        label: Text('-$p%'),
                        selected: selected,
                        onSelected: (_) => _applyPercent(p),
                        selectedColor: AppColors.primaryColor,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: selected
                              ? Colors.white
                              : AppColors.blackColor,
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: selected
                                ? AppColors.primaryColor
                                : AppColors.greyColor.withOpacity(0.4),
                          ),
                        ),
                        backgroundColor: AppColors.whiteColor,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _selectedPercent == null &&
                          amountController.text.isNotEmpty,
                      onSelected: (_) {
                        setState(() => _selectedPercent = null);
                        amountFocusNode.requestFocus();
                      },
                      selectedColor: AppColors.primaryColor,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _selectedPercent == null &&
                                amountController.text.isNotEmpty
                            ? Colors.white
                            : AppColors.blackColor,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: AppColors.greyColor.withOpacity(0.4),
                        ),
                      ),
                      backgroundColor: AppColors.whiteColor,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],

              // Offer message preview (sent into the chat thread)
              if (amount != null && errorText == null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'I will make an offer for an amount ₹${amount!.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.blackColor1,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.greyColor.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: AppColors.blackColor,
                          fontWeight: FontWeight.w500,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 13.5,
                              tablet: 16,
                              largeTablet: 18,
                              desktop: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canSend
                          ? () {
                              widget.onOfferSubmitted(amount!);
                              Navigator.of(context).pop();
                            }
                          : null,
                      icon: const Icon(Icons.send, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        disabledBackgroundColor:
                            AppColors.greyColor.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      label: Text(
                        'Send offer',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: GetResponsiveSize.getResponsiveFontSize(
                              context,
                              mobile: 13.5,
                              tablet: 16,
                              largeTablet: 18,
                              desktop: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
