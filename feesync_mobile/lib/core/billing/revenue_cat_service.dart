import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatException implements Exception {
  final String message;
  final String? code;
  RevenueCatException(this.message, {this.code});

  @override
  String toString() => 'RevenueCatException: $message (code: $code)';
}

class RevenueCatService {
  static const String _androidApiKey = 'goog_oNzotQBqlZkwQOkPAhTVjWOfcYM';
  
  final StreamController<CustomerInfo> _customerInfoStreamController = StreamController<CustomerInfo>.broadcast();

  RevenueCatService() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _customerInfoStreamController.add(customerInfo);
    });
  }

  Future<void> initialize({required String userId}) async {
    try {
      await Purchases.setLogLevel(LogLevel.info);
      
      final configuration = PurchasesConfiguration(_androidApiKey)
        ..appUserID = userId;
        
      await Purchases.configure(configuration);
      log('RevenueCat initialized for user: $userId');
    } on PlatformException catch (e) {
      log('RevenueCat init error: ${e.message}');
      throw RevenueCatException(e.message ?? 'Unknown init error', code: e.code);
    } catch (e) {
      log('RevenueCat init error: $e');
      throw RevenueCatException(e.toString());
    }
  }

  Future<void> logIn(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      log('RevenueCat logged in user: $userId (created: ${result.created})');
      _customerInfoStreamController.add(result.customerInfo);
    } on PlatformException catch (e) {
      throw RevenueCatException(e.message ?? 'Unknown login error', code: e.code);
    } catch (e) {
      throw RevenueCatException(e.toString());
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      log('RevenueCat logged out');
      final info = await Purchases.getCustomerInfo();
      _customerInfoStreamController.add(info);
    } on PlatformException catch (e) {
      throw RevenueCatException(e.message ?? 'Unknown logout error', code: e.code);
    } catch (e) {
      throw RevenueCatException(e.toString());
    }
  }

  Future<CustomerInfo> currentCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      throw RevenueCatException(e.message ?? 'Unknown error fetching customer info', code: e.code);
    } catch (e) {
      throw RevenueCatException(e.toString());
    }
  }

  Stream<CustomerInfo> get customerInfoStream => _customerInfoStreamController.stream;

  Future<CustomerInfo> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo;
    } on PlatformException catch (e) {
      throw RevenueCatException(e.message ?? 'Unknown purchase error', code: e.code);
    } catch (e) {
      throw RevenueCatException(e.toString());
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      throw RevenueCatException(e.message ?? 'Unknown restore error', code: e.code);
    } catch (e) {
      throw RevenueCatException(e.toString());
    }
  }

  Future<Offerings> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      throw RevenueCatException(e.message ?? 'Unknown offerings error', code: e.code);
    } catch (e) {
      throw RevenueCatException(e.toString());
    }
  }
}
