import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/profile/ui/android_profile_mobile.dart';
import 'package:ado_dad_user/features/profile/ui/ios_profile_mobile.dart';
import 'package:ado_dad_user/features/profile/ui/profile_page.dart';
import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: ProfilePage(),
      androidMobileView: AndroidProfileMobile(),
      iosTabletView: ProfilePage(),
      iosMobileView: IosProfileMobile(),
    );
  }
}
