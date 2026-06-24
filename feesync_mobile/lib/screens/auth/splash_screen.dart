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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  bool _showLoader = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/avatar_male.jpg'), context);
    precacheImage(const AssetImage('assets/avatar_female.jpg'), context);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    // Show a subtle loading indicator after 1 s so users know the app is working.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showLoader = true);
    });

    // Hard cap: always navigate after 5 s, regardless of any async outcome.
    // This guarantees the splash screen can never hang.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _handleNavigation();
    });

    // Normal path: wait 2 s, then navigate.
    Future.delayed(const Duration(seconds: 2), _handleNavigation);
  }

  Future<void> _handleNavigation() async {
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      // No cached session — go to login regardless of connectivity.
      if (mounted) context.go('/login');
      return;
    }

    if (!mounted) return;

    // Navigate based on onboarding state — works both online and offline
    // because onboarding_complete is stored in the JWT user metadata (local).
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'FeeSync',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'INTELLIGENT FEE MANAGEMENT',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 48),
              AnimatedOpacity(
                opacity: _showLoader ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
