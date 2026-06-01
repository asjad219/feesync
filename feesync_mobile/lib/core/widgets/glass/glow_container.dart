import 'package:flutter/material.dart';

class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double spreadRadius;
  final double blurRadius;
  final BorderRadius? borderRadius;
  final Color? color;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.spreadRadius = 1.0,
    this.blurRadius = 15.0,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.2),
            spreadRadius: spreadRadius,
            blurRadius: blurRadius,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: child,
    );
  }
}
