import 'package:flutter/material.dart';
import '../../models/student.dart';

/// A professional gender-aware avatar for students using pre-cached 3D asset images.
class StudentAvatar extends StatelessWidget {
  final String studentId;
  final String firstName;
  final Gender? gender;
  final double radius;

  const StudentAvatar({
    super.key,
    required this.studentId,
    required this.firstName,
    this.gender,
    this.radius = 24,
  });

  String _imageAssetFor(Gender? g) {
    switch (g) {
      case Gender.female:
        return 'assets/avatar_female.jpg';
      case Gender.male:
      default:
        return 'assets/avatar_male.jpg';
    }
  }

  Color _accentFor(Gender? g) {
    switch (g) {
      case Gender.male:
        return const Color(0xFF1D4ED8);
      case Gender.female:
        return const Color(0xFF9D174D);
      default:
        return const Color(0xFF4C1D95);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          _imageAssetFor(gender),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            final accent = _accentFor(gender);
            return Container(
              color: accent.withValues(alpha: 0.2),
              child: Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.75,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
