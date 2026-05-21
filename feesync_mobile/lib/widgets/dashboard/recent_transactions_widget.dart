import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<RecentTransaction> transactions;
  final VoidCallback? onViewAll;

  const RecentTransactionsWidget({
    super.key,
    required this.transactions,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No transactions yet',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _TransactionTile(transaction: transaction);
            },
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final RecentTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatTime(transaction.date);
    final amountLabel = NumberFormat.currency(
      name: 'INR',
      symbol: 'INR ',
      decimalDigits: 0,
    ).format(transaction.amount);
    final subtitle = _buildSubtitle(transaction);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.payments,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.studentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+$amountLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
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

  if (difference < 1) {
    return 'Just now';
  }

  if (difference < 24) {
    return '$difference hours ago';
  }

  if (difference < 48) {
    return 'Yesterday';
  }

  return DateFormat('MMM d').format(date);
}

String _buildSubtitle(RecentTransaction transaction) {
  final feeType = transaction.feeType.trim();
  final studentClass = transaction.studentClass.trim();
  final paymentMethod = transaction.paymentMethod.trim();

  final parts = <String>[
    if (feeType.isNotEmpty) feeType,
    if (studentClass.isNotEmpty) studentClass,
    if (paymentMethod.isNotEmpty) paymentMethod,
  ];

  if (parts.isEmpty) {
    return 'Payment received';
  }

  return parts.join(' • ');
}
