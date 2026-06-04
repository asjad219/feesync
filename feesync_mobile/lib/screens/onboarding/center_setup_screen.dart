import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';

class CenterSetupScreen extends ConsumerStatefulWidget {
  const CenterSetupScreen({super.key});

  @override
  ConsumerState<CenterSetupScreen> createState() => _CenterSetupScreenState();
}

class _CenterSetupScreenState extends ConsumerState<CenterSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _centerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _phoneController.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await ref.read(accountRepositoryProvider).bootstrapOwner(
        centerName: _centerNameController.text.trim(),
        contactEmail: user.email ?? '',
        ownerFullName: user.userMetadata?['full_name']?.toString() ?? 'Owner',
        contactPhone: _phoneController.text.trim(),
        centerAddress: _addressController.text.trim(),
      );

      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {
        'onboarding_step': 'complete',
        'onboarding_center_setup_complete': true,
        'onboarding_complete': true,
      }));
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: Text('Institution Setup', style: GoogleFonts.manrope(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Institution Profile', subtitle: 'Global settings for your coaching center or school'),
              const SizedBox(height: 32),
              _buildField(label: 'CENTER NAME', controller: _centerNameController, hint: 'e.g. Luminary Academy', icon: Icons.account_balance_rounded),
              const SizedBox(height: 24),
              _buildField(label: 'CONTACT NUMBER', controller: _phoneController, hint: '+91 90000 00000', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              _buildField(label: 'OFFICIAL ADDRESS', controller: _addressController, hint: 'Street, City, State', icon: Icons.location_on_outlined, maxLines: 3),
              const SizedBox(height: 64),
              _buildContinueButton(),
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

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('CONTINUE SETUP'),
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
