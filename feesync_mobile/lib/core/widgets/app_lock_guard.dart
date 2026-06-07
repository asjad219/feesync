import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/local_settings_provider.dart';
import '../../services/app_lock_service.dart';
import '../../screens/settings/screens/pin_lock_screen.dart';

class AppLockGuard extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGuard({super.key, required this.child});

  @override
  ConsumerState<AppLockGuard> createState() => _AppLockGuardState();
}

class _AppLockGuardState extends ConsumerState<AppLockGuard>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Always lock on startup if any lock is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLock(isStartup: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isLocked) {
        // App was locked while in background (or startup), try biometric auth again
        _tryBiometricUnlock();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final settings = ref.read(localSettingsProvider);
      if ((settings.biometricEnabled || settings.pinLockEnabled) && settings.lockOnMinimize) {
        if (!_isLocked && !_isAuthenticating) {
          setState(() {
            _isLocked = true;
          });
        }
      }
    }
  }

  Future<void> _checkLock({required bool isStartup}) async {
    if (_isAuthenticating) return;

    final settings = ref.read(localSettingsProvider);
    if (!settings.biometricEnabled && !settings.pinLockEnabled) {
      if (_isLocked) setState(() => _isLocked = false);
      return;
    }

    if (isStartup || settings.lockOnMinimize) {
      if (!_isLocked) {
        setState(() => _isLocked = true);
      }
      await _tryBiometricUnlock();
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final settings = ref.read(localSettingsProvider);
    if (!settings.biometricEnabled || _isAuthenticating) return;

    _isAuthenticating = true;
    final authService = ref.read(appLockServiceProvider);
    final canUse = await authService.canUseBiometrics();
    if (canUse) {
      final success = await authService.authenticateWithBiometrics('Unlock FeeSync');
      if (success && mounted) {
        setState(() {
          _isLocked = false;
          _isAuthenticating = false;
        });
        return; // Unlocked successfully
      }
    }
    _isAuthenticating = false;
  }

  void _unlock() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PinLockScreen(
        mode: PinLockMode.verify,
        onSuccess: _unlock,
        canCancel: false,
      ),
    );
  }
}
