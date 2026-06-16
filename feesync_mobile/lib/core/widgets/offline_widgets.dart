import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/network_service.dart';

// ── Offline Banner ────────────────────────────────────────────────────────────

/// A thin amber banner shown at the top of a screen when the device is
/// offline. Hides automatically when connectivity is restored.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? true;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isOnline
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('offline_banner'),
              width: double.infinity,
              color: const Color(0xFFB45309), // amber-700
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No internet connection — showing cached data',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── No Internet Screen ────────────────────────────────────────────────────────

/// Full-page friendly error for critical load failures when offline.
/// Shows a retry button that calls [onRetry].
class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const NoInternetScreen({
    super.key,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final textPrimary =
        isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB45309).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 44,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message ??
                      'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        'Try Again',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Retry Error Placeholder ───────────────────────────────────────────────────

/// Compact inline error widget with a retry button.
/// Use this inside dashboard card slots when a FutureProvider fails.
class RetryErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const RetryErrorPlaceholder({
    super.key,
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
