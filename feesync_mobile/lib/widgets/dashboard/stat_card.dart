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
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final primaryLightColor = isDark ? const Color(0xFFEEEFFF) : const Color(0xFFEBF0FF);
    final secondaryColor = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF7C3AED);
    final cardColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final successColor = isDark ? const Color(0xFFB4F0C5) : const Color(0xFF16A34A);
    final errorColor = isDark ? const Color(0xFFFFB4AB) : const Color(0xFFDC2626);

    // Premium styling details based on theme
    final cardBg = isGradient
        ? (isDark
            ? LinearGradient(
                colors: [primaryColor.withValues(alpha: 0.15), secondaryColor.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [primaryColor.withValues(alpha: 0.08), primaryLightColor.withValues(alpha: 0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : (isDark
            ? LinearGradient(
                colors: [iconColor.withValues(alpha: 0.04), cardColor.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [iconColor.withValues(alpha: 0.02), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ));

    final border = Border.all(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
      width: 1.5,
    );

    final shadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ];

    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
                      ? iconColor.withValues(alpha: 0.12)
                      : iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
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
                        ? successColor.withValues(alpha: 0.12) 
                        : errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: trendUp 
                          ? successColor.withValues(alpha: 0.2) 
                          : errorColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: trendUp ? successColor : errorColor,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trendPercent.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          color: trendUp ? successColor : errorColor,
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
              color: textTertiaryColor,
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
              color: textPrimaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
