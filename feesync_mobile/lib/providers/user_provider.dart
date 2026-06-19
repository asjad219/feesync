import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_profile.dart';
import '../models/user_profile.dart';
import '../repositories/account_repository.dart';
import '../repositories/user_repository.dart';
import 'supabase_provider.dart';
import 'sync_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserRepository(client);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AccountRepository(client);
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;
  
  final cache = ref.watch(cacheServiceProvider);
  final repository = ref.watch(userRepositoryProvider);
  
  final cachedProfile = await cache.loadUserProfile(user.id);
  
  try {
    final profile = await repository.getCurrentUserProfile().timeout(
      const Duration(seconds: 10),
    );
    if (profile != null) {
      await cache.saveUserProfile(user.id, profile);
      return profile;
    }
  } catch (e) {
    debugPrint('[UserProvider][OFFLINE] getCurrentUserProfile failed: $e');
    if (cachedProfile != null) {
      return cachedProfile;
    }
  }
  return cachedProfile;
});

final accountProfileProvider = FutureProvider<AccountProfile?>((ref) async {
  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null) return null;
  
  final cache = ref.watch(cacheServiceProvider);
  final repository = ref.watch(accountRepositoryProvider);
  
  final cachedAccount = await cache.loadAccountProfile(userProfile.accountId);
  
  try {
    final account = await repository.getAccountProfile(userProfile.accountId).timeout(
      const Duration(seconds: 10),
    );
    if (account != null) {
      await cache.saveAccountProfile(userProfile.accountId, account);
      return account;
    }
  } catch (e) {
    debugPrint('[UserProvider][OFFLINE] getAccountProfile failed: $e');
    if (cachedAccount != null) {
      return cachedAccount;
    }
  }
  return cachedAccount;
});
