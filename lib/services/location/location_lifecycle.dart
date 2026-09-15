import 'dart:async';

import 'package:ado_dad_user/services/location_service.dart';
import 'package:flutter/widgets.dart';

/// Refreshes a followed device location whenever the app returns to the
/// foreground — from any screen, not only while Home is mounted.
///
/// Debounced: Android reports `resumed` for transient things too (a dismissed
/// permission sheet, the app switcher), and the service already ignores manual
/// places and fresh fixes, so one call per real return is enough.
class LocationLifecycle with WidgetsBindingObserver {
  LocationLifecycle._();
  static final LocationLifecycle instance = LocationLifecycle._();

  bool _attached = false;
  Timer? _debounce;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 1), () {
        unawaited(LocationService().refreshIfFollowing());
      });
    } else if (state == AppLifecycleState.paused) {
      _debounce?.cancel();
    }
  }
}
