import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'revenue_cat_service.dart';

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

final revenueCatInitProvider = FutureProvider<void>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return; // unauthenticated — RC init deferred to login
  final service = ref.read(revenueCatServiceProvider);
  await service.initialize(userId: userId);
});

final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  return ref.watch(revenueCatServiceProvider).customerInfoStream;
});

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return ref.watch(revenueCatServiceProvider).currentCustomerInfo();
});

final rcOfferingsProvider = FutureProvider<Offerings>((ref) async {
  return ref.watch(revenueCatServiceProvider).getOfferings();
});

class RcPurchaseController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is idle (null error, null data -> void)
  }

  Future<void> purchase(Package package) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(revenueCatServiceProvider);
      await service.purchase(package);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> restore() async {
    state = const AsyncLoading();
    try {
      final service = ref.read(revenueCatServiceProvider);
      await service.restorePurchases();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final rcPurchaseControllerProvider = AsyncNotifierProvider<RcPurchaseController, void>(
  () => RcPurchaseController(),
);
