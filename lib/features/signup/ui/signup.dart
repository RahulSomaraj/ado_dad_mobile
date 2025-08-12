import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/signup/ui/android_signup_mobile.dart';
import 'package:ado_dad_user/features/signup/ui/ios_signup_mobile.dart';
import 'package:flutter/material.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: Scaffold(),
      androidMobileView: AndroidSignupMobile(),
      iosTabletView: Scaffold(),
      iosMobileView: IosSignupMobile(),
    );
  }
}
