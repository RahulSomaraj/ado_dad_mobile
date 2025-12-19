// lib/common/startup_connectivity_gate.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/material.dart';
import 'package:ado_dad_user/common/get_responsive_size.dart';

class StartupConnectivityGate extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBackOnline;
  const StartupConnectivityGate(
      {super.key, required this.child, this.onBackOnline});

  @override
  State<StartupConnectivityGate> createState() =>
      _StartupConnectivityGateState();
}

class _StartupConnectivityGateState extends State<StartupConnectivityGate> {
  bool _passedGate = false; // once true, we never show again this session
  bool _checking = true;
  String? _error;
  // Use dynamic type on iOS to avoid ConnectivityResult dependency
  StreamSubscription? _sub;
  Timer? _maxTimeoutTimer;
  Timer? _periodicCheckTimer; // For iOS fallback when stream fails

  @override
  void initState() {
    super.initState();

    // Maximum timeout: Give enough time for connectivity check to complete
    // This is a fallback - if check completes, it will cancel this timer
    final timeoutDuration = Platform.isIOS
        ? const Duration(seconds: 3) // iOS: give more time for check
        : const Duration(seconds: 2); // Android: standard timeout

    _maxTimeoutTimer = Timer(timeoutDuration, () {
      // Only pass gate via timeout if still checking (check didn't complete)
      if (mounted && !_passedGate && _checking) {
        debugPrint(
            '⏰ [ConnectivityGate] Timeout reached (${Platform.isIOS ? "iOS" : "Android"}) - allowing app to proceed');
        _sub?.cancel();
        setState(() {
          _passedGate = true;
          _checking = false;
        });
        widget.onBackOnline?.call();
        debugPrint('✅ [ConnectivityGate] Gate passed via timeout');
      }
    });

    // Run check asynchronously without blocking
    Future.microtask(() {
      _doCheck();
    });

    // Set up connectivity stream listener
    // On iOS, skip the stream listener entirely to avoid MissingPluginException
    // Use periodic checks instead which are more reliable on iOS
    if (Platform.isIOS) {
      // iOS: Use periodic checks instead of stream listener to avoid plugin initialization issues
      // The stream listener can fail with MissingPluginException on iOS due to timing issues
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _startPeriodicChecks();
        }
      });
    } else {
      // Android: set up stream listener immediately
      _setupConnectivityListener();
    }
  }

  /// Set up connectivity stream listener with error handling
  /// Only used on Android - iOS uses periodic checks instead
  void _setupConnectivityListener() {
    // Only set up on non-iOS platforms
    if (Platform.isIOS) {
      debugPrint('⚠️ [ConnectivityGate] Skipping stream listener on iOS');
      return;
    }

    try {
      // Listen for interface changes ONLY until we pass the gate
      // Use dynamic to avoid type issues if connectivity_plus isn't available
      final connectivity = Connectivity();
      _sub = connectivity.onConnectivityChanged.listen(
        (_) {
          if (!_passedGate && mounted) {
            _doCheck();
          }
        },
        onError: (error) {
          // On Android, if stream fails, fall back to periodic checks
          debugPrint('⚠️ [ConnectivityGate] Connectivity stream error: $error');
          _sub?.cancel();
          _sub = null;
          _startPeriodicChecks();
        },
        cancelOnError: false, // Don't cancel subscription on error
      );
    } catch (e) {
      // If stream setup fails, fall back to periodic checks
      debugPrint(
          '❌ [ConnectivityGate] Unexpected error setting up listener: $e');
      _startPeriodicChecks();
    }
  }

  /// Start periodic connectivity checks
  /// Used on iOS as primary method, and as fallback on Android if stream fails
  void _startPeriodicChecks() {
    if (_periodicCheckTimer != null) return; // Already running

    debugPrint(
        '🔄 [ConnectivityGate] Starting periodic connectivity checks (${Platform.isIOS ? "iOS" : "Android fallback"})');
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_passedGate && mounted) {
        _doCheck();
      } else {
        timer.cancel();
        _periodicCheckTimer = null;
      }
    });
  }

  Future<void> _doCheck() async {
    if (!mounted) {
      debugPrint('⚠️ [ConnectivityGate] Not mounted, skipping check');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      if (Platform.isIOS) {
        // iOS-specific connectivity check with retry logic
        await _doCheckIOS();
      } else {
        // Android and other platforms - standard check
        await _doCheckStandard();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ConnectivityGate] ERROR during check: $e');
      debugPrint('❌ [ConnectivityGate] Stack trace: $stackTrace');
      if (!mounted) return;
      // On any error, let the max timeout handle proceeding
      // Don't show error immediately, let it timeout
    }
  }

  /// iOS-specific connectivity check with retry logic
  /// Completely avoids connectivity_plus plugin to prevent MissingPluginException
  /// Uses only InternetConnectionCheckerPlus which works independently
  Future<void> _doCheckIOS() async {
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        // iOS: Skip connectivity_plus entirely and check internet directly
        // This avoids MissingPluginException since connectivity_plus isn't initialized
        debugPrint(
            '🌐 [ConnectivityGate] iOS checking internet access directly...');

        bool hasInternet = false;
        try {
          hasInternet = await InternetConnection()
              .hasInternetAccess
              .timeout(const Duration(milliseconds: 500), onTimeout: () {
            debugPrint('⏰ [ConnectivityGate] iOS internet check timed out');
            return false;
          });
          debugPrint('🌐 [ConnectivityGate] iOS has internet: $hasInternet');
        } catch (e) {
          debugPrint('❌ [ConnectivityGate] iOS internet check error: $e');
          final errorMsg = e.toString();

          // Check if it's a channel/platform error
          if (errorMsg.contains('channel-error') ||
              errorMsg.contains('PlatformException') ||
              errorMsg.contains('MissingPluginException') ||
              errorMsg.contains('Unable to establish connection')) {
            retries++;
            if (retries < maxRetries) {
              debugPrint(
                  '🔄 [ConnectivityGate] iOS channel error, retrying... (${retries}/$maxRetries)');
              await Future.delayed(Duration(milliseconds: 300 * retries));
              continue;
            } else {
              // Max retries reached - let timeout handle it
              debugPrint(
                  '⏳ [ConnectivityGate] iOS max retries reached, waiting for timeout');
              return;
            }
          }
          hasInternet = false;
        }

        if (!mounted) {
          debugPrint('⚠️ [ConnectivityGate] Not mounted after iOS check');
          return;
        }

        if (hasInternet) {
          debugPrint(
              '✅ [ConnectivityGate] iOS internet confirmed - passing gate');
          _sub?.cancel();
          _maxTimeoutTimer?.cancel();
          _periodicCheckTimer?.cancel();
          setState(() {
            _passedGate = true;
            _checking = false;
          });
          widget.onBackOnline?.call();
          return;
        } else {
          debugPrint('⚠️ [ConnectivityGate] iOS no internet access');
          // No internet - retry or wait for timeout
          retries++;
          if (retries < maxRetries) {
            debugPrint(
                '🔄 [ConnectivityGate] iOS no internet, retrying... (${retries}/$maxRetries)');
            await Future.delayed(Duration(milliseconds: 300 * retries));
            continue;
          } else {
            // After max retries, show error screen
            if (!mounted) return;
            _maxTimeoutTimer?.cancel(); // Cancel timeout - user needs to retry
            setState(() {
              _checking = false;
              _error =
                  "No internet connection. Please check your Wi-Fi or Mobile Data and retry.";
            });
            debugPrint('📱 [ConnectivityGate] iOS showing no internet error');
            return;
          }
        }
      } catch (e) {
        retries++;
        final errorMsg = e.toString();
        debugPrint(
            '❌ [ConnectivityGate] iOS check attempt ${retries} failed: $e');

        // Check if it's a channel/platform error
        if (errorMsg.contains('channel-error') ||
            errorMsg.contains('PlatformException') ||
            errorMsg.contains('MissingPluginException') ||
            errorMsg.contains('Unable to establish connection')) {
          if (retries < maxRetries) {
            debugPrint('🔄 [ConnectivityGate] iOS channel error, retrying...');
            await Future.delayed(Duration(milliseconds: 300 * retries));
            continue;
          }
        }

        // If not a channel error or max retries reached, break and let timeout handle it
        if (retries >= maxRetries) {
          debugPrint(
              '⏳ [ConnectivityGate] iOS max retries reached, waiting for timeout');
          return;
        }
      }
    }
  }

  /// Standard connectivity check for Android and other platforms
  /// Uses retry logic similar to iOS for consistency
  Future<void> _doCheckStandard() async {
    // On iOS, this should never be called, but add safety check
    if (Platform.isIOS) {
      debugPrint(
          '⚠️ [ConnectivityGate] _doCheckStandard called on iOS, redirecting to iOS check');
      await _doCheckIOS();
      return;
    }

    int retries = 0;
    const maxRetries = 2; // Android typically needs fewer retries

    while (retries < maxRetries) {
      try {
        // Quick connectivity check with timeout
        // Wrap in try-catch to handle MissingPluginException gracefully
        List<ConnectivityResult> iface;
        try {
          final connectivity = Connectivity();
          iface = await connectivity
              .checkConnectivity()
              .timeout(const Duration(milliseconds: 500), onTimeout: () {
            return [ConnectivityResult.none];
          });
        } catch (e) {
          debugPrint('❌ [ConnectivityGate] Connectivity check failed: $e');
          // If connectivity_plus fails, fall back to direct internet check
          iface = [ConnectivityResult.none];
        }

        final hasInterface =
            iface.isNotEmpty && iface.first != ConnectivityResult.none;

        bool hasInternet = false;
        if (hasInterface) {
          // Real reachability (handles emulator "fake connected" case)
          try {
            hasInternet = await InternetConnection()
                .hasInternetAccess
                .timeout(const Duration(milliseconds: 500), onTimeout: () {
              return false;
            });
          } catch (e) {
            debugPrint('❌ [ConnectivityGate] Internet check error: $e');
            // If timeout or error, assume no internet
            hasInternet = false;
          }
        }

        if (!mounted) {
          debugPrint(
              '⚠️ [ConnectivityGate] Not mounted after check, returning');
          return;
        }

        if (hasInternet) {
          _sub?.cancel();
          _maxTimeoutTimer?.cancel();
          setState(() {
            _passedGate = true; // ✅ proceed to Login and rest of app
            _checking = false;
          });
          widget.onBackOnline?.call();
          return;
        } else {
          debugPrint(
              '⚠️ [ConnectivityGate] No internet - hasInterface: $hasInterface');
          // If we have interface but no internet, show error screen immediately
          if (hasInterface) {
            if (!mounted) return;
            _maxTimeoutTimer?.cancel(); // Cancel timeout - user needs to retry
            setState(() {
              _checking = false;
              _error = "You're offline. Enable Wi-Fi/Mobile Data and retry.";
            });
            debugPrint('📱 [ConnectivityGate] Showing offline error');
            return;
          } else {
            // No interface - retry or show error
            retries++;
            if (retries < maxRetries) {
              await Future.delayed(Duration(milliseconds: 200 * retries));
              continue;
            } else {
              // After max retries, show error screen
              if (!mounted) return;
              _maxTimeoutTimer
                  ?.cancel(); // Cancel timeout - user needs to retry
              setState(() {
                _checking = false;
                _error =
                    "No network connection. Please check your Wi-Fi or Mobile Data and retry.";
              });
              debugPrint('📱 [ConnectivityGate] Showing no interface error');
              return;
            }
          }
        }
      } catch (e) {
        retries++;
        final errorMsg = e.toString();
        debugPrint('❌ [ConnectivityGate] Check attempt ${retries} failed: $e');

        // Check if it's a channel/platform error
        if (errorMsg.contains('channel-error') ||
            errorMsg.contains('PlatformException') ||
            errorMsg.contains('Unable to establish connection')) {
          if (retries < maxRetries) {
            debugPrint('🔄 [ConnectivityGate] Channel error, retrying...');
            await Future.delayed(Duration(milliseconds: 200 * retries));
            continue;
          }
        }

        // If not a channel error or max retries reached, show error screen
        if (retries >= maxRetries) {
          if (!mounted) return;
          _maxTimeoutTimer?.cancel();
          setState(() {
            _checking = false;
            _error =
                "Unable to check connectivity. Please check your network and retry.";
          });
          debugPrint('📱 [ConnectivityGate] Showing connectivity check error');
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _maxTimeoutTimer?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always show the child widget - connectivity check happens in background
    // Only show connectivity screen if explicitly offline and user needs to retry
    if (_passedGate || _checking) {
      return SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          bottom: GetResponsiveSize.getResponsiveSize(
            context,
            mobile: 50,
            tablet: 50,
            largeTablet: 50,
            desktop: 60,
          ),
        ),
        child: widget.child,
      );
    }

    // Only show connectivity error screen if check completed and no internet
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Checking connectivity…',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _doCheck,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
