import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';
import '../../core/widgets/student_avatar.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<RecentTransaction> transactions;
  final NumberFormat currencyFormatter;
  final VoidCallback? onViewAll;

  const RecentTransactionsWidget({
    super.key,
    required this.transactions,
    required this.currencyFormatter,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final cardColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          _emptyState(isDark)
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: isDark ? 0.75 : 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.01),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                height: 16,
                indent: 12,
                endIndent: 12,
              ),
              itemBuilder: (context, index) => _TransactionTile(
                transaction: transactions[index],
                currencyFormatter: currencyFormatter,
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 40,
            color: textTertiaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions recorded today',
            style: GoogleFonts.inter(
              color: textTertiaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final RecentTransaction transaction;
  final NumberFormat currencyFormatter;

  const _TransactionTile({required this.transaction, required this.currencyFormatter});

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final successColor = isDark ? const Color(0xFFB4F0C5) : const Color(0xFF16A34A);

    // Resolve color code for payment methods
    Color methodColor = primaryColor;
    if (transaction.paymentMethod.toUpperCase() == 'CASH') {
      methodColor = const Color(0xFF10B981);
    } else if (transaction.paymentMethod.toUpperCase() == 'UPI' || transaction.paymentMethod.toUpperCase() == 'ONLINE') {
      methodColor = const Color(0xFF8B5CF6);
    }

    // Dynamic gradient background for initials avatar based on student name hash
    final initials = _getInitials(transaction.studentName);
    final nameHash = transaction.studentName.hashCode;
    final List<Color> avatarColors = [
      [const Color(0xFF2563EB), const Color(0xFF7C3AED)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      [const Color(0xFFEC4899), const Color(0xFFBE185D)],
      [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
    ][nameHash.abs() % 6];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // Premium Colored Initials Avatar
          StudentAvatar(
            studentId: transaction.studentName, // Fallback since we don't have ID here
            firstName: transaction.studentName.split(' ').first,
            radius: 26,
          ),
          const SizedBox(width: 16),
          // Transaction Details Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.studentName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Class pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.studentClass.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '•  ${transaction.feeType}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textTertiaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount & Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${currencyFormatter.format(transaction.amount)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: successColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: methodColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction.paymentMethod.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: textTertiaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• ${_formatTime(transaction.date)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textTertiaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inHours;
  if (difference < 1) return 'Just now';
  if (difference < 24) return '$difference hrs';
  if (difference < 48) return 'Yesterday';
  return DateFormat('MMM d').format(date);
}
