import 'dart:io';
import 'package:flutter/material.dart';

class DeviceChecker extends StatelessWidget {
  final Widget androidTabletView,
      androidMobileView,
      iosTabletView,
      iosMobileView;
  const DeviceChecker({
    super.key,
    required this.androidTabletView,
    required this.androidMobileView,
    required this.iosTabletView,
    required this.iosMobileView,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      final bool isAndroid = Platform.isAndroid;

      // Determine if the device is a tablet
      bool isTablet = screenWidth >= 600 && screenWidth <= 1200;

      // Determine the platform
      if (isAndroid) {
        return isTablet ? androidTabletView : androidMobileView;
      } else {
        return isTablet ? iosTabletView : iosMobileView;
      }
    } catch (e, stackTrace) {
      print('❌ [DeviceChecker] ERROR: $e');
      print('❌ [DeviceChecker] Stack: $stackTrace');
      // Fallback to iOS mobile view on error
      return iosMobileView;
    }
  }
}
