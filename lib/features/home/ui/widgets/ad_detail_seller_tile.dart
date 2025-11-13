import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_card_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdDetailSellerTile extends StatelessWidget {
  final AddModel ad;

  const AdDetailSellerTile({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 12, tablet: 16, largeTablet: 20, desktop: 24),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        0,
      ),
      child: AdDetailCardShell(
        child: ListTile(
          leading: CircleAvatar(
            radius: GetResponsiveSize.getResponsiveSize(context,
                mobile: 24, tablet: 32, largeTablet: 38, desktop: 44),
            backgroundImage: NetworkImage(ad.user?.profilePic ?? ''),
          ),
          title: Text(
            ad.user?.name?.trim().isNotEmpty == true
                ? ad.user!.name!
                : 'Seller',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                  mobile: 16, tablet: 24, largeTablet: 28, desktop: 32),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ad.user?.email?.trim().isNotEmpty == true)
                Text(
                  ad.user!.email!,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
                  ),
                ),
              if (ad.user?.phone?.trim().isNotEmpty == true)
                Text(
                  ad.user!.phone!,
                  style: TextStyle(
                    fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                        mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
                  ),
                ),
              Text(
                ad.location,
                style: TextStyle(
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 20, largeTablet: 24, desktop: 28),
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: GetResponsiveSize.getResponsiveSize(context,
                mobile: 24, tablet: 28, largeTablet: 32, desktop: 36),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 8, tablet: 12, largeTablet: 16, desktop: 20),
          ),
          onTap: () {
            final sellerId = ad.user?.id;
            if (sellerId != null && sellerId.isNotEmpty && ad.user != null) {
              context.push('/seller-profile/$sellerId', extra: ad.user);
            }
          },
        ),
      ),
    );
  }
}
