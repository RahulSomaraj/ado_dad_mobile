import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/home/ui/android_home_mobile.dart';
import 'package:ado_dad_user/features/home/ui/ios_home_mobile.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: Scaffold(),
      androidMobileView: AndroidHomeMobile(),
      iosTabletView: Scaffold(),
      iosMobileView: IosHomeMobile(),
    );
  }
}
