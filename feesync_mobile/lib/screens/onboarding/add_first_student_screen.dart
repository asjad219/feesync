import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/user_provider.dart';

class AddFirstStudentScreen extends ConsumerStatefulWidget {
  const AddFirstStudentScreen({super.key});

  @override
  ConsumerState<AddFirstStudentScreen> createState() => _AddFirstStudentScreenState();
}

class _AddFirstStudentScreenState extends ConsumerState<AddFirstStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _batchController = TextEditingController();
  final _feeAmountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _feeAmountController.text = '1000';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _parentPhoneController.dispose();
    _batchController.dispose();
    _feeAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent(String accountId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final studentRepository = ref.read(studentRepositoryProvider);
      final feeRepository = ref.read(feeRepositoryProvider);

      final admissionNumber = 'FS-${DateTime.now().millisecondsSinceEpoch}';
      final student = await studentRepository.createStudent({
        'account_id': accountId,
        'admission_number': admissionNumber,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'class': _batchController.text.trim(),
        'parent_phone': _parentPhoneController.text.trim(),
      });

      final feeCategories = await feeRepository.getFeeCategories();
      final category = feeCategories.isEmpty
          ? await feeRepository.createFeeCategory({
              'account_id': accountId,
              'name': 'Tuition Fee',
              'description': 'Default tuition fee category',
            })
          : feeCategories.first;

      final feeAmount = double.tryParse(_feeAmountController.text.trim()) ?? 0;
      if (feeAmount > 0) {
        await feeRepository.createFeeStructure({
          'account_id': accountId,
          'category_id': category.id,
          'name': 'Standard Plan',
          'amount': feeAmount,
          'class': _batchController.text.trim(),
          'due_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'description': 'Auto-created during onboarding',
        });
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'onboarding_step': 'first-payment',
            'onboarding_first_student_complete': true,
            'onboarding_student_id': student.id,
          },
        ),
      );

      if (mounted) {
        context.go('/onboarding/first-payment?studentId=${student.id}');
      }
    } catch (e) {
      _showError('Failed to add your first student.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: userProfileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Add Your First Student',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture the core student details and a starter fee plan.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter first name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter last name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _parentPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Parent Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter parent phone';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _batchController,
                            decoration: const InputDecoration(
                              labelText: 'Batch / Class',
                              prefixIcon: Icon(Icons.class_outlined),
                              hintText: 'Grade 10 - Evening',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter batch or class';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _feeAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Fee Amount',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter fee amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _saveStudent(profile.accountId),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save and Continue'),
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
              'Unable to load profile.',
              style: TextStyle(color: AppColors.overdue),
            ),
          ),
        ),
      ),
    );
  }
}
