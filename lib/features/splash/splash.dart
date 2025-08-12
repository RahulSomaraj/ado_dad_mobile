import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/splash/android_splash_mobile.dart';
import 'package:ado_dad_user/features/splash/android_splash_tablet.dart';
import 'package:ado_dad_user/features/splash/ios_splash_mobile.dart';
import 'package:flutter/material.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: AndroidSplashTablet(),
      androidMobileView: AndroidSplashMobile(),
      iosTabletView: Scaffold(),
      iosMobileView: IosSplashMobile(),
    );
  }
}
