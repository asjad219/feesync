import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../providers/user_provider.dart';

class OptionalProfileScreen extends ConsumerStatefulWidget {
  const OptionalProfileScreen({super.key});

  @override
  ConsumerState<OptionalProfileScreen> createState() => _OptionalProfileScreenState();
}

class _OptionalProfileScreenState extends ConsumerState<OptionalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _logoController = TextEditingController();
  final _gstinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _logoController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String accountId) async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(accountRepositoryProvider);
      await repository.updateAccountProfile(accountId, {
        'logo_url': _logoController.text.trim().isEmpty
            ? null
            : _logoController.text.trim(),
        'gstin': _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim(),
      });

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'onboarding_step': 'dashboard-empty',
            'onboarding_optional_profile_complete': true,
          },
        ),
      );

      if (mounted) {
        context.go('/onboarding/dashboard-empty');
      }
    } catch (e) {
      _showError('Unable to save optional profile details.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skip() async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        data: {
          'onboarding_step': 'dashboard-empty',
          'onboarding_optional_profile_complete': true,
        },
      ),
    );

    if (mounted) {
      context.go('/onboarding/dashboard-empty');
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
              return const Center(
                child: Text('Profile not found.'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Optional Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add details that appear on receipts and reports.',
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _logoController,
                            decoration: const InputDecoration(
                              labelText: 'Logo URL',
                              prefixIcon: Icon(Icons.image_outlined),
                              hintText: 'https://example.com/logo.png',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _gstinController,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN (Optional)',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                              hintText: '22AAAAA0000A1Z5',
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _saveProfile(profile.accountId),
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
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isLoading ? null : _skip,
                            child: Text(
                              'Skip for now',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
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
              'Failed to load profile.',
              style: TextStyle(color: AppColors.overdue),
            ),
          ),
        ),
      ),
    );
  }
}