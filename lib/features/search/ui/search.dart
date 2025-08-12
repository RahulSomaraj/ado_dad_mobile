import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/search/ui/android_search_mobile.dart';
import 'package:ado_dad_user/features/search/ui/ios_search_mobile.dart';
import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: Scaffold(),
      androidMobileView: AndroidSearchMobile(),
      iosTabletView: Scaffold(),
      iosMobileView: IosSearchMobile(),
    );
  }
}
