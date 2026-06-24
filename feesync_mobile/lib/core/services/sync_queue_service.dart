import '../../models/sync_task.dart';
import 'cache_service.dart';

class SyncQueueService {
  final CacheService _cache;

  SyncQueueService(this._cache);

  Future<List<SyncTask>> getPendingTasks() async {
    final list = await _cache.loadSyncTasks();
    return list ?? [];
  }

  Future<void> enqueueTask(SyncTask task) async {
    final tasks = await getPendingTasks();
    tasks.add(task);
    await _cache.saveSyncTasks(tasks);
  }

  Future<void> removeTask(String id) async {
    final tasks = await getPendingTasks();
    tasks.removeWhere((t) => t.id == id);
    await _cache.saveSyncTasks(tasks);
  }

  Future<void> incrementRetry(String id) async {
    final tasks = await getPendingTasks();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      tasks[index].retryCount++;
      await _cache.saveSyncTasks(tasks);
    }
  }
}
