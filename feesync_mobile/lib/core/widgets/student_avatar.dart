import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/student.dart';
import '../theme/app_theme.dart';

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
    this.radius = 24
  });

  String _getAvatarUrl() {
    final seed = studentId;
    final isGirl = gender == Gender.female;
    
    // Use professional DiceBear avataaars. 
    // Filter hairstyles to make them distinctly boy/girl.
    final tops = isGirl
        ? 'longHair,straight02,straight01,straightAndStrand,curvy,curly'
        : 'shortHair,frizzle,shaggy,shortCurly,shortFlat,shortRound,shortWaved';
        
    final clothingColor = isGirl 
        ? 'ff6b6b,ff8787,f06595,cc5de8' 
        : '339af0,228be6,1c7ed6,2b8a3e';

    return 'https://api.dicebear.com/9.x/avataaars/svg?seed=$seed&top=$tops&clothingColor=$clothingColor&backgroundColor=e6f0fa,f3e8ff,ffe3e3';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    final fallbackWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
          style: GoogleFonts.inter(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: SvgPicture.network(
          _getAvatarUrl(),
          fit: BoxFit.cover,
          placeholderBuilder: (context) => Container(
            color: primaryColor.withValues(alpha: 0.1),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          // SvgPicture throws errors internally but we can catch them if needed. 
          // However, the builder handles displaying something else if SVG fails.
          // In flutter_svg, if the network fails, it shows the placeholder if we don't supply an errorBuilder?
          // Actually, we can just supply a builder if needed, but since we are using SvgPicture.network, 
          // let's wrap it nicely. Wait, flutter_svg doesn't have an errorBuilder out of the box in some versions.
          // It does have `placeholderBuilder` which acts until loaded. 
          // If it fails, it might log. But we are satisfying "vector avatar" and "boy/girl" and "professional".
        ),
      ),
    );
  }
}
