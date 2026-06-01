import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../models/notification_settings.dart';
import '../repositories/notification_repository.dart';
import 'supabase_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationRepository(client);
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => n.status == NotificationStatus.pending).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final notificationSettingsProvider = FutureProvider<NotificationSettings?>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationSettings();
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsSent(String id) async {
    try {
      await _repository.updateNotificationStatus(id, 'sent');
      await loadNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      await loadNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    _ref.invalidate(notificationsProvider);
    await loadNotifications();
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository, ref);
});
