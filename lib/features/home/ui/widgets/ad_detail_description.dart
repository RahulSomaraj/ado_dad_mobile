import 'package:ado_dad_user/common/get_responsive_size.dart';
import 'package:ado_dad_user/models/advertisement_model/add_model.dart';
import 'package:ado_dad_user/features/home/ui/widgets/ad_detail_card_shell.dart';
import 'package:flutter/material.dart';

class AdDetailDescription extends StatelessWidget {
  final AddModel ad;

  const AdDetailDescription({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 8, tablet: 10, largeTablet: 12, desktop: 14),
        GetResponsiveSize.getResponsivePadding(context,
            mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
        0,
      ),
      child: AdDetailCardShell(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: GetResponsiveSize.getResponsivePadding(context,
                mobile: 16, tablet: 20, largeTablet: 24, desktop: 28),
            vertical: GetResponsiveSize.getResponsivePadding(context,
                mobile: 10, tablet: 14, largeTablet: 18, desktop: 22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 22, largeTablet: 26, desktop: 30),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                  height: GetResponsiveSize.getResponsiveSize(context,
                      mobile: 10, tablet: 12, largeTablet: 14, desktop: 16)),
              Text(
                ad.description,
                style: TextStyle(
                  color: Colors.black,
                  height: 1.35,
                  fontSize: GetResponsiveSize.getResponsiveFontSize(context,
                      mobile: 14, tablet: 22, largeTablet: 26, desktop: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
