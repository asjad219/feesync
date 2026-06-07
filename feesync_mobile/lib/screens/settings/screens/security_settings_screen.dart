import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/local_settings_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../services/app_lock_service.dart';
import 'mpin_settings_screen.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _isSendingReset = false;
  bool _isSigningOutAll = false;

  // ── Change Password ────────────────────────────────────────────────────────
  Future<void> _sendPasswordReset(String email) async {
    setState(() => _isSendingReset = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        _showSnack(
          'Password reset email sent to $email. Check your inbox.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to send reset email: $e');
      }
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  // ── Sign Out All Devices ───────────────────────────────────────────────────
  Future<void> _signOutAllDevices() async {
    final confirmed = await _showConfirmDialog(
      title: 'Sign Out All Devices',
      message:
          'This will immediately terminate all active sessions across every device. You will be signed out here as well.',
      confirmLabel: 'Sign Out All',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSigningOutAll = true);
    try {
      await Supabase.instance.client.auth.signOut(
        scope: SignOutScope.global,
      );
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOutAll = false);
        _showSnack('Failed to sign out all devices: $e');
      }
    }
  }



  // ── Account Deletion ───────────────────────────────────────────────────────
  Future<void> _showDeleteAccountDialog(
      String accountId, String userId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Request Account Deletion',
          style: GoogleFonts.manrope(
            color: AppColors.error,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All student records, fees, and payment logs will be permanently deleted after 30 days. This cannot be undone.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reason for deletion (optional)…',
                hintStyle:
                    GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor:
                    AppColors.surfaceContainer.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.onErrorContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Submit Request', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.requestAccountDeletion(
          accountId, userId, reasonController.text.trim());
      if (mounted) {
        _showSnack(
          'Deletion request submitted. Your account will be reviewed within 48 hours.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to submit request: $e');
    } finally {
      reasonController.dispose();
    }
  }

  // ── App Lock Toggles ───────────────────────────────────────────────────────
  Future<void> _toggleBiometric(bool value) async {
    final settings = ref.read(localSettingsProvider.notifier);
    if (value) {
      final service = ref.read(appLockServiceProvider);
      final canUse = await service.canUseBiometrics();
      if (!canUse) {
        if (mounted) {
          _showSnack('Biometric authentication is not set up or not supported on this device.');
        }
        return;
      }
      // Optionally verify right now to confirm ownership
      final success = await service.authenticateWithBiometrics('Verify to enable biometric login');
      if (success) {
        await settings.updateBiometricEnabled(true);
      }
    } else {
      await settings.updateBiometricEnabled(false);
    }
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDanger,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            color: isDanger ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger
                  ? AppColors.errorContainer
                  : AppColors.primaryContainer,
              foregroundColor: isDanger
                  ? AppColors.onErrorContainer
                  : AppColors.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel, style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSuccess ? AppColors.onSuccess : AppColors.onError,
          ),
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final local = ref.watch(localSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Security & System',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Lock ───────────────────────────────────────────────────
            _sectionHeader('App Lock'),
            const SizedBox(height: 12),
            GlassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.primary,
                    title: 'Biometric Authentication',
                    subtitle:
                        'Use Face ID or fingerprint for fast secure login',
                    value: local.biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                  _divider(),
                  _actionTile(
                    icon: Icons.password_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'MPIN Settings',
                    subtitle: local.pinLockEnabled
                        ? 'Manage or remove your 4-digit PIN'
                        : 'Set up a 4-digit PIN to secure your app',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MpinSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Login Alerts ───────────────────────────────────────────────
            _sectionHeader('Login Security'),
            const SizedBox(height: 12),
            GlassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'New Device Login Alerts',
                    subtitle:
                        'Get notified when your account signs in on a new device',
                    value: local.sessionAlertsEnabled,
                    onChanged: (v) => ref
                        .read(localSettingsProvider.notifier)
                        .updateSessionAlertsEnabled(v),
                  ),
                  _divider(),
                  _actionTile(
                    icon: Icons.lock_reset_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Change Password',
                    subtitle: 'Send a password reset link to your email',
                    trailingWidget: _isSendingReset
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                    onTap: _isSendingReset
                        ? null
                        : () async {
                            final user = userAsync.value;
                            if (user != null) {
                              final confirmed = await _showConfirmDialog(
                                title: 'Reset Password',
                                message:
                                    'Are you sure you want to request a password reset?\n\nAn email will be sent to ${user.email} with instructions to reset your password. Please check your inbox and spam folders to complete the password reset.',
                                confirmLabel: 'Send Link',
                                isDanger: false,
                              );
                              if (confirmed && mounted) {
                                _sendPasswordReset(user.email);
                              }
                            }
                          },
                  ),
                  _divider(),
                  _actionTile(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    title: 'Sign Out All Devices',
                    subtitle:
                        'Terminate all active sessions everywhere',
                    isDanger: true,
                    trailingWidget: _isSigningOutAll
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : null,
                    onTap: _isSigningOutAll ? null : _signOutAllDevices,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),


            // ── About ──────────────────────────────────────────────────────
            _sectionHeader('About'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow('App Version', '1.0.0'),
                  _divider(),
                  _infoRow('Environment', 'Production'),
                  _divider(),
                  _infoRow('Support Email', 'support@feesync.com'),
                  _divider(),
                  _infoRow('Developer', 'FeeSync Team'),
                  _divider(),
                  _infoRow('Build', 'Release'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Danger Zone ────────────────────────────────────────────────
            userAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Danger Zone'),
                    const SizedBox(height: 12),
                    GlassCard(
                      borderColor: AppColors.error.withValues(alpha: 0.25),
                      gradientColors: [
                        AppColors.error.withValues(alpha: 0.04),
                        AppColors.error.withValues(alpha: 0.04),
                      ],
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_rounded,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Request Account Deletion',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All student records, fees, and payment logs will be permanently purged 30 days after the request is approved.',
                            style: GoogleFonts.inter(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showDeleteAccountDialog(
                                  user.accountId, user.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.errorContainer,
                                foregroundColor: AppColors.onErrorContainer,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                minimumSize: const Size(double.infinity, 48),
                                elevation: 0,
                              ),
                              child: Text(
                                'Request Account Deletion',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 52, top: 2),
        child: Text(
          subtitle,
          style: GoogleFonts.inter(
              color: AppColors.textTertiary, fontSize: 11),
        ),
      ),
      activeThumbColor: AppColors.primary,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onChanged: onChanged,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailingWidget,
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDanger ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: GoogleFonts.inter(
              color: AppColors.textTertiary, fontSize: 11),
        ),
      ),
      trailing: trailingWidget ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
            size: 18,
          ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1);

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 0),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
      );
}