import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/login/ui/android_login_mobile.dart';
import 'package:ado_dad_user/features/login/ui/ios_login_mobile.dart';
import 'package:ado_dad_user/features/login/ui/login_page.dart';
import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: LoginPage(),
      androidMobileView: AndroidLoginMobile(),
      iosTabletView: LoginPage(),
      iosMobileView: IosLoginMobile(),
    );
  }
}
