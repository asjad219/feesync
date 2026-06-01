import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: FeeSyncApp(),
    ),
  );
}

class FeeSyncApp extends ConsumerWidget {
  const FeeSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = settingsAsync.value?.themeMode.toLowerCase() ?? 'dark_luxury';
    final isLight = themeMode.contains('light');
    AppColors.isDarkMode = !isLight;
    final appTitle = settingsAsync.value?.centerName.isNotEmpty == true
        ? settingsAsync.value!.centerName
        : 'FeeSync';

    return MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: isLight ? AppTheme.lightTheme : AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
