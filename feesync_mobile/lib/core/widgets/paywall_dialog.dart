import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';

/// Describes which limit was hit — controls copy & icon in the dialog.
enum PaywallTrigger { studentLimit, batchLimit }

/// Shows a premium paywall bottom sheet when a free-plan limit is hit.
/// Returns `true` if the user upgrades (navigate to subscription screen),
/// `false` or null if they dismiss.
Future<bool?> showPaywallDialog(
  BuildContext context,
  WidgetRef ref, {
  required PaywallTrigger trigger,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaywallSheet(trigger: trigger, ref: ref),
  );
}

class _PaywallSheet extends StatelessWidget {
  final PaywallTrigger trigger;
  final WidgetRef ref;

  const _PaywallSheet({required this.trigger, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(subscriptionScreenDataProvider);
    final plan = SubscriptionPlan.free;
    final isStudent = trigger == PaywallTrigger.studentLimit;

    final int limit = isStudent ? plan.maxStudents : plan.maxBatches;
    final String itemName = isStudent ? 'students' : 'batches';
    final IconData icon =
        isStudent ? Icons.people_alt_rounded : Icons.layers_rounded;

    final int currentCount = dataAsync.whenOrNull(
          data: (d) =>
              isStudent ? d.activeStudentCount : d.activeBatchCount,
        ) ??
        limit;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Handle ───────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Icon ─────────────────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),

          // ─── Headline ─────────────────────────────────────────────────────
          Text(
            isStudent ? 'Student Limit Reached!' : 'Batch Limit Reached!',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'You\'ve reached the '),
                TextSpan(
                  text: 'Free plan limit of $limit $itemName',
                  style: const TextStyle(
                    color: Color(0xFFDB2777),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: isStudent
                      ? '. You currently have $currentCount active student${currentCount == 1 ? '' : 's'}.'
                      : '. You currently have $currentCount batch${currentCount == 1 ? '' : 'es'}.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── What you get ─────────────────────────────────────────────────
          _buildBenefitRow(
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF2563EB),
            text: isStudent
                ? 'Starter: up to 200 students'
                : 'Starter: up to 15 batches',
            highlight: 'Starter',
          ),
          const SizedBox(height: 10),
          _buildBenefitRow(
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF8B5CF6),
            text: isStudent
                ? 'Growth: unlimited students'
                : 'Growth: unlimited batches',
            highlight: 'Growth',
          ),
          const SizedBox(height: 10),
          _buildBenefitRow(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF10B981),
            text: 'AI features, WhatsApp & more',
            highlight: null,
          ),
          const SizedBox(height: 28),

          // ─── CTA button ───────────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.pop(context, true);
              context.push('/settings/subscription');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Upgrade Plan — View Options',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── Dismiss ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Maybe later',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required Color color,
    required String text,
    required String? highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: highlight != null
                ? RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      children: _buildHighlightedText(text, highlight, color),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 16),
        ],
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(
      String text, String highlight, Color color) {
    final idx = text.indexOf(highlight);
    if (idx < 0) return [TextSpan(text: text)];
    return [
      if (idx > 0) TextSpan(text: text.substring(0, idx)),
      TextSpan(
        text: highlight,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (idx + highlight.length < text.length)
        TextSpan(text: text.substring(idx + highlight.length)),
    ];
  }
}
