import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance.dart';
import 'supabase_provider.dart';
import 'batch_analytics_provider.dart';

import 'user_provider.dart';
import 'batch_provider.dart';
final batchAttendanceProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, batchId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('attendance')
      .select()
      .eq('batch_id', batchId)
      .order('date', ascending: false);
  
  return (response as List).map((json) => AttendanceRecord.fromJson(json)).toList();
});

class DailyAttendanceState {
  final Map<String, AttendanceStatus?> statuses;
  final bool isSaving;

  DailyAttendanceState({required this.statuses, this.isSaving = false});

  DailyAttendanceState copyWith({Map<String, AttendanceStatus?>? statuses, bool? isSaving}) {
    return DailyAttendanceState(
      statuses: statuses ?? this.statuses,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class DailyAttendanceNotifier extends StateNotifier<DailyAttendanceState> {
  final Ref _ref;
  final String _batchId;

  DailyAttendanceNotifier(this._ref, this._batchId) : super(DailyAttendanceState(statuses: {}));

  void setStatus(String studentId, AttendanceStatus status) {
    final newStatuses = Map<String, AttendanceStatus?>.from(state.statuses);
    newStatuses[studentId] = status;
    state = state.copyWith(statuses: newStatuses);
  }

  void markAllPresent(List<String> studentIds) {
    final newStatuses = Map<String, AttendanceStatus?>.from(state.statuses);
    for (final id in studentIds) {
      newStatuses[id] = AttendanceStatus.present;
    }
    state = state.copyWith(statuses: newStatuses);
  }

  Future<void> saveAttendance() async {
    if (state.statuses.isEmpty) return;
    state = state.copyWith(isSaving: true);
    
    try {
      final client = _ref.read(supabaseClientProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);
      final accountId = userProfile?.accountId;
      
      if (accountId == null) throw Exception('User account not identified');

      final records = state.statuses.entries.map((e) => {
        'account_id': accountId,
        'batch_id': _batchId,
        'student_id': e.key,
        'status': e.value!.name,
        'date': DateTime.now().toIso8601String().split('T')[0],
      }).toList();

      await client.from('attendance').upsert(
        records,
        onConflict: 'student_id,batch_id,date',
      );
      
      // Invalidate both history and analytics to ensure UI updates
      _ref.invalidate(batchAttendanceProvider(_batchId));
      _ref.invalidate(batchAnalyticsProvider(_batchId));
      _ref.invalidate(batchByIdProvider(_batchId));
      _ref.invalidate(batchNotifierProvider);
      
      // Reset marking state after successful save
      state = DailyAttendanceState(statuses: {});
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final dailyAttendanceProvider = StateNotifierProvider.family<DailyAttendanceNotifier, DailyAttendanceState, String>((ref, batchId) {
  return DailyAttendanceNotifier(ref, batchId);
});
