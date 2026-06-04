import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), _handleNavigation);
  }

  void _handleNavigation() {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { context.go('/login'); return; }
    
    final metadata = user.userMetadata ?? {};
    final onboardingComplete = metadata['onboarding_complete'] == true ||
        metadata['onboarding_center_setup_complete'] == true;
    if (onboardingComplete) {
      context.go('/dashboard');
    } else {
      context.go('/onboarding/intro');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20))]),
                child: const Icon(Icons.sync_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text('FeeSync Pro', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('INTELLIGENT FEE MANAGEMENT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 3, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}
