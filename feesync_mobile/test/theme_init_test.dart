import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feesync_mobile/providers/settings_provider.dart';
import 'package:feesync_mobile/providers/user_provider.dart';
import 'package:feesync_mobile/models/user_profile.dart';
import 'package:feesync_mobile/models/app_settings.dart';
import 'package:feesync_mobile/repositories/settings_repository.dart';
import 'package:feesync_mobile/providers/sync_provider.dart';

// Helper function to create mock AppSettings
AppSettings createMockSettings({
  required String id,
  required String accountId,
  required String themeMode,
}) {
  return AppSettings(
    id: id,
    accountId: accountId,
    centerName: 'Test Academy',
    academicYear: '2024-25',
    currency: 'INR',
    timezone: 'IST',
    gstEnabled: true,
    qrVerificationEnabled: true,
    parentPortalEnabled: true,
    digitalSignatureEnabled: false,
    defaultDueDay: 5,
    autoDueGeneration: true,
    lateFinesEnabled: true,
    lateFineAmount: 100.0,
    gracePeriodDays: 3,
    partialPaymentsAllowed: true,
    aiRemindersEnabled: true,
    aiPredictionsEnabled: true,
    ocrEnabled: true,
    whatsappEnabled: true,
    smsFallbackEnabled: true,
    autoReceiptEnabled: true,
    themeMode: themeMode,
    dashboardLayout: 'bento',
    glassEffectsEnabled: true,
    tplFeeReminder: 'Hello',
    tplPaymentReceipt: 'Receipt',
    tplOverdueNotice: 'Overdue',
    tplLateFineApplied: 'Fine',
    tplNewFeeGenerated: 'New Fee',
  );
}

// Create Fakes for testing
class MockSettingsRepository implements SettingsRepository {
  AppSettings? mockSettings;
  int getSettingsCount = 0;

  @override
  Future<AppSettings?> getSettings() async {
    getSettingsCount++;
    return mockSettings;
  }

  @override
  Future<AppSettings> updateSettings(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Theme Initialization & settingsProvider Tests', () {
    late MockSettingsRepository mockRepository;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockRepository = MockSettingsRepository();
    });

    test('Initial state is loading and does not load settings if profile is null', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(mockRepository),
          currentUserProfileProvider.overrideWith((ref) => Future.value(null)),
        ],
      );

      addTearDown(container.dispose);

      // Verify initially loading (note: the constructor calls loadSettings once)
      expect(container.read(settingsProvider), const AsyncValue<AppSettings>.loading());
      expect(mockRepository.getSettingsCount, 1);
    });

    test('Loads settings when user profile becomes available (login transition)', () async {
      // Create user profile behavior
      final userProfileNotifier = StateProvider<UserProfile?>((ref) => null);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(mockRepository),
          // Override currentUserProfileProvider to watch our controller StateProvider
          currentUserProfileProvider.overrideWith((ref) => ref.watch(userProfileNotifier)),
        ],
      );

      addTearDown(container.dispose);

      // Setup repository mock response
      mockRepository.mockSettings = createMockSettings(
        id: 'settings-123',
        accountId: 'test-acc-123',
        themeMode: 'light',
      );

      // Verify initially loading
      expect(container.read(settingsProvider), const AsyncValue<AppSettings>.loading());
      expect(mockRepository.getSettingsCount, 1); // 1 from constructor

      // Simulate login by updating userProfile
      container.read(userProfileNotifier.notifier).state = UserProfile(
        id: 'user-123',
        accountId: 'test-acc-123',
        email: 'test@feesync.com',
        fullName: 'Test User',
        role: 'admin',
      );

      // Wait for the state to be loaded (transition completes)
      while (container.read(settingsProvider).isLoading) {
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // Read settingsProvider
      final state = container.read(settingsProvider);
      expect(state, isA<AsyncData<AppSettings>>());
      expect(state.value?.themeMode, equals('light'));
      expect(mockRepository.getSettingsCount, 2); // 1 constructor + 1 login listener
    });

    test('Clears settings to loading state on logout (profile becomes null)', () async {
      final userProfileNotifier = StateProvider<UserProfile?>((ref) => UserProfile(
        id: 'user-123',
        accountId: 'test-acc-123',
        email: 'test@feesync.com',
        fullName: 'Test User',
        role: 'admin',
      ));

      mockRepository.mockSettings = createMockSettings(
        id: 'settings-123',
        accountId: 'test-acc-123',
        themeMode: 'dark_luxury',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(mockRepository),
          currentUserProfileProvider.overrideWith((ref) => ref.watch(userProfileNotifier)),
        ],
      );

      addTearDown(container.dispose);

      // Wait for the state to be loaded
      while (container.read(settingsProvider).isLoading) {
        await Future.delayed(const Duration(milliseconds: 5));
      }

      expect(container.read(settingsProvider).value?.themeMode, equals('dark_luxury'));
      expect(mockRepository.getSettingsCount, 1);

      // Simulate logout
      container.read(userProfileNotifier.notifier).state = null;
      
      // Since notifier.clearSettings() runs synchronously in the listener, it updates the state immediately
      expect(container.read(settingsProvider), const AsyncValue<AppSettings>.loading());
    });
  });
}
