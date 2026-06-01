import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

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
      final student = await ref.read(studentRepositoryProvider).createStudent({
        'account_id': accountId,
        'admission_number': 'ADM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'class': _batchController.text.trim(),
        'parent_phone': _parentPhoneController.text.trim(),
      });

      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'onboarding_step': 'first-payment', 'onboarding_first_student_complete': true, 'onboarding_student_id': student.id}));
      if (mounted) context.go('/onboarding/first-payment?studentId=${student.id}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: Text('Enrollment', style: GoogleFonts.manrope(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'First Student', subtitle: 'Add a student record to start tracking fee payments'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildField(label: 'FIRST NAME', controller: _firstNameController, hint: 'First name', icon: Icons.person_outline_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(label: 'LAST NAME', controller: _lastNameController, hint: 'Last name', icon: Icons.person_outline_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              _buildField(label: 'PARENT PHONE', controller: _parentPhoneController, hint: '+91 90000 00000', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              _buildField(label: 'BATCH / CLASS', controller: _batchController, hint: 'e.g. Grade 10', icon: Icons.school_outlined),
              const SizedBox(height: 24),
              _buildField(label: 'EXPECTED MONTHLY FEE (INR)', controller: _feeAmountController, hint: '0', icon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 64),
              _buildSubmitButton(profile.accountId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
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

  Widget _buildSubmitButton(String accountId) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _saveStudent(accountId),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE AND ENROLL'),
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
