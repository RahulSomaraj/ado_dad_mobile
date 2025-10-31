import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/sell/ui/android_mobile_seller.dart';
import 'package:ado_dad_user/features/sell/ui/ios_mobile_seller.dart';
import 'package:ado_dad_user/features/sell/ui/item_category.dart';
import 'package:flutter/material.dart';

class Seller extends StatelessWidget {
  const Seller({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: ItemCategory(),
      androidMobileView: AndroidMobileSeller(),
      iosTabletView: ItemCategory(),
      iosMobileView: IosMobileSeller(),
    );
  }
}
