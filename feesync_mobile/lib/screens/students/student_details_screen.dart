import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../models/student.dart';
import '../../models/payment.dart';
import '../../models/batch.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';
import '../../core/utils/receipt_service.dart';
import '../../core/widgets/glass/glass_card.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentByIdProvider(studentId));
    final balanceAsync = ref.watch(studentBalanceByIdProvider(studentId));
    final paymentsAsync = ref.watch(studentPaymentsProvider(studentId));
    final batchesAsync = ref.watch(studentBatchesProvider(studentId));
    final settingsAsync = ref.watch(settingsProvider);
    final currencyFormatter = CurrencyFormatter.numberFormat(settingsAsync.value?.currency, decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(
          'Student Details',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/students/edit/$studentId'),
            icon: const Icon(Icons.edit_note_rounded),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref),
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) return const Center(child: Text('Student not found'));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentByIdProvider(studentId));
              ref.invalidate(studentBalanceByIdProvider(studentId));
              ref.invalidate(studentPaymentsProvider(studentId));
              ref.invalidate(studentBatchesProvider(studentId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(student: student, balance: balanceAsync.value),
                  const SizedBox(height: 32),
                  _MetricsSection(
                    balance: balanceAsync.value,
                    discountAmount: student.discountAmount,
                    currencyFormatter: currencyFormatter,
                  ),
                  const SizedBox(height: 32),
                  _BatchEnrollmentSection(studentId: studentId, batchesAsync: batchesAsync),
                  const SizedBox(height: 32),
                  _RecentPaymentsList(
                    paymentsAsync: paymentsAsync,
                    studentId: studentId,
                    student: student,
                    currencyFormatter: currencyFormatter,
                  ),
                  const SizedBox(height: 32),
                  _ContactInfoCard(student: student),
                  const SizedBox(height: 40),
                  _ActionButtons(student: student),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Student?', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: const Text('This will permanently delete all records and payment history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ref.read(studentRepositoryProvider).deleteStudent(studentId);
              ref.invalidate(studentBalancesProvider);
              ref.invalidate(activeStudentCountProvider);
              ref.invalidate(subscriptionScreenDataProvider);
              ref.invalidate(featureGateProvider);
              if (context.mounted) {
                Navigator.pop(context);
                context.pop();
              }
            },
            child: Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Student student;
  final StudentBalance? balance;

  const _ProfileHeader({required this.student, this.balance});

  @override
  Widget build(BuildContext context) {
    final hasBalance = balance != null && balance!.balance > 0;
    final String capitalizedName = student.fullName
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
        
    final String initials = student.fullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capitalizedName,
                  style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.studentClass} • ID: ${student.admissionNumber}',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
                ),
                if (student.rollNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Roll No: ${student.rollNumber}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 12),
                StatusBadge(status: hasBalance ? 'OVERDUE' : 'PAID'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsSection extends StatelessWidget {
  final StudentBalance? balance;
  final double discountAmount;
  final NumberFormat currencyFormatter;

  const _MetricsSection({
    this.balance,
    this.discountAmount = 0,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (balance == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            _MetricCard(
              label: 'TOTAL FEE', 
              value: currencyFormatter.format(balance!.totalFeeAmount), 
              color: AppColors.textPrimary,
              icon: Icons.receipt_long_rounded,
              iconBgColor: AppColors.textPrimary,
            ),
            const SizedBox(width: 16),
            _MetricCard(
              label: 'PAID', 
              value: currencyFormatter.format(balance!.totalPaidAmount), 
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
              iconBgColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _MetricCard(
              label: 'DISCOUNT', 
              value: currencyFormatter.format(discountAmount), 
              color: AppColors.tertiary,
              icon: Icons.local_offer_rounded,
              iconBgColor: AppColors.tertiary,
            ),
            const SizedBox(width: 16),
            _MetricCard(
              label: balance!.balance < 0 ? 'ADVANCE' : 'OUTSTANDING',
              value: currencyFormatter.format(balance!.balance.abs()),
              color: balance!.balance > 0 ? AppColors.error : AppColors.success,
              icon: balance!.balance > 0 ? Icons.warning_amber_rounded : Icons.verified_rounded,
              iconBgColor: balance!.balance > 0 ? AppColors.error : AppColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final Color iconBgColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label, 
                    style: GoogleFonts.inter(
                      fontSize: 10, 
                      fontWeight: FontWeight.w700, 
                      letterSpacing: 1.1, 
                      color: AppColors.textTertiary
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconBgColor, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value, 
              style: GoogleFonts.inter(
                fontSize: 18, 
                fontWeight: FontWeight.w800, 
                color: color
              )
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchEnrollmentSection extends ConsumerWidget {
  final String studentId;
  final AsyncValue<List<Batch>> batchesAsync;

  const _BatchEnrollmentSection({required this.studentId, required this.batchesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Enrolled Batches', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextButton.icon(
              onPressed: () => _showEnrollmentSheet(context, ref),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text('Assign'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        batchesAsync.when(
          data: (batches) {
            if (batches.isEmpty) return Text('No batches assigned yet', style: TextStyle(color: AppColors.textTertiary));
            return Column(
              children: batches.map((batch) => _BatchTile(batch: batch)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  void _showEnrollmentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _EnrollmentSheet(studentId: studentId),
    );
  }
}

class _BatchTile extends StatelessWidget {
  final Batch batch;
  const _BatchTile({required this.batch});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: batch.color.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: batch.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.school_rounded, color: batch.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('${batch.subject} • ${batch.teacherName}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.push('/batches/${batch.id}'),
            icon: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentSheet extends ConsumerWidget {
  final String studentId;
  const _EnrollmentSheet({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBatchesAsync = ref.watch(filteredBatchesProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enroll in Batch', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          allBatchesAsync.when(
            data: (batches) => Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: batches.length,
                itemBuilder: (context, index) {
                  final batch = batches[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: batch.color.withValues(alpha: 0.1),
                      child: Icon(Icons.school_rounded, color: batch.color),
                    ),
                    title: Text(batch.name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text(batch.subject, style: TextStyle(color: AppColors.textTertiary)),
                    trailing: Icon(Icons.add_rounded, color: AppColors.primary),
                    onTap: () async {
                      final accountId = userProfileAsync.value?.accountId;
                      if (accountId != null) {
                        await ref.read(batchRepositoryProvider).enrollStudentInBatch(
                          studentId: studentId,
                          batchId: batch.id,
                          accountId: accountId,
                        );
                        ref.invalidate(studentBatchesProvider(studentId));
                        if (context.mounted) Navigator.pop(context);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: Could not determine account')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _RecentPaymentsList extends StatelessWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  final String studentId;
  final Student student;
  final NumberFormat currencyFormatter;

  const _RecentPaymentsList({
    required this.paymentsAsync,
    required this.studentId,
    required this.student,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Payments', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _StudentPaymentHistorySheet(
                    studentId: studentId,
                    student: student,
                    currencyFormatter: currencyFormatter,
                  ),
                );
              },
              child: Text('View All', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) return Text('No payments recorded yet', style: TextStyle(color: AppColors.textTertiary));
            return Column(
              children: payments
                  .take(3)
                  .map((p) => _PaymentTile(payment: p, student: student, currencyFormatter: currencyFormatter))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}

class _PaymentTile extends ConsumerWidget {
  final Payment payment;
  final Student student;
  final NumberFormat currencyFormatter;
  final bool isHistoryView;
  const _PaymentTile({
    required this.payment, 
    required this.student, 
    required this.currencyFormatter,
    this.isHistoryView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor = AppColors.success;
    if (payment.status == PaymentStatus.pending) statusColor = AppColors.tertiary;
    if (payment.status == PaymentStatus.cancelled || payment.status == PaymentStatus.refunded) statusColor = AppColors.error;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(
              payment.status == PaymentStatus.completed ? Icons.receipt_rounded : 
              (payment.status == PaymentStatus.cancelled ? Icons.cancel_rounded : Icons.pending_actions_rounded), 
              color: statusColor, size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(currencyFormatter.format(payment.amount), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (payment.status != PaymentStatus.completed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(payment.status.name.toUpperCase(), style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text('${payment.paymentMethod.name.toUpperCase()} • ${DateFormat('MMM d, yyyy').format(payment.paymentDate)}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          if (payment.status == PaymentStatus.completed)
            IconButton(
              onPressed: () => _sharePastReceipt(context, ref),
              icon: Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
              tooltip: 'Share Receipt',
            ),
          if (isHistoryView && payment.status == PaymentStatus.completed)
            IconButton(
              onPressed: () => _confirmRevert(context, ref),
              icon: Icon(Icons.undo_rounded, size: 20, color: AppColors.error),
              tooltip: 'Revert Payment',
            ),
        ],
      ),
    );
  }

  void _confirmRevert(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Revert Payment?', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text('Are you sure you want to revert this payment? This will mark it as cancelled and adjust the student\'s outstanding balance.', 
          style: GoogleFonts.inter(color: AppColors.textTertiary)),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // close dialog
                    try {
                      await ref.read(paymentNotifierProvider.notifier).updatePayment(payment.id, {'status': 'cancelled'});
                      ref.invalidate(studentPaymentsProvider(student.id));
                      ref.invalidate(studentBalanceByIdProvider(student.id));
                      ref.invalidate(studentBalancesProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment reverted successfully')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reverting payment: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('REVERT', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textTertiary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sharePastReceipt(BuildContext context, WidgetRef ref) async {
    final invoiceNo = payment.receiptNumber ?? 'INV-${payment.id.substring(0, 8)}';
    
    final accountProfile = ref.read(accountProfileProvider).value;
    final institutionName = accountProfile?.schoolName ?? accountProfile?.name ?? 'Institution';

    final textReceipt = ReceiptService.generateTextReceipt(
      student: student,
      amount: payment.amount,
      paymentMode: payment.paymentMethod.name,
      date: payment.paymentDate,
      invoiceNo: invoiceNo,
      institutionName: institutionName,
    );

    final pdfFile = await ReceiptService.generatePdfReceipt(
      student: student,
      amount: payment.amount,
      paymentMode: payment.paymentMethod.name,
      date: payment.paymentDate,
      invoiceNo: invoiceNo,
      institutionName: institutionName,
    );

    String phone = student.parentPhone ?? '';
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    await ReceiptService.shareToWhatsApp(
      phone: cleanPhone,
      text: textReceipt,
      pdfFile: pdfFile,
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final Student student;
  const _ContactInfoCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Details', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _InfoRow(label: 'Parent Name', value: student.parentName ?? '--', icon: Icons.person_outline_rounded),
          _InfoRow(label: 'Phone Number', value: student.parentPhone ?? '--', icon: Icons.phone_outlined),
          _InfoRow(label: 'Email', value: student.parentEmail ?? '--', icon: Icons.mail_outline_rounded),
          _InfoRow(label: 'Address', value: student.address ?? '--', icon: Icons.map_outlined, isLast: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right, 
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Student student;
  const _ActionButtons({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(24)),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/payments/record', extra: student),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('RECORD PAYMENT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, 
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366),
          onTap: () => _launchWhatsApp(student.parentPhone ?? '', student.fullName),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          icon: Icons.call_rounded,
          color: AppColors.primary,
          onTap: () => launchUrl(Uri.parse('tel:${student.parentPhone}')),
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp(String phone, String name) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }
    final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('Hello, regarding student $name...')}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), 
          shape: BoxShape.circle, 
          border: Border.all(color: color.withValues(alpha: 0.2))
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _StudentPaymentHistorySheet extends ConsumerWidget {
  final String studentId;
  final Student student;
  final NumberFormat currencyFormatter;

  const _StudentPaymentHistorySheet({
    required this.studentId,
    required this.student,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(studentPaymentsProvider(studentId));
    final bool isDark = AppColors.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment History', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 20),
          paymentsAsync.when(
            data: (payments) {
              if (payments.isEmpty) {
                return const Expanded(child: Center(child: Text('No payments found')));
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    return _PaymentTile(payment: p, student: student, currencyFormatter: currencyFormatter, isHistoryView: true);
                  },
                ),
              );
            },
            loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Expanded(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }
}