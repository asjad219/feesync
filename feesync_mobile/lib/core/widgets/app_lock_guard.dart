import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/local_settings_provider.dart';
import '../../services/app_lock_service.dart';
import '../../screens/settings/screens/pin_lock_screen.dart';

/// Guards the app with biometric/PIN lock when security settings are enabled.
///
/// Design principle: the [child] is ALWAYS rendered — we never block it with an
/// invisible placeholder. When a lock is required the [PinLockScreen] is shown
/// as a full-screen overlay on top of [child] via a [Stack]. This eliminates
/// the black-screen flash that occurred when the old implementation replaced the
/// entire widget tree with [SizedBox.shrink()] during the async init check.
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
    // Run after the first frame so the child (splash/login) is already visible.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initLock() async {
    try {
      // Wait for local settings to load (max 5 s).
      await ref
          .read(localSettingsProvider.notifier)
          .initFuture
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Timeout or error — treat as no lock needed.
    }

    if (!mounted) return;

    final settings = ref.read(localSettingsProvider);
    if (!settings.biometricEnabled && !settings.pinLockEnabled) {
      // No lock configured — nothing to do.
      return;
    }

    // Lock is configured — show the lock screen and attempt biometric unlock.
    if (mounted) setState(() => _isLocked = true);
    await _tryBiometricUnlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isLocked) _tryBiometricUnlock();
    } else if (state == AppLifecycleState.paused) {
      final settings = ref.read(localSettingsProvider);
      if ((settings.biometricEnabled || settings.pinLockEnabled) &&
          settings.lockOnMinimize) {
        if (!_isLocked && !_isAuthenticating) {
          setState(() => _isLocked = true);
        }
      }
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final settings = ref.read(localSettingsProvider);
    if (!settings.biometricEnabled || _isAuthenticating) return;

    _isAuthenticating = true;
    try {
      final authService = ref.read(appLockServiceProvider);
      final canUse = await authService.canUseBiometrics();
      if (canUse) {
        final success =
            await authService.authenticateWithBiometrics('Unlock FeeSync');
        if (success && mounted) {
          setState(() {
            _isLocked = false;
            _isAuthenticating = false;
          });
          return;
        }
      }
    } catch (_) {
      // Biometric failed — fall back to PIN.
    }
    _isAuthenticating = false;
  }

  void _unlock() {
    if (mounted) setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    // Always render the child so the app content (splash, login, dashboard)
    // is never blocked. The lock screen appears as an overlay when needed.
    if (!_isLocked) {
      return widget.child;
    }

    // Overlay the full-screen lock screen on top of the child.
    return Stack(
      children: [
        // Keep child alive underneath so it doesn't lose state.
        Offstage(child: widget.child),
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: PinLockScreen(
            mode: PinLockMode.verify,
            onSuccess: _unlock,
            canCancel: false,
          ),
        ),
      ],
    );
  }
}
