import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/payment.dart';
import '../../providers/providers.dart';
import 'receipt_preview_screen.dart';

class FirstPaymentScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const FirstPaymentScreen({super.key, this.studentId});

  @override
  ConsumerState<FirstPaymentScreen> createState() => _FirstPaymentScreenState();
}

class _FirstPaymentScreenState extends ConsumerState<FirstPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _amountController.text = '1000';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _previewReceipt(String studentName) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    
    final args = ReceiptPreviewArgs(studentId: widget.studentId ?? '', studentName: studentName, amount: amount, method: _method);
    await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'onboarding_step': 'receipt-preview'}));
    if (mounted) context.go('/onboarding/receipt-preview', extra: args);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.studentId == null) return const Scaffold(body: Center(child: Text('Student ID missing')));
    final studentAsync = ref.watch(studentByIdProvider(widget.studentId!));
    final currencyCode = ref.watch(settingsProvider).value?.currency;
    final currencySymbol = CurrencyFormatter.symbolFor(currencyCode);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: Text('Payment Record', style: GoogleFonts.manrope(fontWeight: FontWeight.w800))),
      body: studentAsync.when(
        data: (student) {
          if (student == null) return const Center(child: Text('Student not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Record First Fee', subtitle: 'Simulate a real payment for ${student.fullName}'),
                  const SizedBox(height: 32),
                  _buildField(label: 'COLLECTED AMOUNT ($currencySymbol)', controller: _amountController, hint: '0', icon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
                  const SizedBox(height: 32),
                  Text('PAYMENT MODE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
                  const SizedBox(height: 12),
                  _buildModePicker(),
                  const SizedBox(height: 64),
                  _buildSubmitButton(student.fullName),
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

  Widget _buildField({required String label, required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
            fillColor: AppColors.surfaceContainer.withValues(alpha: 0.5),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildModePicker() {
    return Row(
      children: PaymentMethod.values.map((m) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _method = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _method == m ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _method == m ? AppColors.primary : Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Icon(m == PaymentMethod.cash ? Icons.payments_rounded : Icons.account_balance_wallet_rounded, color: _method == m ? AppColors.primary : AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(m.name.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _method == m ? AppColors.primary : AppColors.textTertiary)),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSubmitButton(String studentName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _previewReceipt(studentName),
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('PREVIEW RECEIPT'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
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
