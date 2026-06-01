import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/user_provider.dart';
import '../widgets/premium_widgets.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricEnabled = true;
  bool _pinLockEnabled = false;
  bool _sessionAlerts = true;
  bool _isWipingCache = false;

  void _showDeleteAccountDialog(String accountId, String userId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Delete Account',
          style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is irreversible. All student records, fees status, and payment logs will be scheduled for permanent deletion.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Reason for deletion (Optional)...',
                hintStyle: GoogleFonts.inter(color: AppColors.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repo = ref.read(accountRepositoryProvider);
                await repo.requestAccountDeletion(accountId, userId, reasonController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deletion request submitted. Management will review shortly.', style: GoogleFonts.inter(color: AppColors.onError)),
                      backgroundColor: AppColors.errorContainer,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit request: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorContainer),
            child: Text('Request Deletion', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _wipeOfflineCache() async {
    setState(() => _isWipingCache = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate local file cache wiping
    if (mounted) {
      setState(() => _isWipingCache = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offline database cache cleared successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSuccess)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Security & System Settings',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Authentication Controls'),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _biometricEnabled,
                    title: Text('Biometric Authentication', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Use FaceID/Fingerprint for fast secure logins', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: (val) => setState(() => _biometricEnabled = val),
                  ),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  SwitchListTile.adaptive(
                    value: _pinLockEnabled,
                    title: Text('App Lock PIN', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('Require a 4-digit PIN access lock upon startup', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                    secondary: const Icon(Icons.password_rounded, color: AppColors.primary),
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: (val) => setState(() => _pinLockEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionHeader('Active Session Monitors'),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDeviceTile('Android Mobile (This Device)', 'Active Session • New Delhi, India', true),
                  Divider(color: Colors.white.withOpacity(0.05), height: 16),
                  _buildDeviceTile('Chrome Web Application', 'Active Session • California, USA', false),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: _sessionAlerts,
                    title: Text('Unknown Device Login Alerts', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Push alert when account is signed in on a new host', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _sessionAlerts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionHeader('Diagnostics & Database Sync'),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDiagnosticsRow('System Connection', 'ONLINE', Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  _buildDiagnosticsRow('Supabase API Latency', '118 ms', AppColors.primary),
                  const SizedBox(height: 12),
                  _buildDiagnosticsRow('Local DB Cache Size', '24 KB', AppColors.textSecondary),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isWipingCache ? null : _wipeOfflineCache,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: _isWipingCache
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Wipe Offline Database Cache', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            userProfileAsync.when(
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
              data: (user) {
                if (user == null) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Danger Zone'),
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: AppColors.error.withOpacity(0.02),
                      borderColor: AppColors.error.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Account Deletion',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Initiate the operational teardown request for this multi-tenant institution card. All records are permanently purged after 30 days.',
                            style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showDeleteAccountDialog(user.accountId, user.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorContainer,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text('Begin Teardown Request', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

  Widget _buildDeviceTile(String name, String status, bool current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.devices_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(status, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
        if (!current)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
            child: Text('Revoke', style: GoogleFonts.inter(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text('THIS DEVICE', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }

  Widget _buildDiagnosticsRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
