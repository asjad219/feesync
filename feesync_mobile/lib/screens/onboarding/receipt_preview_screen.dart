import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/payment.dart';
import '../../providers/providers.dart';

class ReceiptPreviewArgs {
  final String studentId;
  final String studentName;
  final double amount;
  final PaymentMethod method;

  ReceiptPreviewArgs({required this.studentId, required this.studentName, required this.amount, required this.method});
}

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  final ReceiptPreviewArgs? args;

  const ReceiptPreviewScreen({super.key, this.args});

  @override
  ConsumerState<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  bool _isLoading = false;

  Future<void> _confirmPayment(ReceiptPreviewArgs args) async {
    setState(() => _isLoading = true);
    try {
      final userProfile = ref.read(currentUserProfileProvider).value;
      if (userProfile == null) throw Exception('Profile not found');

      await ref.read(paymentRepositoryProvider).createPayment({
        'account_id': userProfile.accountId,
        'student_id': args.studentId,
        'amount': args.amount,
        'payment_method': args.method.name,
        'payment_date': DateTime.now().toIso8601String(),
        'status': 'completed',
      }, []);

      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'onboarding_step': 'complete', 'onboarding_first_payment_complete': true, 'onboarding_complete': true}));
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) return const Scaffold(body: Center(child: Text('Data missing')));
    final settings = ref.watch(settingsProvider).value;
    final currencyFormatter = CurrencyFormatter.numberFormat(settings?.currency, decimalDigits: 0);
    final canShareReceipt = (settings?.autoReceiptEnabled ?? true) && (settings?.whatsappEnabled ?? true);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: Text('Verification', style: GoogleFonts.manrope(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Receipt Preview', subtitle: 'Verify the details before completing setup'),
            const SizedBox(height: 32),
            _DigitalReceipt(args: args, currencyFormatter: currencyFormatter),
            const SizedBox(height: 64),
            _buildActionButtons(args, canShareReceipt),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReceiptPreviewArgs args, bool canShareReceipt) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _confirmPayment(args),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('FINISH AND START APP'),
          ),
        ),
        const SizedBox(height: 16),
        if (canShareReceipt)
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text('SHARE ON WHATSAPP', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.textTertiary)),
          ),
      ],
    );
  }
}

class _DigitalReceipt extends StatelessWidget {
  final ReceiptPreviewArgs args;
  final NumberFormat currencyFormatter;
  const _DigitalReceipt({required this.args, required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: AppColors.primary)),
          const SizedBox(height: 24),
          Text(currencyFormatter.format(args.amount), style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text('SUCCESSFUL PAYMENT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.primary)),
          const SizedBox(height: 40),
          Divider(color: AppColors.outline, thickness: 0.2),
          const SizedBox(height: 24),
          _ReceiptRow(label: 'STUDENT', value: args.studentName),
          _ReceiptRow(label: 'PAYMENT ID', value: 'FS-ONB-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}'),
          _ReceiptRow(label: 'MODE', value: args.method.name.toUpperCase()),
          _ReceiptRow(label: 'DATE', value: 'TODAY'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: Text('This is a verified digital receipt generated by FeeSync Pro.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
      ],
    );
  }
}