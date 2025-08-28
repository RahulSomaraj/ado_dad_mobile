// lib/common/startup_connectivity_gate.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/material.dart';

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
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _doCheck();
    // Listen for interface changes ONLY until we pass the gate
    _sub = Connectivity().onConnectivityChanged.listen((_) {
      if (!_passedGate) _doCheck();
    });
  }

  Future<void> _doCheck() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final iface = await Connectivity().checkConnectivity();
      final hasInterface = iface != ConnectivityResult.none;

      bool hasInternet = false;
      if (hasInterface) {
        // Real reachability (handles emulator “fake connected” case)
        hasInternet = await InternetConnection().hasInternetAccess;
      }

      if (!mounted) return;

      if (hasInternet) {
        _sub?.cancel();
        setState(() {
          _passedGate = true; // ✅ proceed to Login and rest of app
          _checking = false;
        });
        widget.onBackOnline?.call();
      } else {
        setState(() {
          _checking = false;
          _error = "You're offline. Enable Wi-Fi/Mobile Data and retry.";
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = "Unable to verify connection. Try again.";
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_passedGate) return widget.child;

    return Scaffold(
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
                if (_checking)
                  const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
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
