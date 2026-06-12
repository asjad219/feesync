import 'dart:convert';
import 'dart:io';
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

  static final Map<String, String> _svgCache = {};

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

  Future<String?> _fetchSvg(String url) async {
    if (_svgCache.containsKey(url)) {
      return _svgCache[url];
    }
    
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final contents = await response.transform(utf8.decoder).join();
        _svgCache[url] = contents;
        return contents;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching avatar: $e');
      return null;
    }
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
        child: FutureBuilder<String?>(
          future: _fetchSvg(_getAvatarUrl()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: primaryColor.withValues(alpha: 0.1),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            
            if (snapshot.hasData && snapshot.data != null) {
              return SvgPicture.string(
                snapshot.data!,
                fit: BoxFit.cover,
                placeholderBuilder: (context) => fallbackWidget,
              );
            }
            
            return fallbackWidget;
          },
        ),
      ),
    );
  }
}
