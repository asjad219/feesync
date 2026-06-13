import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/student.dart';

/// A professional gender-aware vector avatar for students.
///
/// Renders an embedded SVG (no network required) with a gradient background
/// and a clean white silhouette that differs by gender:
///   • Male   → blue gradient, short hair, broad shoulders
///   • Female → rose gradient, flowing long hair, narrower shoulders
///   • Other  → purple gradient, neutral hair
///
/// Falls back to a coloured initials circle if SVG rendering fails.
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

  // ── Embedded SVG data ─────────────────────────────────────────────────────

  /// Male avatar — blue gradient + short-hair silhouette + broad shoulders.
  static const String _maleSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="200" y2="200" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#7CB9FF"/>
      <stop offset="100%" stop-color="#1D4ED8"/>
    </linearGradient>
    <clipPath id="c">
      <circle cx="100" cy="100" r="100"/>
    </clipPath>
  </defs>
  <circle cx="100" cy="100" r="100" fill="url(#bg)"/>
  <g clip-path="url(#c)" opacity="0.93">
    <!-- Shoulders / body -->
    <path d="M8,215 Q8,152 100,143 Q192,152 192,215Z" fill="white"/>
    <!-- Neck -->
    <rect x="86" y="126" width="28" height="22" rx="12" fill="white"/>
    <!-- Head -->
    <circle cx="100" cy="97" r="41" fill="white"/>
    <!-- Short hair cap — top of head, flat-edged for masculine read -->
    <path d="M59,97 Q57,50 100,47 Q143,50 141,97
             Q138,64 100,62 Q62,64 59,97Z" fill="white"/>
    <!-- Subtle sideburn shapes for extra male definition -->
    <rect x="59" y="90" width="8" height="20" rx="4" fill="white"/>
    <rect x="133" y="90" width="8" height="20" rx="4" fill="white"/>
  </g>
</svg>''';

  /// Female avatar — rose gradient + long flowing hair + shoulders.
  static const String _femaleSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="200" y2="200" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#F9A8D4"/>
      <stop offset="100%" stop-color="#9D174D"/>
    </linearGradient>
    <clipPath id="c">
      <circle cx="100" cy="100" r="100"/>
    </clipPath>
  </defs>
  <circle cx="100" cy="100" r="100" fill="url(#bg)"/>
  <g clip-path="url(#c)" opacity="0.93">
    <!-- Long flowing hair — left side (behind head layer) -->
    <path d="M59,97 Q46,145 52,175" stroke="white" stroke-width="24"
          stroke-linecap="round" fill="none"/>
    <!-- Long flowing hair — right side (behind head layer) -->
    <path d="M141,97 Q154,145 148,175" stroke="white" stroke-width="24"
          stroke-linecap="round" fill="none"/>
    <!-- Shoulders / body -->
    <path d="M18,215 Q18,157 100,148 Q182,157 182,215Z" fill="white"/>
    <!-- Neck -->
    <rect x="88" y="126" width="24" height="20" rx="10" fill="white"/>
    <!-- Head -->
    <circle cx="100" cy="97" r="40" fill="white"/>
    <!-- Hair top — flows smoothly into the long side strands -->
    <path d="M59,97 Q57,50 100,47 Q143,50 141,97
             Q138,62 100,60 Q62,62 59,97Z" fill="white"/>
  </g>
</svg>''';

  /// Other / unknown gender avatar — purple gradient + neutral medium hair.
  static const String _otherSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="200" y2="200" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#C4B5FD"/>
      <stop offset="100%" stop-color="#4C1D95"/>
    </linearGradient>
    <clipPath id="c">
      <circle cx="100" cy="100" r="100"/>
    </clipPath>
  </defs>
  <circle cx="100" cy="100" r="100" fill="url(#bg)"/>
  <g clip-path="url(#c)" opacity="0.93">
    <!-- Medium side hair (slight overlap past head) -->
    <path d="M60,97 Q52,130 56,160" stroke="white" stroke-width="14"
          stroke-linecap="round" fill="none"/>
    <path d="M140,97 Q148,130 144,160" stroke="white" stroke-width="14"
          stroke-linecap="round" fill="none"/>
    <!-- Shoulders / body -->
    <path d="M12,215 Q12,154 100,145 Q188,154 188,215Z" fill="white"/>
    <!-- Neck -->
    <rect x="87" y="126" width="26" height="22" rx="11" fill="white"/>
    <!-- Head -->
    <circle cx="100" cy="97" r="40" fill="white"/>
    <!-- Medium hair top -->
    <path d="M60,97 Q58,50 100,47 Q142,50 140,97
             Q137,64 100,62 Q63,64 60,97Z" fill="white"/>
  </g>
</svg>''';

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _svgFor(Gender? g) {
    switch (g) {
      case Gender.male:
        return _maleSvg;
      case Gender.female:
        return _femaleSvg;
      default:
        return _otherSvg;
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final accent = _accentFor(gender);

    // Initials fallback — shown only if SVG fails (extremely unlikely).
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
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

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(
          _svgFor(gender),
          fit: BoxFit.cover,
          placeholderBuilder: (_) => fallback,
        ),
      ),
    );
  }
}
