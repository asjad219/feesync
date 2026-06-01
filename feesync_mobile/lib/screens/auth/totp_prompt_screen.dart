import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';

class TotpPromptScreen extends StatefulWidget {
  final bool isMandatory;

  const TotpPromptScreen({
    super.key,
    required this.isMandatory,
  });

  @override
  State<TotpPromptScreen> createState() => _TotpPromptScreenState();
}

class _TotpPromptScreenState extends State<TotpPromptScreen> {
  bool _isLoading = false;

  Future<void> _enableTotp() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'totp_enabled': true,
            'totp_skip_used': false,
          },
        ),
      );

      if (mounted) {
        context.go('/onboarding/intro');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipOnce() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'totp_skip_used': true,
          },
        ),
      );

      if (mounted) {
        context.go('/onboarding/intro');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.overdue,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.security,
                    size: 48,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isMandatory
                        ? 'Enable Two-Factor Security'
                        : 'Secure Your Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isMandatory
                        ? 'Two-factor authentication is required before you continue.'
                        : 'Add a TOTP authenticator to protect your account. You can skip this once.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _enableTotp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Enable TOTP'),
                  ),
                  if (!widget.isMandatory) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _skipOnce,
                      child: Text(
                        'Skip for now',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}