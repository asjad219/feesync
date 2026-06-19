import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/sync_task.dart';

class SyncQueueService {
  final SharedPreferences _prefs;
  static const _key = 'feesync_offline_queue';

  SyncQueueService(this._prefs);

  List<SyncTask> getPendingTasks() {
    final list = _prefs.getStringList(_key);
    if (list == null) return [];
    return list.map((e) => SyncTask.fromJson(jsonDecode(e))).toList();
  }

  Future<void> enqueueTask(SyncTask task) async {
    final tasks = getPendingTasks();
    tasks.add(task);
    await _saveTasks(tasks);
  }

  Future<void> removeTask(String id) async {
    final tasks = getPendingTasks();
    tasks.removeWhere((t) => t.id == id);
    await _saveTasks(tasks);
  }

  Future<void> incrementRetry(String id) async {
    final tasks = getPendingTasks();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index].retryCount++;
      await _saveTasks(tasks);
    }
  }

  Future<void> _saveTasks(List<SyncTask> tasks) async {
    final list = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_key, list);
  }
}
