import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/utils/google_drive_helper.dart';
import '../../../core/widgets/error_dialog.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {

  // Google Drive states
  GoogleSignInAccount? _googleUser;
  bool _isGdriveLoading = false;
  String? _gdriveBackupTime;
  List<GoogleBackupFile> _backupsList = [];

  @override
  void initState() {
    super.initState();
    _checkGoogleStatus();
    _loadLastBackupTime();
  }

  Future<void> _checkGoogleStatus() async {
    setState(() => _isGdriveLoading = true);
    try {
      final loggedIn = await GoogleDriveHelper.isLoggedIn();
      if (loggedIn) {
        setState(() {
          _googleUser = GoogleDriveHelper.currentUser;
        });
      }
    } catch (e) {
      debugPrint('Error checking Google login: $e');
    } finally {
      setState(() => _isGdriveLoading = false);
    }
  }

  Future<void> _loadLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('feesync_last_gdrive_backup_time');
    if (timeStr != null) {
      setState(() {
        _gdriveBackupTime = timeStr;
      });
    }
  }

  Future<void> _saveLastBackupTime(String timeStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('feesync_last_gdrive_backup_time', timeStr);
    setState(() {
      _gdriveBackupTime = timeStr;
    });
  }

  Future<void> _gdriveSignIn() async {
    setState(() => _isGdriveLoading = true);
    try {
      final user = await GoogleDriveHelper.signIn();
      setState(() {
        _googleUser = user;
      });
      if (user != null) {
        _showSuccessSnack('Connected to Google Drive: ${user.email}');
      }
    } catch (e) {
      _showErrorSnack('Google Drive Sign-In failed. Verify SHA-1 & credentials.');
    } finally {
      setState(() => _isGdriveLoading = false);
    }
  }

  Future<void> _gdriveSignOut() async {
    setState(() => _isGdriveLoading = true);
    try {
      await GoogleDriveHelper.signOut();
      setState(() {
        _googleUser = null;
        _backupsList.clear();
      });
      _showSuccessSnack('Disconnected from Google Drive.');
    } catch (e) {
      _showErrorSnack('Failed to disconnect: $e');
    } finally {
      setState(() => _isGdriveLoading = false);
    }
  }

  Future<void> _gdriveBackup() async {
    if (_googleUser == null) {
      await _gdriveSignIn();
      if (_googleUser == null) return;
    }
    setState(() => _isGdriveLoading = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User session not found. Please log in.');
      }
      final userData = await client
          .from('users')
          .select('account_id')
          .eq('id', user.id)
          .single();
      final accountId = userData['account_id'] as String;

      final fileName = await GoogleDriveHelper.performBackup(client, accountId);
      final nowStr = DateTime.now().toLocal().toString().split('.').first;
      await _saveLastBackupTime(nowStr);
      
      _showSuccessSnack('Backup created: $fileName');
    } catch (e) {
      _showErrorSnack('Backup failed: $e');
    } finally {
      setState(() => _isGdriveLoading = false);
    }
  }

  Future<void> _showRestoreDialog() async {
    if (_googleUser == null) {
      await _gdriveSignIn();
      if (_googleUser == null) return;
    }

    setState(() => _isGdriveLoading = true);
    try {
      final backups = await GoogleDriveHelper.listBackups();
      setState(() {
        _backupsList = backups;
      });
    } catch (e) {
      _showErrorSnack('Failed to retrieve backups: $e');
      setState(() => _isGdriveLoading = false);
      return;
    }
    setState(() => _isGdriveLoading = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Restore from Google Drive',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _backupsList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No backup files found in "FeeSync_Backups".',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _backupsList.length,
                        itemBuilder: (context, index) {
                          final backup = _backupsList[index];
                          final dateStr = backup.modifiedTime.toLocal().toString().split('.').first;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.settings_backup_restore_rounded, color: AppColors.primary),
                            ),
                            title: Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Size: ${backup.formattedSize}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.surfaceContainer,
                                    title: const Text('Delete Backup?'),
                                    content: Text('Are you sure you want to delete backup from $dateStr?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await GoogleDriveHelper.deleteBackup(backup.id);
                                    final newList = await GoogleDriveHelper.listBackups();
                                    setDialogState(() {
                                      _backupsList = newList;
                                    });
                                    setState(() {
                                      _backupsList = newList;
                                    });
                                    _showSuccessSnack('Backup deleted.');
                                  } catch (e) {
                                    _showErrorSnack('Failed to delete backup: $e');
                                  }
                                }
                              },
                            ),
                            onTap: () async {
                              Navigator.pop(context); // close list dialog
                              final confirmRestore = await showDialog<bool>(
                                context: this.context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.surfaceContainer,
                                  title: const Text('Confirm Restore'),
                                  content: Text(
                                    'This will overwrite or merge local records with the backup from $dateStr.\n\nAre you sure you want to restore?',
                                    style: const TextStyle(height: 1.4),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(
                                        'Restore',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmRestore == true) {
                                _executeRestore(backup.id);
                              }
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeRestore(String fileId) async {
    setState(() => _isGdriveLoading = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User session not found. Please log in.');
      }
      final userData = await client
          .from('users')
          .select('account_id')
          .eq('id', user.id)
          .single();
      final accountId = userData['account_id'] as String;

      await GoogleDriveHelper.restoreBackup(client, accountId, fileId);

      // Invalidate all providers to sync latest data to UI
      ref.invalidate(studentNotifierProvider);
      ref.invalidate(paymentNotifierProvider);

      _showSuccessSnack('Database restored from Google Drive successfully!');
    } catch (e) {
      _showErrorSnack('Restore failed: $e');
    } finally {
      setState(() => _isGdriveLoading = false);
    }
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.onSuccess,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnack(String msg) {
    if (mounted) {
      showErrorDialog(context, msg);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Data Management',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Google Drive Backup ───────────────────────────────────────
            _sectionHeader('Google Drive Backup'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.backup_rounded,
                          color: Color(0xFF4285F4),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Drive Sync',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _googleUser != null
                                  ? 'Logged in as: ${_googleUser!.email}'
                                  : 'Not connected',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _googleUser != null
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                              ),
                            ),
                            if (_gdriveBackupTime != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Last backup: $_gdriveBackupTime',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGdriveLoading ? null : _gdriveBackup,
                          icon: _isGdriveLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 16),
                          label: Text(
                            'Backup Now',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isGdriveLoading ? null : _showRestoreDialog,
                          icon: const Icon(Icons.settings_backup_restore_rounded, size: 16),
                          label: Text(
                            'Restore Data',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4285F4),
                            side: const BorderSide(color: Color(0xFF4285F4)),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_googleUser != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isGdriveLoading ? null : _gdriveSignOut,
                        child: Text(
                          'Disconnect Google Drive',
                          style: GoogleFonts.inter(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGdriveLoading ? null : _gdriveSignIn,
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: Text(
                          'Connect Google Drive',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'Backup Guidelines & Security',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.textTertiary,
                      children: [
                        const SizedBox(height: 8),
                        _instructionText(
                          'How it works:',
                          '• Backups are saved securely in a folder named "FeeSync_Backups" in your Google Drive.\n'
                          '• Privacy: FeeSync only requests access to files it creates. It cannot access any other files on your Google Drive.\n'
                          '• Restoring: Restoring a backup will merge or update records in your current database with the backed-up data.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Import ────────────────────────────────────────────────────
            _sectionHeader('Import'),
            const SizedBox(height: 12),
            _navCard(
              icon: Icons.upload_file_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Import Student Data',
              subtitle: 'Bulk-add students from a CSV file',
              badge: 'CSV',
              badgeColor: const Color(0xFF10B981),
              onTap: () => context.push('/settings/data/import'),
            ),
            const SizedBox(height: 24),

            // ── Export ────────────────────────────────────────────────────
            _sectionHeader('Export'),
            const SizedBox(height: 12),
            _navCard(
              icon: Icons.download_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Export Data',
              subtitle: 'Download students, payments & fees as CSV',
              badge: 'CSV',
              badgeColor: const Color(0xFF8B5CF6),
              onTap: () => context.push('/settings/data/export'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _instructionText(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _navCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badge,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
          size: 20,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
      );
}
