import 'package:ado_dad_user/common/device_checker.dart';
import 'package:ado_dad_user/features/search/ui/android_search_mobile.dart';
import 'package:ado_dad_user/features/search/ui/ios_search_mobile.dart';
import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  final String? previousRoute;
  const Search({super.key, this.previousRoute});

  @override
  Widget build(BuildContext context) {
    return DeviceChecker(
      androidTabletView: AndroidSearchMobile(previousRoute: previousRoute),
      androidMobileView: AndroidSearchMobile(previousRoute: previousRoute),
      iosTabletView: AndroidSearchMobile(previousRoute: previousRoute),
      iosMobileView: IosSearchMobile(previousRoute: previousRoute),
    );
  }
}
