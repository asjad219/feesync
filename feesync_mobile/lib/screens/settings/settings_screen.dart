import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/user_profile.dart';
import '../../models/app_settings.dart';
import '../../core/widgets/glass/glass_card.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update theme: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateDashboardLayout(String layout) async {
    try {
      await ref.read(settingsProvider.notifier).updateSetting('dashboard_layout', layout);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update layout: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateGlassEffects(bool enabled) async {
    try {
      await ref.read(settingsProvider.notifier).updateSetting('glass_effects_enabled', enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update glass effects: $e'), backgroundColor: AppColors.error),
        );
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
            if (settingsAsync.value != null) ...[
              _buildAppearanceSettings(settingsAsync.value!),
              const SizedBox(height: 24),
            ],
            
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

  Widget _buildAppearanceSettings(AppSettings settings) {
    final currentTheme = settings.themeMode.toLowerCase();
    final currentLayout = settings.dashboardLayout.toLowerCase();
    final glassEnabled = settings.glassEffectsEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance & Interface'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme Mode',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildThemeOption('dark_luxury', 'Dark Luxury', currentTheme == 'dark_luxury'),
                  const SizedBox(width: 12),
                  _buildThemeOption('light', 'Light Mode', currentTheme == 'light'),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 16),
              
              // Dashboard Layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Layout',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Choose home screen visual structure',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  _buildLayoutDropdown(currentLayout),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 8),

              // Glassmorphism toggle
              SwitchListTile.adaptive(
                value: glassEnabled,
                title: Text(
                  'Glassmorphism Effects',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Enable blur and glass reflections on cards',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: _updateGlassEffects,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutDropdown(String currentLayout) {
    final Map<String, String> layouts = {
      'bento': 'Bento Grid',
      'classic_list': 'Classic List',
      'modern_grid': 'Modern Grid',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: layouts.containsKey(currentLayout) ? currentLayout : 'bento',
          items: layouts.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.key,
              child: Text(
                e.value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              _updateDashboardLayout(val);
            }
          },
          dropdownColor: AppColors.darkSurface,
          icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildThemeOption(String themeKey, String label, bool isSelected) {
    final bool isDark = AppColors.isDarkMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateThemeMode(themeKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.onPrimaryContainer : AppColors.textSecondary,
              ),
            ),
          ),
        ),
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
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRO TIER SUBSCRIPTION',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFF59E0B)),
              ),
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Center Enrollment Seat Usage',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            child: LinearProgressIndicator(
              value: 0.9,
              minHeight: 8,
              backgroundColor: AppColors.outline.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('450 / 500 active students', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
              Text('90% Limit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ],
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