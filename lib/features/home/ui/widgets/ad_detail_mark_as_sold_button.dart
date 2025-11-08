import 'package:ado_dad_user/common/app_colors.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/ad_detail/ad_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdDetailMarkAsSoldButton extends StatelessWidget {
  final AddModel ad;

  const AdDetailMarkAsSoldButton({super.key, required this.ad});

  void _handleMarkAsSold(BuildContext context) {
    final adDetailBloc = context.read<AdDetailBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          titlePadding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 0, tablet: 4, largeTablet: 8, desktop: 12),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
          ),
          contentPadding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
            0,
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            0,
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
            GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
          ),
          title: Text(
            'Mark as Sold',
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 20, tablet: 26, largeTablet: 30, desktop: 34),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to mark this ad as sold? This action cannot be undone.',
            style: TextStyle(
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                adDetailBloc.add(
                  AdDetailEvent.markAsSold(ad.id),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
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
                elevation: 0,
              ),
              child: Text(
                'Mark as Sold',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 18, largeTablet: 22, desktop: 26),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdDetailBloc, AdDetailState>(
      builder: (context, state) {
        final isLoading = state.when(
          initial: () => false,
          loading: () => false,
          error: (e) => false,
          loaded: (ad) => false,
          markingAsSold: () => true,
          markedAsSold: (ad) => false,
        );
        final isSold = ad.soldOut == true;

        if (isSold) {
          return Container(
            width: double.infinity,
            height: GetResponsiveSize.getResponsiveSize(context,
                mobile: 44, tablet: 65, largeTablet: 75, desktop: 85),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(
                GetResponsiveSize.getResponsiveBorderRadius(context,
                    mobile: 12, tablet: 14, largeTablet: 16, desktop: 18),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: GetResponsiveSize.getResponsivePadding(context,
                  mobile: 12, tablet: 20, largeTablet: 24, desktop: 28),
              vertical: GetResponsiveSize.getResponsivePadding(context,
                  mobile: 6, tablet: 16, largeTablet: 20, desktop: 24),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: GetResponsiveSize.getResponsiveSize(context,
                          mobile: 18, tablet: 26, largeTablet: 30, desktop: 34),
                    ),
                    SizedBox(
                        width: GetResponsiveSize.getResponsiveSize(context,
                            mobile: 6,
                            tablet: 10,
                            largeTablet: 12,
                            desktop: 14)),
                    Text(
                      'SOLD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: GetResponsiveSize.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 22,
                            largeTablet: 26,
                            desktop: 30),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: GetResponsiveSize.getResponsiveSize(context,
              mobile: 44, tablet: 65, largeTablet: 75, desktop: 85),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppColors.primaryColor,
                width: GetResponsiveSize.getResponsiveSize(context,
                    mobile: 1, tablet: 1.5, largeTablet: 2, desktop: 2.5),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 12, tablet: 20, largeTablet: 24, desktop: 28),
                vertical: GetResponsiveSize.getResponsivePadding(context,
                    mobile: 6, tablet: 16, largeTablet: 20, desktop: 24),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  GetResponsiveSize.getResponsiveBorderRadius(context,
                      mobile: 12, tablet: 14, largeTablet: 16, desktop: 18),
                ),
              ),
            ),
            onPressed: isLoading ? null : () => _handleMarkAsSold(context),
            child: isLoading
                ? SizedBox(
                    height: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 20, tablet: 26, largeTablet: 30, desktop: 34),
                    width: GetResponsiveSize.getResponsiveSize(context,
                        mobile: 20, tablet: 26, largeTablet: 30, desktop: 34),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sell,
                          color: AppColors.primaryColor,
                          size: GetResponsiveSize.getResponsiveSize(context,
                              mobile: 18,
                              tablet: 26,
                              largeTablet: 30,
                              desktop: 34),
                        ),
                        SizedBox(
                            width: GetResponsiveSize.getResponsiveSize(context,
                                mobile: 6,
                                tablet: 10,
                                largeTablet: 12,
                                desktop: 14)),
                        Text(
                          'Mark as Sold',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                            fontSize: GetResponsiveSize.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 22,
                                largeTablet: 26,
                                desktop: 30),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
