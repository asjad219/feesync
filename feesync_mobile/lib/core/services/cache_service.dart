import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/student.dart';
import '../../models/batch.dart';
import '../../models/payment.dart';
import '../../models/app_settings.dart';
import '../../models/dashboard_stats.dart';
import '../../models/user_profile.dart';
import '../../models/account_profile.dart';

class CacheService {
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  // ── Generic Helpers ─────────────────────────────────────────────────────────

  String _getKey(String accountId, String entity) => 'feesync_${accountId}_$entity';

  void _saveList<T>(String key, List<T> items, Map<String, dynamic> Function(T) toJson) {
    try {
      final jsonList = items.map((e) => jsonEncode(toJson(e))).toList();
      _prefs.setStringList(key, jsonList);
      _saveSyncTime(key);
    } catch (e) {
      debugPrint('[CacheService] Failed to save list $key: $e');
    }
  }

  List<T>? _loadList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final jsonList = _prefs.getStringList(key);
      if (jsonList == null) return null;
      return jsonList.map((e) => fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[CacheService] Failed to load list $key: $e');
      return null;
    }
  }

  void _saveMap(String key, Map<String, dynamic> data) {
    try {
      _prefs.setString(key, jsonEncode(data));
      _saveSyncTime(key);
    } catch (e) {
      debugPrint('[CacheService] Failed to save map $key: $e');
    }
  }

  Map<String, dynamic>? _loadMap(String key) {
    try {
      final str = _prefs.getString(key);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[CacheService] Failed to load map $key: $e');
      return null;
    }
  }

  void _saveSyncTime(String key) {
    _prefs.setString('${key}_sync_time', DateTime.now().toIso8601String());
  }

  DateTime? loadLastSyncTime(String entity) {
    // Note: since the UI only asks for entity, we can search the keys or
    // we can just store global sync times if we don't have accountId context in UI.
    // Let's iterate keys to find the newest for this entity
    DateTime? latest;
    for (final key in _prefs.getKeys()) {
      if (key.endsWith('_${entity}_sync_time')) {
        final str = _prefs.getString(key);
        if (str != null) {
          final dt = DateTime.tryParse(str);
          if (dt != null && (latest == null || dt.isAfter(latest))) {
            latest = dt;
          }
        }
      }
    }
    return latest;
  }

  // ── Domain Methods ──────────────────────────────────────────────────────────

  Future<void> saveStudentBalances(String accountId, List<StudentBalance> balances) async {
    _saveList(_getKey(accountId, 'students'), balances, (b) => b.toJson());
  }

  List<StudentBalance>? loadStudentBalances(String accountId) {
    return _loadList(_getKey(accountId, 'students'), StudentBalance.fromJson);
  }

  Future<void> saveSettings(String accountId, AppSettings settings) async {
    _saveMap(_getKey(accountId, 'settings'), settings.toJson());
  }

  AppSettings? loadSettings(String accountId) {
    final data = _loadMap(_getKey(accountId, 'settings'));
    if (data == null) return null;
    return AppSettings.fromJson(data);
  }

  Future<void> savePayments(String accountId, List<Payment> payments) async {
    _saveList(_getKey(accountId, 'payments'), payments, (p) => p.toJson());
  }

  List<Payment>? loadPayments(String accountId) {
    return _loadList(_getKey(accountId, 'payments'), Payment.fromJson);
  }

  Future<void> saveDashboardStats(String accountId, DashboardStats stats) async {
    _saveMap(_getKey(accountId, 'dashboard_stats'), stats.toJson());
  }

  DashboardStats? loadDashboardStats(String accountId) {
    final data = _loadMap(_getKey(accountId, 'dashboard_stats'));
    if (data == null) return null;
    return DashboardStats.fromJson(data);
  }

  Future<void> saveMonthlyStats(String accountId, List<MonthlyStat> stats) async {
    _saveList(_getKey(accountId, 'monthly_stats'), stats, (s) => s.toJson());
  }

  List<MonthlyStat>? loadMonthlyStats(String accountId) {
    return _loadList(_getKey(accountId, 'monthly_stats'), MonthlyStat.fromJson);
  }

  Future<void> saveRecentTransactions(String accountId, List<RecentTransaction> txs) async {
    _saveList(_getKey(accountId, 'recent_transactions'), txs, (t) => t.toJson());
  }

  List<RecentTransaction>? loadRecentTransactions(String accountId) {
    return _loadList(_getKey(accountId, 'recent_transactions'), RecentTransaction.fromJson);
  }

  Future<void> saveBatches(String accountId, List<Batch> batches) async {
    _saveList(_getKey(accountId, 'batches'), batches, (b) => b.toJson());
  }

  List<Batch>? loadBatches(String accountId) {
    return _loadList(_getKey(accountId, 'batches'), Batch.fromJson);
  }

  Future<void> saveClassStats(String accountId, List<ClassStat> stats) async {
    _saveList(_getKey(accountId, 'class_stats'), stats, (s) => s.toJson());
  }

  List<ClassStat>? loadClassStats(String accountId) {
    return _loadList(_getKey(accountId, 'class_stats'), ClassStat.fromJson);
  }

  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    _saveMap('feesync_user_profile_$userId', profile.toJson());
  }

  UserProfile? loadUserProfile(String userId) {
    final data = _loadMap('feesync_user_profile_$userId');
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> saveAccountProfile(String accountId, AccountProfile profile) async {
    _saveMap('feesync_account_profile_$accountId', profile.toJson());
  }

  AccountProfile? loadAccountProfile(String accountId) {
    final data = _loadMap('feesync_account_profile_$accountId');
    if (data == null) return null;
    return AccountProfile.fromJson(data);
  }
}
