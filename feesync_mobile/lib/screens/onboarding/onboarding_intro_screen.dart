import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300, 
                height: 300, 
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15), 
                  shape: BoxShape.circle
                )
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  const _IllustrationCard(),
                  const Spacer(),
                  Text('FeeSync Pro', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Text('Precision Fee Management', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.5)),
                  const SizedBox(height: 32),
                  Text('Automate collections, track dues, and generate professional receipts in seconds.', 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary, height: 1.6),
                  ),
                  const Spacer(),
                  _buildNextButton(context),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _continue(context),
                    child: Text('SKIP SETUP', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textTertiary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppGradients.primary, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
      ),
      child: ElevatedButton(
        onPressed: () => _continue(context),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: Text('GET STARTED', style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1)),
      ),
    );
  }

  Future<void> _continue(BuildContext context) async {
    await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'onboarding_step': 'center-setup'}));
    if (context.mounted) context.go('/onboarding/center-setup');
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
          child: const Icon(Icons.sync_rounded, size: 64, color: Colors.white),
        ),
      ),
    );
  }
}
