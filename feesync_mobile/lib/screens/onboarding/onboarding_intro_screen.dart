import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _IllustrationCard(),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  children: [
                    const Text(
                      'Simplify Fee Collection',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Manage your institution's finances with ease and precision.",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _ProgressDots(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _continue(context),
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _continue(context),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _FooterBrand(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCqyD2NadE1B_dmPYIOCv17rZG6748M1ENMquRaxe-Lf-5GAyspjxS2tiVjsTPf16lNNojDpnHrQ49XUDXESSVoiXULEqyal13HXbQdKTzbfxhctlZoH2aM_j1cxJVIU_gOsyiC0F8Eb5LvyO1Hr_9kpf9TvwX8ZwH9ozFK3UZl5JoouFPz6EJ2toiWzt9lPJBGIx4AkkbsSfAJZKPyR2UdldnpreBnhqUQlPGgGcWyyWdHKUM0RLdtwxRe3ss67pWGho9Ipcx0HNzg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: AppColors.darkSurface);
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.darkBg.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _continue(BuildContext context) async {
  await Supabase.instance.client.auth.updateUser(
    UserAttributes(
      data: {
        'onboarding_step': 'center-setup',
      },
    ),
  );

  if (context.mounted) {
    context.go('/onboarding/center-setup');
  }
}

class _ProgressDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF571BC1)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.darkBorder,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.darkBorder,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

class _FooterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF571BC1)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.sync,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'FEESYNC',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
