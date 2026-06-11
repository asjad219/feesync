import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ParsedError {
  final String title;
  final String message;
  final String hotfix;
  final String? actionLabel;
  final IconData icon;
  final Color color;
  final VoidCallback? onAction;

  ParsedError({
    required this.title,
    required this.message,
    required this.hotfix,
    this.actionLabel,
    this.icon = Icons.error_outline_rounded,
    this.color = const Color(0xFFEF4444),
    this.onAction,
  });
}

ParsedError parseError(BuildContext context, dynamic error) {
  final errStr = error.toString();

  bool contains(List<String> keywords) {
    return keywords.any((kw) => errStr.toLowerCase().contains(kw.toLowerCase()));
  }

  // 1. Staff limit
  if (contains(['staff limit', 'invite more staff'])) {
    return ParsedError(
      title: 'Staff Limit Reached',
      message: 'You have reached the staff limit for your current subscription plan.',
      hotfix: 'To add more staff members and manage roles, please upgrade your subscription plan.',
      actionLabel: 'Upgrade Plan',
      icon: Icons.people_outline_rounded,
      color: const Color(0xFF8B5CF6), // Purple
      onAction: () {
        context.push('/settings/subscription');
      },
    );
  }

  // 2. Student limit
  if (contains(['student limit', 'maxstudents', 'limit of student'])) {
    return ParsedError(
      title: 'Student Limit Reached',
      message: 'You have reached the maximum number of students allowed on your current plan.',
      hotfix: 'To add more students to your institution, please upgrade your subscription plan.',
      actionLabel: 'Upgrade Plan',
      icon: Icons.school_outlined,
      color: const Color(0xFF8B5CF6),
      onAction: () {
        context.push('/settings/subscription');
      },
    );
  }

  // 3. Batch limit
  if (contains(['batch limit', 'maxbatches', 'limit of batch'])) {
    return ParsedError(
      title: 'Batch Limit Reached',
      message: 'You have reached the limit of active batches allowed on your current plan.',
      hotfix: 'To create more batches/classes, please upgrade your subscription plan.',
      actionLabel: 'Upgrade Plan',
      icon: Icons.layers_outlined,
      color: const Color(0xFF8B5CF6),
      onAction: () {
        context.push('/settings/subscription');
      },
    );
  }

  // 4. Network error
  if (contains(['socketexception', 'connection failed', 'failed host lookup', 'timeout', 'network_error'])) {
    return ParsedError(
      title: 'Connection Offline',
      message: 'Unable to connect to the FeeSync servers.',
      hotfix: 'Please check your Wi-Fi or cellular network connection and try again.',
      icon: Icons.wifi_off_rounded,
      color: const Color(0xFF3B82F6), // Blue
    );
  }

  // 5. Invalid Credentials
  if (contains(['invalid_credentials', 'invalid login credentials'])) {
    return ParsedError(
      title: 'Invalid Credentials',
      message: 'The email or password you entered is incorrect.',
      hotfix: 'Please check your email and password and try again. If you forgot your password, use the "Forgot Password" option.',
      icon: Icons.no_accounts_rounded,
      color: const Color(0xFFEF4444),
    );
  }

  // 6. RLS / Permission
  if (contains(['unauthorized', 'permission denied', 'row-level security'])) {
    return ParsedError(
      title: 'Permission Denied',
      message: 'You do not have the required permissions to perform this action.',
      hotfix: 'Ensure you are logged in with the correct account or consult your administrator.',
      actionLabel: 'Check Settings',
      icon: Icons.lock_outline_rounded,
      color: const Color(0xFFEF4444),
      onAction: () {
        context.push('/settings');
      },
    );
  }

  // Clean raw message extraction
  String cleanMsg = errStr;
  
  if (errStr.contains('details:')) {
    final errorMatch = RegExp(r'details:\s*\{\s*error:\s*([^}]+)\}').firstMatch(errStr);
    if (errorMatch != null) {
      cleanMsg = errorMatch.group(1)!.trim();
    } else {
      final messageMatch = RegExp(r'details:\s*\{\s*message:\s*([^}]+)\}').firstMatch(errStr);
      if (messageMatch != null) {
        cleanMsg = messageMatch.group(1)!.trim();
      }
    }
  } else if (errStr.contains('message:')) {
    final msgMatch = RegExp(r'message:\s*([^,)]+)').firstMatch(errStr);
    if (msgMatch != null) {
      cleanMsg = msgMatch.group(1)!.trim();
    }
  } else {
    final jsonErrorMatch = RegExp(r'"error"\s*:\s*"([^"]+)"').firstMatch(errStr);
    if (jsonErrorMatch != null) {
      cleanMsg = jsonErrorMatch.group(1)!;
    }
  }

  if (cleanMsg.startsWith('Exception: ')) {
    cleanMsg = cleanMsg.replaceFirst('Exception: ', '');
  } else if (cleanMsg.startsWith('Exception:')) {
    cleanMsg = cleanMsg.replaceFirst('Exception:', '');
  }

  return ParsedError(
    title: 'Operation Failed',
    message: cleanMsg,
    hotfix: 'Please verify the operation or try again. If this problem persists, contact FeeSync support.',
    icon: Icons.error_outline_rounded,
    color: const Color(0xFFEF4444),
  );
}

void showErrorDialog(BuildContext context, dynamic error) {
  final parsed = parseError(context, error);
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _ErrorDialog(
      parsedError: parsed,
      rawError: error.toString(),
    ),
  );
}

class _ErrorDialog extends StatefulWidget {
  final ParsedError parsedError;
  final String rawError;

  const _ErrorDialog({
    required this.parsedError,
    required this.rawError,
  });

  @override
  State<_ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<_ErrorDialog> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.parsedError.color;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Accent Icon
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColor.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Icon(
                  widget.parsedError.icon,
                  color: themeColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              widget.parsedError.title,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Clean Error Message Description
            Text(
              widget.parsedError.message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // How to fix Card (Hotfix card)
            Container(
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themeColor.withValues(alpha: 0.15)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: themeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUGGESTED ACTION',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: themeColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.parsedError.hotfix,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Technical Details (Collapsible Panel)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  _showDetails ? 'Hide Technical Details' : 'Show Technical Details',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                dense: true,
                onExpansionChanged: (expanded) {
                  setState(() => _showDetails = expanded);
                },
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.rawError,
                      style: GoogleFonts.firaCode(
                        fontSize: 10.5,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CTA Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (widget.parsedError.actionLabel != null &&
                    widget.parsedError.onAction != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.parsedError.onAction!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.parsedError.actionLabel!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
