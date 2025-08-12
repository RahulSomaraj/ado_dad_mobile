import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/sell/ui/android_mobile_seller.dart';
import 'package:ado_dad_user/features/sell/ui/ios_mobile_seller.dart';
import 'package:flutter/material.dart';

class Seller extends StatelessWidget {
  const Seller({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: Scaffold(),
      androidMobileView: AndroidMobileSeller(),
      iosTabletView: Scaffold(),
      iosMobileView: IosMobileSeller(),
    );
  }
}
