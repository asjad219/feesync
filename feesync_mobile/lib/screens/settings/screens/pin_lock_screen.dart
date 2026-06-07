import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/local_settings_provider.dart';
import '../../../services/app_lock_service.dart';

enum PinLockMode { setup, verify }

class PinLockScreen extends ConsumerStatefulWidget {
  final PinLockMode mode;
  final VoidCallback? onSuccess;
  final bool canCancel;

  const PinLockScreen({
    super.key,
    required this.mode,
    this.onSuccess,
    this.canCancel = true,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorText = '';

  void _onKeyPress(String key) {
    if (_pin.length < 4 && !_isConfirming) {
      setState(() {
        _pin += key;
        _errorText = '';
      });
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _processPin();
        });
      }
    } else if (_confirmPin.length < 4 && _isConfirming) {
      setState(() {
        _confirmPin += key;
        _errorText = '';
      });
      if (_confirmPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _processPin();
        });
      }
    }
  }

  void _onDelete() {
    setState(() {
      if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
      _errorText = '';
    });
  }

  Future<void> _processPin() async {
    final appLockService = ref.read(appLockServiceProvider);
    final settingsNotifier = ref.read(localSettingsProvider.notifier);

    if (widget.mode == PinLockMode.setup) {
      if (!_isConfirming) {
        setState(() => _isConfirming = true);
      } else {
        if (_pin == _confirmPin) {
          // Setup success
          final hash = appLockService.hashPin(_pin);
          await settingsNotifier.updatePinHash(hash);
          await settingsNotifier.updatePinLockEnabled(true);
          
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (mounted) {
            context.pop(true);
          }
        } else {
          // Mismatch
          setState(() {
            _errorText = 'PINs do not match. Try again.';
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    } else if (widget.mode == PinLockMode.verify) {
      final isValid = appLockService.verifyPin(_pin);
      if (isValid) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (mounted) {
          context.pop(true);
        }
      } else {
        setState(() {
          _errorText = 'Incorrect PIN. Try again.';
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode;
    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    String title;
    String subtitle;
    String activePin = _isConfirming ? _confirmPin : _pin;

    if (widget.mode == PinLockMode.setup) {
      title = _isConfirming ? 'Confirm PIN' : 'Create PIN';
      subtitle = _isConfirming ? 'Re-enter your 4-digit PIN' : 'Enter a 4-digit PIN to secure your app';
    } else {
      title = 'Enter PIN';
      subtitle = 'Enter your 4-digit PIN to unlock';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.canCancel
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: textPrimary),
                onPressed: () {
                  if (widget.onSuccess == null) {
                    context.pop(false);
                  }
                },
              )
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < activePin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppColors.primary : AppColors.textTertiary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            if (_errorText.isNotEmpty)
              Text(
                _errorText,
                style: GoogleFonts.inter(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600),
              )
            else
              const SizedBox(height: 20),
              
            const Spacer(),
            
            // Numpad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var j = 1; j <= 3; j++)
                            _buildKey((i * 3 + j).toString(), textPrimary, bg),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 72), // Empty space
                      _buildKey('0', textPrimary, bg),
                      _buildDeleteKey(textPrimary, bg),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String label, Color textColor, Color bgColor) {
    return GestureDetector(
      onTap: () => _onKeyPress(label),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: textColor.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(Color textColor, Color bgColor) {
    return GestureDetector(
      onTap: _onDelete,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: textColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}
