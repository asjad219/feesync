import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool showTrend;
  final double trendPercent;
  final bool trendUp;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool isGradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.showTrend = false,
    this.trendPercent = 0,
    this.trendUp = true,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;

    // Premium styling details based on theme
    final cardBg = isGradient
        ? (isDark
            ? LinearGradient(
                colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppColors.primary.withOpacity(0.08), AppColors.primaryLight.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : null;

    final border = Border.all(
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
      width: 1.5,
    );

    final shadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ];

    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGradient ? null : AppColors.darkCard.withOpacity(0.85),
        gradient: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: border,
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Styled Glassmorphic Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark 
                      ? iconColor.withOpacity(0.12)
                      : iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              
              // Clean pill-shaped trend indicator
              if (showTrend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: trendUp 
                        ? AppColors.success.withOpacity(0.12) 
                        : AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: trendUp 
                          ? AppColors.success.withOpacity(0.2) 
                          : AppColors.error.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: trendUp ? AppColors.success : AppColors.error,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trendPercent.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          color: trendUp ? AppColors.success : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Stat Title Label
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          // Value (Number/Amount)
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
