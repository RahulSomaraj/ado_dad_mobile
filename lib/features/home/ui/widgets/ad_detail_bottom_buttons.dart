import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:flutter/material.dart';

class AdDetailBottomButtons extends StatelessWidget {
  final AddModel ad;
  final Future<bool> Function(AddModel) isCurrentUserOwner;
  final VoidCallback onMakeOffer;
  final VoidCallback onChat;

  const AdDetailBottomButtons({
    super.key,
    required this.ad,
    required this.isCurrentUserOwner,
    required this.onMakeOffer,
    required this.onChat,
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

        return Row(
          children: [
            Expanded(
              child: _MakeOfferButton(
                label: 'Make an Offer',
                onTap: onMakeOffer,
              ),
            ),
            SizedBox(
                width: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 12, tablet: 16, largeTablet: 20, desktop: 24)),
            Expanded(
              child: _ChatButton(
                label: 'Chat',
                onTap: onChat,
              ),
            ),
          ],
        );
      },
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
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                mobile: 16, tablet: 22, largeTablet: 26, desktop: 30),
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
