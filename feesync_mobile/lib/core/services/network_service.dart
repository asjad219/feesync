import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight service that tracks network reachability.
class NetworkService {
  final Connectivity _connectivity = Connectivity();

  /// Returns true if the device currently has any network interface.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Stream of connectivity changes (emits true = online, false = offline).
  Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

/// Reactive provider — true when device has a network interface.
/// Starts with an AsyncLoading state until the first check resolves.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(networkServiceProvider);

  // Emit initial connectivity state immediately.
  yield await service.isConnected;

  // Then emit on every change.
  yield* service.connectivityStream;
});
