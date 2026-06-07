import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/local_settings_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import 'pin_lock_screen.dart';

class MpinSettingsScreen extends ConsumerStatefulWidget {
  const MpinSettingsScreen({super.key});

  @override
  ConsumerState<MpinSettingsScreen> createState() => _MpinSettingsScreenState();
}

class _MpinSettingsScreenState extends ConsumerState<MpinSettingsScreen> {
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

  Future<void> _enableMpin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinLockScreen(mode: PinLockMode.setup),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _resetMpin() async {
    // Verify first
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinLockScreen(mode: PinLockMode.verify),
      ),
    );
    
    if (verified == true && mounted) {
      // Then setup new
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const PinLockScreen(mode: PinLockMode.setup),
        ),
      );
      if (mounted) {
        _showSnack('MPIN successfully reset.', isSuccess: true);
        setState(() {});
      }
    }
  }

  Future<void> _disableMpin() async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinLockScreen(mode: PinLockMode.verify),
      ),
    );

    if (verified == true && mounted) {
      final settings = ref.read(localSettingsProvider.notifier);
      await settings.updatePinHash(null);
      await settings.updatePinLockEnabled(false);
      if (mounted) {
        _showSnack('MPIN disabled.', isSuccess: true);
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = ref.watch(localSettingsProvider);
    final hasMpin = local.pinLockEnabled;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'MPIN Settings',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'MANAGE MPIN',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  if (!hasMpin)
                    _actionTile(
                      icon: Icons.add_moderator_rounded,
                      iconColor: AppColors.primary,
                      title: 'Add / Enable MPIN',
                      subtitle: 'Set up a 4-digit PIN to secure your app',
                      onTap: _enableMpin,
                    )
                  else ...[
                    _actionTile(
                      icon: Icons.pin_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Reset MPIN',
                      subtitle: 'Change your current 4-digit PIN',
                      onTap: _resetMpin,
                    ),
                    Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                    _switchTile(
                      icon: Icons.phonelink_lock_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Lock on Minimize',
                      subtitle: 'Require PIN when switching back to the app',
                      value: local.lockOnMinimize,
                      onChanged: (v) => ref.read(localSettingsProvider.notifier).updateLockOnMinimize(v),
                    ),
                    Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
                    _actionTile(
                      icon: Icons.remove_moderator_rounded,
                      iconColor: AppColors.error,
                      title: 'Disable MPIN',
                      subtitle: 'Turn off PIN protection',
                      isDanger: true,
                      onTap: _disableMpin,
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 18,
      ),
    );
  }

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
          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
        ),
      ),
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onChanged: onChanged,
    );
  }
}
