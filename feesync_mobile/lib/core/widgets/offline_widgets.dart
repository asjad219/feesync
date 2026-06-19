import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/network_service.dart';
import '../../providers/sync_provider.dart';

// ── Offline Banner ────────────────────────────────────────────────────────────

/// Amber banner shown when the device is offline.
/// Shows the most recent sync time below the message.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? true;

    if (isOnline) return const SizedBox.shrink();

    final syncTimes = ref.watch(lastSyncTimesProvider);
    // Pick the most recent sync time across all entities
    DateTime? latestSync;
    for (final dt in syncTimes.values) {
      if (dt != null && (latestSync == null || dt.isAfter(latestSync))) {
        latestSync = dt;
      }
    }

    // Removed synchronous CacheService read since it is now async and backed by SQLite.
    // The session's lastSyncTimesProvider is sufficient for real-time updates.

    final syncLabel = latestSync != null
        ? 'Last synced: ${_formatSyncTime(latestSync)}'
        : 'Not synced yet — connect to download data';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: const ValueKey('offline_banner'),
        width: double.infinity,
        color: const Color(0xFFB45309),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No internet — showing cached data',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  syncLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}

// ── Shimmer Loading Card ──────────────────────────────────────────────────────

/// Animated shimmer skeleton — replaces CircularProgressIndicator in cards.
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 28,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFE2E8F0);
    final shimmerColor = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, shimmerColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer skeleton for a stats grid (matches the dashboard bento layout).
class ShimmerStatsGrid extends StatelessWidget {
  const ShimmerStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerCard(height: 200),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: ShimmerCard(height: 100)),
            SizedBox(width: 16),
            Expanded(child: ShimmerCard(height: 100)),
          ],
        ),
      ],
    );
  }
}

/// Shimmer skeleton for a list of items.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: itemHeight, borderRadius: 16),
        ),
      ),
    );
  }
}

// ── Offline Empty State ───────────────────────────────────────────────────────

/// Shown when no cached data exists and the device is offline.
class OfflineEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const OfflineEmptyState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB45309).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  title ?? 'No Internet Connection',
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
                      'No internet connection.\nConnect once to download your data.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: textSecondary,
                    height: 1.6,
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

// ── No Internet Screen ────────────────────────────────────────────────────────

/// Full-page offline screen — used only for hard failures.
class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const NoInternetScreen({super.key, this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return OfflineEmptyState(
      title: 'No Internet Connection',
      message:
          message ?? 'Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }
}

// ── Retry Error Placeholder ───────────────────────────────────────────────────

/// Compact inline error widget with a retry button.
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

// ── Offline snackbar helper ───────────────────────────────────────────────────

/// Shows a friendly snackbar when attempting a write action while offline.
void showOfflineWriteSnackbar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Text(
            "You're offline. Connect to perform this action.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB45309),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Shows a professional offline popup dialog when offline.
void showOfflineDialog(BuildContext context, {VoidCallback? onRetry}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
  final textPrimary = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
  final textSecondary = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFB45309), size: 28),
          const SizedBox(width: 12),
          Text(
            'Connection Offline',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'You are currently offline. Some features may be unavailable, but you can continue browsing your cached students, batches, and dashboard data.',
        style: GoogleFonts.inter(color: textSecondary, height: 1.5, fontSize: 14),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Dismiss',
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onRetry();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}


