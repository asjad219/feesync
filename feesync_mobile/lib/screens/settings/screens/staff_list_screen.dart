import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/paywall_dialog.dart';
import '../../../core/billing/feature_gate.dart';
import '../../../providers/staff_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/subscription_provider.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    ref.watch(featureGateProvider); // Eagerly watch to cache value for instant checks

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        systemOverlayStyle: AppColors.isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Staff & Access Control',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_rounded, color: AppColors.primary),
            onPressed: () {
              final gate = ref.read(featureGateProvider).valueOrNull;
              if (gate != null && !gate.canAddStaff) {
                showPaywallDialog(
                  context,
                  ref,
                  trigger: PaywallTrigger.staffLimit,
                );
                return;
              }
              context.push('/settings/staff/invite');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
        data: (staffList) {
          if (staffList.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(staffListProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 64),
                  Icon(Icons.group_off_rounded, size: 80, color: AppColors.textTertiary.withValues(alpha: 0.3)),
                  const SizedBox(height: 24),
                  Text(
                    'No Staff Added',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your team members and assign them roles to help manage the school efficiently.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final FeatureGate gate = ref.read(featureGateProvider).valueOrNull 
                            ?? await ref.read(featureGateProvider.future);
                        if (!gate.canAddStaff) {
                          if (context.mounted) {
                            await showPaywallDialog(
                              context,
                              ref,
                              trigger: PaywallTrigger.staffLimit,
                            );
                          }
                          return;
                        }
                        if (context.mounted) {
                          context.push('/settings/staff/invite');
                        }
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: Text('Invite Staff', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(staffListProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                final isCurrentUser = currentUserAsync.value?.id == staff.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: staff.isActive 
                              ? AppColors.primaryContainer 
                              : AppColors.outline.withValues(alpha: 0.2),
                          child: Text(
                            staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: staff.isActive ? AppColors.onPrimaryContainer : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.fullName + (isCurrentUser ? ' (You)' : ''),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: staff.isActive ? AppColors.textPrimary : AppColors.textTertiary,
                                ),
                              ),
                              Text(
                                staff.email,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (staff.role == 'admin' ? AppColors.error : AppColors.primary).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      staff.role.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: staff.role == 'admin' ? AppColors.error : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  if (!staff.isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.outline.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'DISABLED',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrentUser) // don't edit yourself here to prevent locking out
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                            onPressed: () {
                              context.push('/settings/staff/invite', extra: staff);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
