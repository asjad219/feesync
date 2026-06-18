import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/network_service.dart';
import '../../providers/providers.dart';

class OfflineScreen extends ConsumerStatefulWidget {
  final String? fromPath;
  const OfflineScreen({super.key, this.fromPath});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  bool _isRetrying = false;

  Future<void> _retryConnection() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    final isConnected = await ref.read(networkServiceProvider).isConnected;
    if (isConnected) {
      // Trigger background refreshes
      try {
        await Future.wait([
          ref.read(dashboardStatsProvider.notifier).fetch(),
          ref.read(studentBalancesProvider.notifier).loadStudents(),
          ref.read(batchNotifierProvider.notifier).loadBatches(),
          ref.read(paymentNotifierProvider.notifier).loadPayments(),
          ref.read(settingsProvider.notifier).loadSettings(),
        ]);
      } catch (e) {
        debugPrint('[OfflineScreen] Sync failed: $e');
      }

      if (mounted) {
        if (widget.fromPath != null && widget.fromPath!.isNotEmpty) {
          context.go(widget.fromPath!);
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
    } else {
      if (mounted) {
        setState(() => _isRetrying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 10),
                Text(
                  "Still offline. Please check your network.",
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Automatically restore and navigate back if connection is restored in background
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      final isOnline = next.value ?? false;
      if (isOnline) {
        _retryConnection();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off,
                    size: 80,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "📡 No Internet Connection",
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Please check your network and try again.",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _isRetrying
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _retryConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Retry",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
