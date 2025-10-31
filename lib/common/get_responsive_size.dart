import 'package:flutter/material.dart';

class GetResponsiveSize {
  // Common responsive sizing function for fonts, padding, margins, etc.
  static double getResponsiveSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double largeTablet,
    required double desktop,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      // Large tablets/desktop
      return desktop;
    } else if (screenWidth > 900) {
      // Medium tablets
      return largeTablet;
    } else if (screenWidth > 600) {
      // Small tablets
      return tablet;
    } else {
      // Mobile phones
      return mobile;
    }
  }

  // Convenience method for font sizes
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double largeTablet,
    required double desktop,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      desktop: desktop,
    );
  }

  // Convenience method for padding/margins
  static double getResponsivePadding(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double largeTablet,
    required double desktop,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      desktop: desktop,
    );
  }

  // Convenience method for border radius
  static double getResponsiveBorderRadius(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double largeTablet,
    required double desktop,
  }) {
    return getResponsiveSize(
      context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      desktop: desktop,
    );
  }

  // Get responsive EdgeInsets for padding
  static EdgeInsets getResponsiveEdgeInsets(
    BuildContext context, {
    required EdgeInsets mobile,
    required EdgeInsets tablet,
    required EdgeInsets largeTablet,
    required EdgeInsets desktop,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      return desktop;
    } else if (screenWidth > 900) {
      return largeTablet;
    } else if (screenWidth > 600) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // Check if current device is tablet or larger
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  // Check if current device is large tablet or desktop
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  // Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  // Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      return DeviceType.desktop;
    } else if (screenWidth > 900) {
      return DeviceType.largeTablet;
    } else if (screenWidth > 600) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }
}

enum DeviceType {
  mobile,
  tablet,
  largeTablet,
  desktop,
}
