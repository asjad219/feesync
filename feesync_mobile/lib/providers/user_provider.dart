import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_profile.dart';
import '../models/user_profile.dart';
import '../repositories/account_repository.dart';
import '../repositories/user_repository.dart';
import 'supabase_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserRepository(client);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AccountRepository(client);
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUserProfile();
});

final accountProfileProvider = FutureProvider<AccountProfile?>((ref) async {
  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null) return null;
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAccountProfile(userProfile.accountId);
});
