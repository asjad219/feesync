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
  bool _isCheckingInitialState = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Always lock on startup if any lock is enabled, but wait for settings to load first.
    // Cap at 5 s — if init hangs (e.g. slow storage), proceed anyway so we never freeze.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(localSettingsProvider.notifier)
          .initFuture
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // Settings didn't load in time — proceed with defaults.
            },
          )
          .then((_) {
        if (mounted) {
          _checkLock(isStartup: true).then((_) {
            if (mounted) {
              setState(() => _isCheckingInitialState = false);
            }
          });
        }
      }).catchError((_) {
        // Any other error — unblock the UI.
        if (mounted) setState(() => _isCheckingInitialState = false);
      });
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
    if (_isCheckingInitialState) {
      // Show an empty container that matches the dark background to prevent flashing the app content
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Container(color: const Color(0xFF0D0D1A)),
      );
    }

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
