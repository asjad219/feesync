import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleDriveHelper {
  // We use the drive.file scope so the app can only read/write files it has created.
  // This is highly secure and prevents the app from accessing other user files on Google Drive.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      drive.DriveApi.driveFileScope,
    ],
  );

  /// Sign in to Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Drive Sign-In Error: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Get currently logged-in account
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if logged in
  static Future<bool> isLoggedIn() async {
    return _googleSignIn.currentUser != null || await _googleSignIn.isSignedIn();
  }

  /// Get Drive API client from Google Account
  static Future<drive.DriveApi?> _getDriveApi() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      return null;
    }

    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;

    return drive.DriveApi(httpClient);
  }

  /// Backup all Supabase data for the given accountId to Google Drive
  static Future<String> performBackup(SupabaseClient supabase, String accountId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('Failed to initialize Google Drive client. Please sign in again.');
    }

    // 1. Gather all database records associated with the account
    final backupData = await _generateBackupPayload(supabase, accountId);
    final jsonString = jsonEncode(backupData);
    final jsonBytes = utf8.encode(jsonString);

    // 2. Find or create the FeeSync_Backups folder
    final folderId = await _getOrCreateBackupsFolder(driveApi);

    // 3. Upload the backup file
    final now = DateTime.now();
    final timestamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final fileName = 'feesync_backup_$timestamp.json';

    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = [folderId]
      ..mimeType = 'application/json';

    final media = drive.Media(
      Stream.value(jsonBytes),
      jsonBytes.length,
      contentType: 'application/json',
    );

    final uploadedFile = await driveApi.files.create(
      fileMetadata,
      uploadMedia: media,
    );

    if (uploadedFile.id == null) {
      throw Exception('Google Drive upload failed.');
    }

    return fileName;
  }

  /// Retrieve list of backup files from Google Drive
  static Future<List<GoogleBackupFile>> listBackups() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('Failed to initialize Google Drive client. Please sign in.');
    }

    // Search for backup files inside the FeeSync_Backups folder
    final folderId = await _getOrCreateBackupsFolder(driveApi);
    final q = "'$folderId' in parents and mimeType = 'application/json' and name contains 'feesync_backup_' and trashed = false";

    final fileList = await driveApi.files.list(
      q: q,
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, name, size, modifiedTime)',
    );

    if (fileList.files == null) return [];

    return fileList.files!.map((f) {
      return GoogleBackupFile(
        id: f.id ?? '',
        name: f.name ?? '',
        sizeInBytes: int.tryParse(f.size ?? '0') ?? 0,
        modifiedTime: f.modifiedTime ?? DateTime.now(),
      );
    }).toList();
  }

  /// Download a backup file from Google Drive and restore it into Supabase
  static Future<void> restoreBackup(SupabaseClient supabase, String accountId, String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('Failed to initialize Google Drive client. Please sign in.');
    }

    // 1. Download file content
    final drive.Media media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> dataBytes = [];
    await for (final chunk in media.stream) {
      dataBytes.addAll(chunk);
    }

    final jsonString = utf8.decode(dataBytes);
    final Map<String, dynamic> backupData = jsonDecode(jsonString);

    // 2. Validate payload version/structure
    if (backupData['version'] == null || backupData['account_id'] == null) {
      throw Exception('Invalid backup file structure.');
    }

    // 3. Restore database records
    await _importBackupPayload(supabase, accountId, backupData);
  }

  /// Deletes a backup file from Google Drive
  static Future<void> deleteBackup(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('Failed to initialize Google Drive client. Please sign in.');
    }
    await driveApi.files.delete(fileId);
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────

  /// Finds or creates a folder named 'FeeSync_Backups' in the root directory
  static Future<String> _getOrCreateBackupsFolder(drive.DriveApi driveApi) async {
    final q = "mimeType = 'application/vnd.google-apps.folder' and name = 'FeeSync_Backups' and trashed = false";
    final list = await driveApi.files.list(q: q, spaces: 'drive');
    
    if (list.files != null && list.files!.isNotEmpty) {
      return list.files!.first.id!;
    }

    // Create the folder
    final folderMetadata = drive.File()
      ..name = 'FeeSync_Backups'
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folderMetadata);
    if (createdFolder.id == null) {
      throw Exception('Failed to create FeeSync backups folder on Google Drive.');
    }
    return createdFolder.id!;
  }

  /// Packages all account-specific data from Supabase into a JSON map
  static Future<Map<String, dynamic>> _generateBackupPayload(SupabaseClient supabase, String accountId) async {
    // Fetch tables
    final feeCategories = await supabase.from('fee_categories').select().eq('account_id', accountId);
    final feeStructures = await supabase.from('fee_structures').select().eq('account_id', accountId);
    final students = await supabase.from('students').select().eq('account_id', accountId);
    final payments = await supabase.from('payments').select().eq('account_id', accountId);

    // Fetch payment records (we fetch all payment records since they are tied to payments)
    // To ensure RLS constraints or filter by account_id indirectly, we retrieve records linked to user's payments
    final paymentIds = (payments as List).map((p) => p['id'] as String).toList();
    List<dynamic> paymentRecords = [];
    if (paymentIds.isNotEmpty) {
      paymentRecords = await supabase
          .from('payment_records')
          .select()
          .inFilter('payment_id', paymentIds);
    }

    final notificationSettings = await supabase
        .from('notification_settings')
        .select()
        .eq('account_id', accountId);

    return {
      'version': 1,
      'account_id': accountId,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': {
        'fee_categories': feeCategories,
        'fee_structures': feeStructures,
        'students': students,
        'payments': payments,
        'payment_records': paymentRecords,
        'notification_settings': notificationSettings,
      }
    };
  }

  /// Restores serialized records to Supabase tables, respecting foreign keys
  static Future<void> _importBackupPayload(SupabaseClient supabase, String accountId, Map<String, dynamic> payload) async {
    final tables = payload['tables'] as Map<String, dynamic>;

    // Order of operations is critical due to foreign keys:
    // 1. fee_categories
    // 2. fee_structures (depends on fee_categories)
    // 3. students
    // 4. payments (depends on students)
    // 5. payment_records (depends on payments and fee_structures)
    // 6. notification_settings

    final categories = tables['fee_categories'] as List<dynamic>? ?? [];
    if (categories.isNotEmpty) {
      await supabase.from('fee_categories').upsert(categories, onConflict: 'id');
    }

    final structures = tables['fee_structures'] as List<dynamic>? ?? [];
    if (structures.isNotEmpty) {
      await supabase.from('fee_structures').upsert(structures, onConflict: 'id');
    }

    final students = tables['students'] as List<dynamic>? ?? [];
    if (students.isNotEmpty) {
      await supabase.from('students').upsert(students, onConflict: 'id');
    }

    final payments = tables['payments'] as List<dynamic>? ?? [];
    if (payments.isNotEmpty) {
      await supabase.from('payments').upsert(payments, onConflict: 'id');
    }

    final records = tables['payment_records'] as List<dynamic>? ?? [];
    if (records.isNotEmpty) {
      await supabase.from('payment_records').upsert(records, onConflict: 'id');
    }

    final notifSettings = tables['notification_settings'] as List<dynamic>? ?? [];
    if (notifSettings.isNotEmpty) {
      await supabase.from('notification_settings').upsert(notifSettings, onConflict: 'id');
    }
  }
}

class GoogleBackupFile {
  final String id;
  final String name;
  final int sizeInBytes;
  final DateTime modifiedTime;

  GoogleBackupFile({
    required this.id,
    required this.name,
    required this.sizeInBytes,
    required this.modifiedTime,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
