import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../models/payment.dart';
import '../../providers/payment_provider.dart';
import '../../providers/user_provider.dart';

class ReceiptPreviewArgs {
  final String studentId;
  final String studentName;
  final double amount;
  final PaymentMethod method;

  ReceiptPreviewArgs({
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.method,
  });
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
      final userProfile = await ref.read(currentUserProfileProvider.future);
      if (userProfile == null) {
        _showError('Profile not found.');
        return;
      }

      final paymentRepository = ref.read(paymentRepositoryProvider);

      await paymentRepository.createPayment(
        {
          'account_id': userProfile.accountId,
          'student_id': args.studentId,
          'amount': args.amount,
          'payment_method': _mapPaymentMethod(args.method),
          'payment_date': DateTime.now().toIso8601String(),
          'status': 'completed',
          'recorded_by': Supabase.instance.client.auth.currentUser?.id,
        },
        [],
      );

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'onboarding_step': 'complete',
            'onboarding_first_payment_complete': true,
            'onboarding_complete': true,
          },
        ),
      );

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      _showError('Unable to record the first payment.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      default:
        return method.name;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.overdue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    if (args == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        body: GradientBackground(
          child: Center(
            child: Text(
              'Receipt preview unavailable.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Receipt Preview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review the WhatsApp-ready receipt before sending.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FeeSync Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PAID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ReceiptRow(label: 'Student', value: args.studentName),
                    _ReceiptRow(
                      label: 'Amount',
                      value: 'INR ${args.amount.toStringAsFixed(2)}',
                    ),
                    _ReceiptRow(
                      label: 'Mode',
                      value: args.method.name.replaceAll('_', ' ').toUpperCase(),
                    ),
                    _ReceiptRow(
                      label: 'Receipt No',
                      value: 'FS-${DateTime.now().millisecondsSinceEpoch}',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.darkBorder.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Thank you for your payment. This receipt is valid for WhatsApp delivery.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _confirmPayment(args),
                icon: const Icon(Icons.send),
                label: _isLoading
                    ? const Text('Processing...')
                    : const Text('Confirm and Send'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('WhatsApp preview queued.'),
                          ),
                        );
                      },
                child: const Text(
                  'Share on WhatsApp',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
