import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/staff_repository.dart';
import 'supabase_provider.dart';
import 'user_provider.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(supabaseClientProvider));
});

final staffListProvider = FutureProvider<List<UserProfile>>((ref) async {
  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null) return [];
  
  return ref.watch(staffRepositoryProvider).getStaffMembers(userProfile.accountId);
});

class StaffNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  StaffNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> inviteStaff({
    required String email,
    required String fullName,
    required String role,
    required Map<String, dynamic> permissions,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(staffRepositoryProvider).inviteStaff(
        email: email,
        fullName: fullName,
        role: role,
        permissions: permissions,
      );
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStaff(String userId, {
    String? role,
    Map<String, dynamic>? permissions,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(staffRepositoryProvider).updateStaff(
        userId,
        role: role,
        permissions: permissions,
        isActive: isActive,
      );
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteStaff(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(staffRepositoryProvider).deleteStaff(userId);
      _ref.invalidate(staffListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final staffNotifierProvider = StateNotifierProvider<StaffNotifier, AsyncValue<void>>((ref) {
  return StaffNotifier(ref);
});
