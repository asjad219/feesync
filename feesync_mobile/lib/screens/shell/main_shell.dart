import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final user = userProfileAsync.value;
    
    final bool canViewStudents = user?.role == 'admin' || (user?.permissions['view_students'] == true);
    final bool canViewPayments = user?.role == 'admin' || (user?.permissions['view_payments'] == true);

    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: false,
      backgroundColor: AppColors.darkBg,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final primaryVelocity = details.primaryVelocity ?? 0;
          if (primaryVelocity < -300) {
            // Swiped left -> Go to next page
            final nextIndex = selectedIndex + 1;
            if (nextIndex <= 4) {
              HapticFeedback.lightImpact();
              _onItemTapped(nextIndex, context);
            }
          } else if (primaryVelocity > 300) {
            // Swiped right -> Go to previous page
            final prevIndex = selectedIndex - 1;
            if (prevIndex >= 0) {
              HapticFeedback.lightImpact();
              _onItemTapped(prevIndex, context);
            }
          }
        },
        child: child,
      ),
      bottomNavigationBar: _StyledBottomNav(
        selectedIndex: selectedIndex,
        canViewStudents: canViewStudents,
        canViewPayments: canViewPayments,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/batches')) return 1;
    if (location.startsWith('/students')) return 2;
    if (location.startsWith('/payments')) return 3;
    if (location.startsWith('/settings')) return 4;
    if (location.startsWith('/reports')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/batches');
        break;
      case 2:
        context.go('/students');
        break;
      case 3:
        context.go('/payments');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}

class _StyledBottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool canViewStudents;
  final bool canViewPayments;
  final Function(int) onTap;

  const _StyledBottomNav({
    required this.selectedIndex,
    required this.canViewStudents,
    required this.canViewPayments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.06);
    final bg = isDark
        ? AppColors.surfaceContainer.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);
    final shadowColor = isDark 
        ? Colors.black.withValues(alpha: 0.2) 
        : Colors.black.withValues(alpha: 0.03);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPadding),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top: BorderSide(color: borderColor, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.layers_rounded,
                  label: 'Batches',
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
                if (canViewStudents)
                  _NavItem(
                    icon: Icons.people_rounded,
                    label: 'Students',
                    isSelected: selectedIndex == 2,
                    onTap: () => onTap(2),
                  ),
                if (canViewPayments)
                  _NavItem(
                    icon: Icons.payments_rounded,
                    label: 'Payments',
                    isSelected: selectedIndex == 3,
                    onTap: () => onTap(3),
                  ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: selectedIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: isSelected ? AppGradients.primary : null,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
