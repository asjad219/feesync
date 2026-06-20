import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight network reachability service.
///
/// Uses two-stage detection:
/// 1. `connectivity_plus` — fast check for any network interface.
/// 2. TCP socket probe — confirms actual internet access (not just connected interface).
///
/// This prevents false "offline" states on poor/slow networks (2G, congested WiFi,
/// captive portals) where the interface is up but the internet is unreachable.
class NetworkService {
  final Connectivity _connectivity = Connectivity();

  // Probe targets — tries Supabase domain first, falls back to Google DNS
  static const _probeHosts = ['8.8.8.8', '1.1.1.1'];
  static const _probePort = 53;
  static const _probeTimeout = Duration(seconds: 4);
  static const _debounceDelay = Duration(seconds: 2);

  /// Returns true if the device has a working internet connection.
  /// Combines interface check + socket probe for accuracy.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (!_hasInterface(results)) return false;
    return _probeInternet();
  }

  /// Stream of connectivity changes (true = online, false = offline).
  /// Debounced by [_debounceDelay] to suppress momentary blips.
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged
        .asyncMap((_) => isConnected)
        .distinct()
        .debounce(_debounceDelay);
  }

  /// Checks if any usable network interface is available.
  bool _hasInterface(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  /// Performs a TCP socket probe to verify actual internet reachability.
  /// Returns true if any probe host is reachable within the timeout.
  Future<bool> _probeInternet() async {
    for (final host in _probeHosts) {
      try {
        final socket = await Socket.connect(
          host,
          _probePort,
          timeout: _probeTimeout,
        );
        socket.destroy();
        return true;
      } catch (_) {
        // Try next host
      }
    }
    return false;
  }
}

// ── Stream Extension ─────────────────────────────────────────────────────────

extension _StreamDebounce<T> on Stream<T> {
  Stream<T> debounce(Duration delay) {
    StreamController<T>? controller;
    Timer? debounceTimer;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          (value) {
            debounceTimer?.cancel();
            debounceTimer = Timer(delay, () {
              if (!(controller?.isClosed ?? true)) {
                controller?.add(value);
              }
            });
          },
          onError: controller?.addError,
          onDone: () {
            debounceTimer?.cancel();
            controller?.close();
          },
        );
      },
      onCancel: () {
        debounceTimer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

/// Reactive provider — true when device has working internet (interface + probe).
/// Starts with an AsyncLoading state until the first check resolves.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(networkServiceProvider);

  // Emit initial connectivity state immediately.
  final initialState = await service.isConnected;
  debugPrint('[Network] Initial connectivity: $initialState');
  yield initialState;

  // Then emit on every debounced change.
  yield* service.connectivityStream.where((isOnline) {
    debugPrint('[Network] Connectivity changed: $isOnline');
    return true;
  });
});
