import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum DeviceLocationAccess { granted, denied, deniedForever, servicesOff }

/// A raw position from the platform, without Geolocator's type so tests and
/// the service do not depend on the plugin's model.
class DeviceFix {
  const DeviceFix(this.lat, this.lng, this.at);
  final double lat;
  final double lng;
  final DateTime at;
}

/// The edge between [LocationService] and the platform.
abstract class DeviceLocator {
  /// Current access. With [request], asks the user when the permission is
  /// still askable. Never throws.
  Future<DeviceLocationAccess> access({bool request = false});

  /// Whatever fix the platform already holds. Never wakes the GPS.
  Future<DeviceFix?> lastKnown();

  /// A real fix, or null on timeout / error.
  Future<DeviceFix?> current({
    required Duration timeLimit,
    required bool highAccuracy,
  });

  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorDeviceLocator implements DeviceLocator {
  const GeolocatorDeviceLocator();

  @override
  Future<DeviceLocationAccess> access({bool request = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return DeviceLocationAccess.servicesOff;
      }
      var permission = await Geolocator.checkPermission();
      if (request &&
          (permission == LocationPermission.denied ||
              permission == LocationPermission.unableToDetermine)) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return DeviceLocationAccess.granted;
        case LocationPermission.deniedForever:
          return DeviceLocationAccess.deniedForever;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return DeviceLocationAccess.denied;
      }
    } catch (_) {
      return DeviceLocationAccess.denied;
    }
  }

  @override
  Future<DeviceFix?> lastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : DeviceFix(p.latitude, p.longitude, p.timestamp);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DeviceFix?> current({
    required Duration timeLimit,
    required bool highAccuracy,
  }) async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.low,
          timeLimit: timeLimit,
        ),
        // Belt and braces: some platform implementations ignore timeLimit, and
        // an unbounded wait here would pin a spinner forever.
      ).timeout(timeLimit + const Duration(seconds: 2));
      return DeviceFix(p.latitude, p.longitude, DateTime.now());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }
}
