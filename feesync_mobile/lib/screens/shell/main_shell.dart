import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  PageController? _pageController;
  int _lastRouterIndex = -1;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int visibleIndex, List<int> visibleIndices) {
    final targetBranch = visibleIndices[visibleIndex];
    if (widget.navigationShell.currentIndex != targetBranch) {
      widget.navigationShell.goBranch(
        targetBranch,
        initialLocation: targetBranch == widget.navigationShell.currentIndex,
      );
    }
  }

  void _onItemTapped(int branchIndex) {
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final user = userProfileAsync.value;
    
    final bool canViewStudents = user?.role == 'admin' || (user?.permissions['view_students'] == true);
    final bool canViewPayments = user?.role == 'admin' || (user?.permissions['view_payments'] == true);

    // Filter visible branches based on role
    List<int> visibleIndices = [0, 1];
    if (canViewStudents) visibleIndices.add(2);
    if (canViewPayments) visibleIndices.add(3);
    visibleIndices.add(4);

    List<Widget> visiblePages = [];
    for (int idx in visibleIndices) {
      visiblePages.add(KeepAliveWidget(child: widget.children[idx]));
    }

    final currentIndex = widget.navigationShell.currentIndex;
    final int initialVisibleIndex = visibleIndices.indexOf(currentIndex);

    // Initialize or Sync PageController
    if (_pageController == null) {
      _pageController = PageController(initialPage: initialVisibleIndex == -1 ? 0 : initialVisibleIndex);
      _lastRouterIndex = currentIndex;
    } else if (currentIndex != _lastRouterIndex) {
      _lastRouterIndex = currentIndex;
      if (initialVisibleIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController?.hasClients == true) {
            final int currentPage = _pageController!.page?.round() ?? 0;
            if (currentPage != initialVisibleIndex) {
              _pageController!.animateToPage(
                initialVisibleIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            }
          }
        });
      }
    }

    return Scaffold(
      extendBody: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: initialVisibleIndex == -1 
          // If navigated via URL to a hidden branch, show it directly (so PermissionGuard triggers)
          ? widget.children[currentIndex]
          : PageView(
              controller: _pageController,
              onPageChanged: (index) => _onPageChanged(index, visibleIndices),
              children: visiblePages,
            ),
      bottomNavigationBar: _StyledBottomNav(
        selectedIndex: currentIndex,
        canViewStudents: canViewStudents,
        canViewPayments: canViewPayments,
        onTap: _onItemTapped,
      ),
    );
  }
}

class KeepAliveWidget extends StatefulWidget {
  final Widget child;
  const KeepAliveWidget({super.key, required this.child});

  @override
  State<KeepAliveWidget> createState() => _KeepAliveWidgetState();
}

class _KeepAliveWidgetState extends State<KeepAliveWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
