import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
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

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('You need to be logged in.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final accountRepository = ref.read(accountRepositoryProvider);
      await accountRepository.bootstrapOwner(
        centerName: _centerNameController.text.trim(),
        contactEmail: user.email ?? '',
        ownerFullName: user.userMetadata?['full_name']?.toString() ?? 'Owner',
        contactPhone: _phoneController.text.trim(),
        centerAddress: _addressController.text.trim(),
      );

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'onboarding_step': 'optional-profile',
            'onboarding_center_setup_complete': true,
          },
        ),
      );

      if (mounted) {
        context.go('/onboarding/optional-profile');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Failed to save center profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Center Setup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell us about your coaching center so we can personalize the experience.',
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
                        controller: _centerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Center Name',
                          prefixIcon: Icon(Icons.school_outlined),
                          hintText: 'Bright Future Coaching',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your center name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Center Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          hintText: 'Street, City, State',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '+91 90000 00000',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
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
                            : const Text('Continue'),
                      ),
                    ],
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
