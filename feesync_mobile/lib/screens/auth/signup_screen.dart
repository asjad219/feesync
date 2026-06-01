import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim(), 'role': 'admin'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please check your email.')));
        context.go('/login');
      }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Container(width: 64, height: 64, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.sync_rounded, color: Colors.white, size: 32)),
              const SizedBox(height: 32),
              Text('Create account', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Join FeeSync Pro as an institution administrator', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
              const SizedBox(height: 40),
              _buildField(label: 'FULL NAME', controller: _nameController, hint: 'John Doe', icon: Icons.person_outline_rounded),
              const SizedBox(height: 24),
              _buildField(label: 'EMAIL ADDRESS', controller: _emailController, hint: 'admin@school.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              _buildField(label: 'PASSWORD', controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 32),
              _buildTermsCheckbox(),
              const SizedBox(height: 48),
              _buildSignupButton(),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Already have an account? ", style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
                GestureDetector(onTap: () => context.go('/login'), child: Text('Login', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
          suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textTertiary), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
          fillColor: AppColors.surfaceContainer.withValues(alpha: 0.5),
        ),
        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
      ),
    ]);
  }

  Widget _buildTermsCheckbox() {
    return Row(children: [
      Checkbox(value: _acceptedTerms, onChanged: (v) => setState(() => _acceptedTerms = v ?? false), activeColor: AppColors.primary),
      Expanded(child: Text('I agree to the Terms of Service and Privacy Policy', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
    ]);
  }

  Widget _buildSignupButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('GET STARTED', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1)),
      ),
    );
  }
}
