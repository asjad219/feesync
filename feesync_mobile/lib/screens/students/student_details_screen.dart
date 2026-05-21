import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../models/student.dart';
import '../../models/payment.dart';
import '../../providers/providers.dart';
import '../../core/utils/currency_formatter.dart';

import 'package:url_launcher/url_launcher.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentByIdProvider(studentId));
    final balanceAsync = ref.watch(studentBalanceByIdProvider(studentId));
    final paymentsAsync = ref.watch(studentPaymentsProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: [
          IconButton(
            onPressed: () => context.push('/students/edit/$studentId'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref),
            icon: Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) return const Center(child: Text('Student not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(student, balanceAsync.value),
                const SizedBox(height: 24),
                _buildMetricsGrid(balanceAsync.value),
                const SizedBox(height: 24),
                _buildTabs(),
                const SizedBox(height: 16),
                _buildRecentPayments(paymentsAsync),
                const SizedBox(height: 24),
                _buildContactInfo(student),
                const SizedBox(height: 32),
                _buildActions(context, student),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfileHeader(Student student, StudentBalance? balance) {
    final hasBalance = balance != null && balance.balance > 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
            ),
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
                Text(
                  '${student.studentClass}${student.section != null ? ' - ${student.section}' : ''} • ID: ${student.admissionNumber}',
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusBadge(
                      status: hasBalance ? 'OVERDUE' : 'PAID',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.darkBorder.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        student.stream ?? 'General',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(StudentBalance? balance) {
    if (balance == null) return const SizedBox.shrink();

    final paidPercent = balance.totalFeeAmount > 0 
        ? (balance.totalPaidAmount / balance.totalFeeAmount)
        : 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'TOTAL FEE',
          CurrencyFormatter.format(balance.totalFeeAmount),
          AppColors.textPrimary,
          1.0,
        ),
        _buildMetricCard(
          'PAID',
          CurrencyFormatter.format(balance.totalPaidAmount),
          AppColors.primary,
          paidPercent,
        ),
        _buildMetricCard(
          'OUTSTANDING',
          CurrencyFormatter.format(balance.balance),
          balance.balance > 0 ? AppColors.error : AppColors.success,
          balance.totalFeeAmount > 0 ? (balance.balance / balance.totalFeeAmount) : 0.0,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.darkBorder.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabItem('Overview', true),
        _buildTabItem('History', false),
        _buildTabItem('Documents', false),
      ],
    );
  }

  Widget _buildTabItem(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.primary : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildRecentPayments(AsyncValue<List<Payment>> paymentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Recent Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'View All',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No payments recorded yet', style: TextStyle(color: AppColors.textTertiary)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length > 3 ? 3 : payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.format(payment.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${payment.paymentMethod.name.toUpperCase()} • ${_formatDate(payment.paymentDate)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildContactInfo(Student student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Contact Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Parent Name', student.parentName ?? 'Not provided'),
          _buildInfoRow('Email Address', student.parentEmail ?? 'Not provided'),
          _buildInfoRow('Phone Number', student.parentPhone ?? 'Not provided'),
          _buildInfoRow('Address', student.address ?? 'Not provided', isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Student student) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/payments/record', extra: student),
            icon: const Icon(Icons.add_card),
            label: const Text('RECORD PAYMENT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            onPressed: () {
              if (student.parentPhone != null) {
                _launchWhatsApp(student.parentPhone!, student.fullName);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Parent phone number not available')),
                );
              }
            },
            icon: const Icon(Icons.message_outlined, color: Colors.green),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('Hello, regarding student $name...')}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('This action cannot be undone. All student records and payment history will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(studentRepositoryProvider).deleteStudent(studentId);
                ref.invalidate(studentBalancesProvider);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Go back from details
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting student: $e')),
                  );
                }
              }
            },
            child: Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
