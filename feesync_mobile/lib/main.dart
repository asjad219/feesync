import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/billing/billing_provider.dart';
import 'core/services/sync_service.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';

import 'core/widgets/app_lock_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(() async {
    // Initialize Firebase (non-fatal if it fails)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }

    // Initialize Supabase
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase init error: $e');
      // Do NOT crash — app may still work offline with cached data
      // Only show error if it was a config problem (not a network problem)
      if (e.toString().contains('invalid') || e.toString().contains('config')) {
        runApp(_ErrorApp(error: 'Invalid server configuration: $e'));
        return;
      }
    }

    // Initialize SharedPreferences for local cache
    final prefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          // Provide the SharedPreferences instance to the provider graph
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FeeSyncApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class FeeSyncApp extends ConsumerWidget {
  const FeeSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize billing service once at startup.
    ref.watch(billingInitProvider);

    // Initialize sync service — auto-syncs when network restores.
    ref.watch(syncServiceProvider);

    final router = ref.watch(routerProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final themeModeStr =
        settingsAsync.value?.themeMode.toLowerCase() ?? 'dark_luxury';

    ThemeMode appThemeMode;
    if (themeModeStr == 'system') {
      appThemeMode = ThemeMode.system;
      AppColors.isDarkMode =
          PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    } else if (themeModeStr.contains('light')) {
      appThemeMode = ThemeMode.light;
      AppColors.isDarkMode = false;
    } else {
      appThemeMode = ThemeMode.dark;
      AppColors.isDarkMode = true;
    }

    final appTitle = settingsAsync.value?.centerName.isNotEmpty == true
        ? settingsAsync.value!.centerName
        : 'FeeSync';

    return MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appThemeMode,
      routerConfig: router,
      builder: (context, child) {
        return AppLockGuard(child: child!);
      },
    );
  }
}

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'App Failed to Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
