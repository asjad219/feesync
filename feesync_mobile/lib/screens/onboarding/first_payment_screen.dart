import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../models/payment.dart';
import '../../providers/student_provider.dart';
import 'receipt_preview_screen.dart';

class FirstPaymentScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const FirstPaymentScreen({
    super.key,
    this.studentId,
  });

  @override
  ConsumerState<FirstPaymentScreen> createState() => _FirstPaymentScreenState();
}

class _FirstPaymentScreenState extends ConsumerState<FirstPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  final bool _isLoading = false;

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
    final args = ReceiptPreviewArgs(
      studentId: widget.studentId ?? '',
      studentName: studentName,
      amount: amount,
      method: _method,
    );

    await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        data: {
          'onboarding_step': 'receipt-preview',
        },
      ),
    );

    if (mounted) {
      context.go('/onboarding/receipt-preview', extra: args);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.studentId == null || widget.studentId!.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        body: GradientBackground(
          child: Center(
            child: Text(
              'Student not found. Please add a student first.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final studentAsync = ref.watch(studentByIdProvider(widget.studentId!));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: studentAsync.when(
          data: (student) {
            if (student == null) {
              return const Center(child: Text('Student not found.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Record First Payment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${student.fullName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Payment Amount',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<PaymentMethod>(
                            initialValue: _method,
                            decoration: const InputDecoration(
                              labelText: 'Payment Mode',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            items: PaymentMethod.values
                                .map(
                                  (method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(
                                      method.name.replaceAll('_', ' ').toUpperCase(),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _method = value);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _previewReceipt(student.fullName),
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Preview Receipt'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Text(
              'Unable to load student details.',
              style: TextStyle(color: AppColors.overdue),
            ),
          ),
        ),
      ),
    );
  }
}
