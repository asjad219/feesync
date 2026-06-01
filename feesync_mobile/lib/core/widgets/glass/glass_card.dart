import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.05,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final radius = borderRadius ?? BorderRadius.circular(24);
    
    final Color bgCol = isDark 
        ? Colors.white.withValues(alpha: opacity) 
        : Colors.white.withValues(alpha: 0.9);
        
    final Color borderCol = borderColor ?? (isDark 
        ? Colors.white.withValues(alpha: 0.1) 
        : Colors.black.withValues(alpha: 0.08));

    final List<BoxShadow>? shadows = isDark ? null : [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];

    final List<Color> gradColors = gradientColors ?? (isDark 
        ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.01)]
        : [Colors.white, Colors.white.withValues(alpha: 0.85)]);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isDark ? blur : 0, sigmaY: isDark ? blur : 0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: radius,
              border: Border.all(
                color: borderCol,
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradColors,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
