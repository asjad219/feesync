import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
       return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64, 
                    height: 64, 
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary, 
                      borderRadius: BorderRadius.circular(16)
                    ), 
                    child: const Icon(Icons.sync_rounded, color: Colors.white, size: 32)
                  ),
                  const SizedBox(height: 32),
                  Text('Welcome back', textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Login to your administrator account', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildField(label: 'EMAIL ADDRESS', controller: _emailController, hint: 'admin@feesync.com', icon: Icons.email_outlined),
            const SizedBox(height: 24),
            _buildField(label: 'PASSWORD', controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight, 
              child: TextButton(
                onPressed: () => context.push('/forgot-password'), 
                child: Text('Forgot Password?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))
              )
            ),
            const SizedBox(height: 48),
            _buildLoginButton(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
                GestureDetector(
                  onTap: () => context.push('/signup'), 
                  child: Text('Sign Up', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))
                ),
              ]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textTertiary), 
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword)
            ) : null,
            fillColor: AppColors.surfaceContainer.withValues(alpha: 0.5),
          ),
        ),
      ]
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppGradients.primary, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('LOGIN', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1)),
      ),
    );
  }
}
