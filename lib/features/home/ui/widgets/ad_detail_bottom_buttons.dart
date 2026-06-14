import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';

class AdDetailBottomButtons extends StatelessWidget {
  final AddModel ad;
  final Future<bool> Function(AddModel) isCurrentUserOwner;
  final VoidCallback onMakeOffer;
  final VoidCallback onChat;
  final VoidCallback? onCall;

  const AdDetailBottomButtons({
    super.key,
    required this.ad,
    required this.isCurrentUserOwner,
    required this.onMakeOffer,
    required this.onChat,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isCurrentUserOwner(ad),
      builder: (context, snapshot) {
        final isOwner = snapshot.data ?? false;

        if (isOwner) {
          return const SizedBox.shrink();
        }

        final bool hasPhone = (ad.user?.phone?.trim().isNotEmpty ?? false);
        final double gap = GetResponsiveSize.getResponsiveSize(context,
            mobile: 12, tablet: 16, largeTablet: 20, desktop: 24);

        // Proposal order: Chat · Make an Offer · Call (lowest-friction first,
        // highest-intent Call anchored right). Make an Offer gets a little more
        // room (flex 3 vs 2) and its label scales down to fit so the longer
        // text never overflows the row.
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _ChatButton(
                label: 'Chat',
                onTap: onChat,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: 3,
              child: _MakeOfferButton(
                label: 'Make an Offer',
                onTap: onMakeOffer,
              ),
            ),
            if (hasPhone && onCall != null) ...[
              SizedBox(width: gap),
              _CallButton(onTap: onCall!),
            ],
          ],
        );
      },
    );
  }
}

class _CallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double size = GetResponsiveSize.getResponsiveSize(context,
        mobile: 48, tablet: 65, largeTablet: 75, desktop: 85);
    return SizedBox(
      height: size,
      width: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF19A463),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(context,
                  mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
            ),
          ),
        ),
        onPressed: onTap,
        child: Icon(
          Icons.call,
          color: Colors.white,
          size: GetResponsiveSize.getResponsiveSize(context,
              mobile: 22, tablet: 28, largeTablet: 32, desktop: 36),
        ),
      ),
    );
  }
}

class _MakeOfferButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MakeOfferButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GetResponsiveSize.getResponsiveSize(context,
          mobile: 48, tablet: 65, largeTablet: 75, desktop: 85),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.primaryColor,
            width: GetResponsiveSize.getResponsiveSize(context,
                mobile: 1, tablet: 1.5, largeTablet: 2, desktop: 2.5),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(context,
                  mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
            ),
          ),
        ),
        onPressed: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 16, tablet: 22, largeTablet: 26, desktop: 30),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChatButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GetResponsiveSize.getResponsiveSize(context,
          mobile: 48, tablet: 65, largeTablet: 75, desktop: 85),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GetResponsiveSize.getResponsiveBorderRadius(context,
                  mobile: 14, tablet: 16, largeTablet: 18, desktop: 20),
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 16, tablet: 22, largeTablet: 26, desktop: 30),
          ),
        ),
      ),
    );
  }
}
