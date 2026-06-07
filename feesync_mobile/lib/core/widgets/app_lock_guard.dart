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
    // Lock on startup if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLock();
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
      _checkLock();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final settings = ref.read(localSettingsProvider);
      if (settings.biometricEnabled || settings.pinLockEnabled) {
        if (!_isLocked && !_isAuthenticating) {
          setState(() {
            _isLocked = true;
          });
        }
      }
    }
  }

  Future<void> _checkLock() async {
    if (_isAuthenticating) return;

    final settings = ref.read(localSettingsProvider);
    if (!settings.biometricEnabled && !settings.pinLockEnabled) {
      if (_isLocked) setState(() => _isLocked = false);
      return;
    }

    if (!_isLocked) {
      setState(() => _isLocked = true);
    }

    // Try biometric first if enabled
    if (settings.biometricEnabled) {
      _isAuthenticating = true;
      final authService = ref.read(appLockServiceProvider);
      final canUse = await authService.canUseBiometrics();
      if (canUse) {
        final success = await authService.authenticateWithBiometrics(
            'Unlock FeeSync');
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
    
    // If we reach here, we are locked. The UI will show the PIN screen 
    // or a prompt to retry biometrics if PIN is disabled.
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
