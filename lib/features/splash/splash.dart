import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/splash/android_splash_mobile.dart';
import 'package:ado_dad_user/features/splash/android_splash_tablet.dart';
import 'package:ado_dad_user/features/splash/ios_splash_mobile.dart';
import 'package:ado_dad_user/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return DeviceChecker(
        androidTabletView: AndroidSplashTablet(),
        androidMobileView: AndroidSplashMobile(),
        iosTabletView: SplashScreen(),
        iosMobileView: IosSplashMobile(),
      );
    } catch (e, stackTrace) {
      print('❌ [Splash] ERROR: $e');
      print('❌ [Splash] Stack: $stackTrace');
      // Fallback to a simple widget
      return const Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: Text('Splash Error',
              style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      );
    }
  }
}
