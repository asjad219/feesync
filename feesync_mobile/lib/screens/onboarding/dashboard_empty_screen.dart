import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';

class DashboardEmptyScreen extends StatefulWidget {
  const DashboardEmptyScreen({super.key});

  @override
  State<DashboardEmptyScreen> createState() => _DashboardEmptyScreenState();
}

class _DashboardEmptyScreenState extends State<DashboardEmptyScreen> {
  bool _isLoading = false;

  Future<void> _startAddStudent() async {
    setState(() => _isLoading = true);

    await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        data: {
          'onboarding_step': 'add-student',
        },
      ),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/onboarding/add-student');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                'Your Dashboard Is Ready',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first student to start tracking fees and payments.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_outlined,
                        size: 56,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No students yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first student record and generate the first payment in minutes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _startAddStudent,
                      icon: const Icon(Icons.add),
                      label: _isLoading
                          ? const Text('Preparing...')
                          : const Text('Add First Student'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}