import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide Batch;
import 'package:path/path.dart';
import '../../models/student.dart';
import '../../models/batch.dart';
import '../../models/payment.dart';
import '../../models/app_settings.dart';
import '../../models/dashboard_stats.dart';
import '../../models/user_profile.dart';
import '../../models/account_profile.dart';
import '../../models/sync_task.dart';

class CacheService {
  final Database _db;

  CacheService(this._db);

  static Future<CacheService> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'feesync_cache.db');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
    return CacheService(db);
  }

  // ── Generic Helpers ─────────────────────────────────────────────────────────

  String _getKey(String accountId, String entity) => 'feesync_${accountId}_$entity';

  Future<void> _saveList<T>(String key, List<T> items, Map<String, dynamic> Function(T) toJson) async {
    try {
      final jsonList = items.map((e) => jsonEncode(toJson(e))).toList();
      final str = jsonEncode(jsonList);
      await _db.insert(
        'cache',
        {'key': key, 'value': str, 'updated_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[CacheService] Failed to save list $key: $e');
    }
  }

  Future<List<T>?> _loadList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'cache',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isEmpty) return null;

      final str = maps.first['value'] as String?;
      if (str == null) return null;

      final jsonList = jsonDecode(str) as List<dynamic>;
      return jsonList.map((e) => fromJson(jsonDecode(e as String) as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[CacheService] Failed to load list $key: $e');
      return null;
    }
  }

  Future<void> _saveMap(String key, Map<String, dynamic> data) async {
    try {
      final str = jsonEncode(data);
      await _db.insert(
        'cache',
        {'key': key, 'value': str, 'updated_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[CacheService] Failed to save map $key: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadMap(String key) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'cache',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isEmpty) return null;

      final str = maps.first['value'] as String?;
      if (str == null) return null;

      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[CacheService] Failed to load map $key: $e');
      return null;
    }
  }

  Future<DateTime?> loadLastSyncTime(String entity) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'cache',
        columns: ['updated_at'],
        where: 'key LIKE ?',
        whereArgs: ['%_$entity'],
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      if (maps.isEmpty) return null;
      
      final str = maps.first['updated_at'] as String?;
      if (str == null) return null;
      return DateTime.tryParse(str);
    } catch (e) {
      return null;
    }
  }

  // ── Domain Methods ──────────────────────────────────────────────────────────

  Future<void> saveStudentBalances(String accountId, List<StudentBalance> balances) async {
    await _saveList(_getKey(accountId, 'students'), balances, (b) => b.toJson());
  }

  Future<List<StudentBalance>?> loadStudentBalances(String accountId) async {
    return _loadList(_getKey(accountId, 'students'), StudentBalance.fromJson);
  }

  Future<void> saveSettings(String accountId, AppSettings settings) async {
    await _saveMap(_getKey(accountId, 'settings'), settings.toJson());
  }

  Future<AppSettings?> loadSettings(String accountId) async {
    final data = await _loadMap(_getKey(accountId, 'settings'));
    if (data == null) return null;
    return AppSettings.fromJson(data);
  }

  Future<void> savePayments(String accountId, List<Payment> payments) async {
    await _saveList(_getKey(accountId, 'payments'), payments, (p) => p.toJson());
  }

  Future<List<Payment>?> loadPayments(String accountId) async {
    return _loadList(_getKey(accountId, 'payments'), Payment.fromJson);
  }

  Future<void> saveDashboardStats(String accountId, DashboardStats stats) async {
    await _saveMap(_getKey(accountId, 'dashboard_stats'), stats.toJson());
  }

  Future<DashboardStats?> loadDashboardStats(String accountId) async {
    final data = await _loadMap(_getKey(accountId, 'dashboard_stats'));
    if (data == null) return null;
    return DashboardStats.fromJson(data);
  }

  Future<void> saveMonthlyStats(String accountId, List<MonthlyStat> stats) async {
    await _saveList(_getKey(accountId, 'monthly_stats'), stats, (s) => s.toJson());
  }

  Future<List<MonthlyStat>?> loadMonthlyStats(String accountId) async {
    return _loadList(_getKey(accountId, 'monthly_stats'), MonthlyStat.fromJson);
  }

  Future<void> saveWeeklyStats(String accountId, List<MonthlyStat> stats) async {
    await _saveList(_getKey(accountId, 'weekly_stats'), stats, (s) => s.toJson());
  }

  Future<List<MonthlyStat>?> loadWeeklyStats(String accountId) async {
    return _loadList(_getKey(accountId, 'weekly_stats'), MonthlyStat.fromJson);
  }

  Future<void> saveRecentTransactions(String accountId, List<RecentTransaction> txs) async {
    await _saveList(_getKey(accountId, 'recent_transactions'), txs, (t) => t.toJson());
  }

  Future<List<RecentTransaction>?> loadRecentTransactions(String accountId) async {
    return _loadList(_getKey(accountId, 'recent_transactions'), RecentTransaction.fromJson);
  }

  Future<void> saveBatches(String accountId, List<Batch> batches) async {
    await _saveList(_getKey(accountId, 'batches'), batches, (b) => b.toJson());
  }

  Future<List<Batch>?> loadBatches(String accountId) async {
    return _loadList(_getKey(accountId, 'batches'), Batch.fromJson);
  }

  Future<void> saveClassStats(String accountId, List<ClassStat> stats) async {
    await _saveList(_getKey(accountId, 'class_stats'), stats, (s) => s.toJson());
  }

  Future<List<ClassStat>?> loadClassStats(String accountId) async {
    return _loadList(_getKey(accountId, 'class_stats'), ClassStat.fromJson);
  }

  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    await _saveMap('feesync_user_profile_$userId', profile.toJson());
  }

  Future<UserProfile?> loadUserProfile(String userId) async {
    final data = await _loadMap('feesync_user_profile_$userId');
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> saveAccountProfile(String accountId, AccountProfile profile) async {
    await _saveMap('feesync_account_profile_$accountId', profile.toJson());
  }

  Future<AccountProfile?> loadAccountProfile(String accountId) async {
    final data = await _loadMap('feesync_account_profile_$accountId');
    if (data == null) return null;
    return AccountProfile.fromJson(data);
  }
  Future<void> saveSyncTasks(List<SyncTask> tasks) async {
    await _saveList('feesync_offline_queue', tasks, (t) => t.toJson());
  }

  Future<List<SyncTask>?> loadSyncTasks() async {
    return _loadList('feesync_offline_queue', SyncTask.fromJson);
  }
}
