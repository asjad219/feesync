import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/local_settings_provider.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(ref);
});

class AppLockService {
  final Ref _ref;
  final LocalAuthentication _auth = LocalAuthentication();

  AppLockService(this._ref);

  /// Checks if device has biometric hardware and is enrolled
  Future<bool> canUseBiometrics() async {
    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  /// Attempts to authenticate with Biometrics
  Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      // Just use the simplest signature that works across local_auth versions
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } catch (e) {
      return false;
    }
  }

  /// Hashes a PIN using SHA-256
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Checks if a provided PIN matches the saved PIN hash
  bool verifyPin(String pin) {
    final settings = _ref.read(localSettingsProvider);
    if (settings.pinHash == null) return false;
    final inputHash = hashPin(pin);
    return inputHash == settings.pinHash;
  }
}
