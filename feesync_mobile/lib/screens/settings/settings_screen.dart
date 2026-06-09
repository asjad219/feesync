import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../models/user_profile.dart';
import '../../models/subscription.dart';
import '../../core/widgets/glass/glass_card.dart';
import '../../core/widgets/error_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _updateThemeMode(String theme) async {
    try {
      await ref.read(settingsProvider.notifier).updateSetting('theme_mode', theme);
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        systemOverlayStyle: AppColors.isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          settingsAsync.when(
            data: (settings) {
              final isLight = settings.themeMode.toLowerCase() == 'light';
              return IconButton(
                icon: Icon(
                  isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => _updateThemeMode(isLight ? 'dark_luxury' : 'light'),
                tooltip: isLight ? 'Switch to Dark Mode' : 'Switch to Light Mode',
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            userProfile.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading profile: $err', style: TextStyle(color: AppColors.error)),
              data: (user) => _buildProfileHeader(user),
            ),
            const SizedBox(height: 24),

            
            _buildSectionHeader('Operational Settings'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _SettingsItem(
                icon: Icons.business_rounded,
                iconColor: AppColors.primary,
                title: 'Institution & Branding',
                subtitle: 'Registration details, currency, school logo',
                onTap: () => context.push('/settings/institution'),
              ),
              if (userProfile.value?.role == 'admin')
                _SettingsItem(
                  icon: Icons.people_outline_rounded,
                  iconColor: const Color(0xFFF43F5E),
                  title: 'Staff & Access Control',
                  subtitle: 'Manage roles, permissions, and staff limits',
                  onTap: () => context.push('/settings/staff'),
                ),
              _SettingsItem(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Fee & Billing Engine',
                subtitle: 'Penalties, due date cycles, payment policies',
                onTap: () => context.push('/settings/billing'),
              ),
              _SettingsItem(
                icon: Icons.campaign_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Communications & Sync',
                subtitle: 'WhatsApp official templates, SMS delivery, auto alerts',
                onTap: () => context.push('/settings/automation'),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Reports & Analytics'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _SettingsItem(
                icon: Icons.analytics_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Reports & Analytics',
                subtitle: 'Collections, pending fees, dynamic reports',
                onTap: () => context.push('/reports'),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Preferences & Intelligence'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _SettingsItem(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'AI Intelligence',
                subtitle: 'Smart due patterns, OCR bills camera tools',
                onTap: () => context.push('/settings/ai'),
              ),
              _SettingsItem(
                icon: Icons.security_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Security & System',
                subtitle: 'Biometrics check, lock screen, server logs',
                onTap: () => context.push('/settings/security'),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Data Management'),
            const SizedBox(height: 12),
            _buildSettingsGroup([
              _SettingsItem(
                icon: Icons.storage_rounded,
                iconColor: const Color(0xFF06B6D4),
                title: 'Data Management',
                subtitle: 'Import students, export data as CSV, sync with cloud',
                onTap: () => context.push('/settings/data'),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Subscription & Billing'),
            const SizedBox(height: 12),
            _buildSubscriptionCard(),
            const SizedBox(height: 28),
            _buildLogoutButton(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile? user) {
    if (user == null) return const SizedBox();
    
    final avatarLetter = user.fullName.isNotEmpty ? user.fullName.substring(0, 1).toUpperCase() : 'K';
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              avatarLetter,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final dataAsync = ref.watch(subscriptionScreenDataProvider);

    return dataAsync.when(
      loading: () => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Text(
              'Loading subscription…',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
      error: (_, _) => _buildSubscriptionCardContent(
        sub: Subscription.defaultFree(''),
        activeStudents: 0,
        onTap: () => context.push('/settings/subscription'),
      ),
      data: (data) => _buildSubscriptionCardContent(
        sub: data.subscription,
        activeStudents: data.activeStudentCount,
        onTap: () => context.push('/settings/subscription'),
        isNearLimit: data.isNearLimit,
        isAtLimit: data.isAtLimit,
        usageRatio: data.studentUsageRatio,
      ),
    );
  }

  Widget _buildSubscriptionCardContent({
    required Subscription sub,
    required int activeStudents,
    required VoidCallback onTap,
    bool isNearLimit = false,
    bool isAtLimit = false,
    double usageRatio = 0.0,
  }) {
    final planColor = sub.isGrowth
        ? const Color(0xFF8B5CF6)
        : sub.isStarter
            ? const Color(0xFF2563EB)
            : AppColors.textTertiary;

    final progressColor = isAtLimit
        ? AppColors.error
        : isNearLimit
            ? AppColors.pending
            : AppColors.success;

    final maxLabel = sub.currentMaxStudents <= 0
        ? 'Unlimited'
        : '$activeStudents / ${sub.currentMaxStudents}';

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderColor: planColor.withValues(alpha: 0.3),
        gradientColors: [
          planColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      sub.isGrowth
                          ? Icons.workspace_premium_rounded
                          : sub.isStarter
                              ? Icons.bolt_rounded
                              : Icons.spa_rounded,
                      color: planColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${sub.planLabel.toUpperCase()} PLAN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: planColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Student Seat Usage',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (sub.currentMaxStudents > 0) ...[  
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: LinearProgressIndicator(
                  value: usageRatio,
                  minHeight: 8,
                  backgroundColor: AppColors.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$activeStudents active student${activeStudents == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  maxLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAtLimit
                        ? AppColors.error
                        : isNearLimit
                            ? AppColors.pending
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (!sub.isGrowth) ...[  
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'View Plans & Upgrade',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.error.withValues(alpha: 0.2),
      child: InkWell(
        onTap: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) context.go('/login');
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Text(
                'Sign Out Account',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: AppColors.textTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 20,
      ),
    );
  }
}