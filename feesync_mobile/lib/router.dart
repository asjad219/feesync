import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/network_service.dart';
import 'screens/offline/offline_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/update_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/students/student_list_screen.dart';
import 'screens/students/student_details_screen.dart';
import 'screens/students/add_edit_student_screen.dart';
import 'screens/fees/fees_screen.dart';
import 'screens/payments/payment_list_screen.dart';
import 'screens/payments/record_payment_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/screens/institution_settings_screen.dart';
import 'screens/settings/screens/billing_settings_screen.dart';
import 'screens/settings/screens/automation_settings_screen.dart';
import 'screens/settings/screens/ai_settings_screen.dart';
import 'screens/settings/screens/security_settings_screen.dart';
import 'screens/settings/screens/data_management_screen.dart';
import 'screens/settings/screens/import_data_screen.dart';
import 'screens/settings/screens/export_data_screen.dart';
import 'screens/settings/screens/subscription_screen.dart';
import 'screens/settings/screens/policy_viewer_screen.dart';
import 'screens/settings/screens/staff_list_screen.dart';
import 'screens/settings/screens/invite_edit_staff_screen.dart';
import 'screens/shell/main_shell.dart';
import 'screens/onboarding/onboarding_intro_screen.dart';
import 'screens/onboarding/center_setup_screen.dart';
import 'screens/onboarding/optional_profile_screen.dart';
import 'screens/onboarding/dashboard_empty_screen.dart';
import 'screens/onboarding/add_first_student_screen.dart';
import 'screens/onboarding/first_payment_screen.dart';
import 'screens/onboarding/receipt_preview_screen.dart';
import 'screens/batches/batch_list_screen.dart';
import 'screens/batches/batch_creation_screen.dart';
import 'screens/batches/batch_detail_screen.dart';
import 'models/student.dart';
import 'models/user_profile.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    errorBuilder: (context, state) => const SplashScreen(),
    redirect: (context, state) {

      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isSplashRoute = state.uri.path == '/splash';
      final isAuthRoute = state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/forgot-password' ||
          state.uri.path == '/update-password';
      final isOnboardingRoute = state.uri.path.startsWith('/onboarding');
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata ?? {};
      final onboardingComplete = metadata['onboarding_complete'] == true ||
          metadata['onboarding_center_setup_complete'] == true;
      final rawStep = metadata['onboarding_step']?.toString() ?? 'intro';
      final onboardingStep = rawStep.replaceAll('_', '-');
      final needsPasswordSet = metadata['needs_password_set'] == true;

      if (isSplashRoute) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn) {
        if (needsPasswordSet && state.uri.path != '/update-password') {
          return '/update-password';
        }
      }

      if (isLoggedIn && isAuthRoute) {
        if (state.uri.path == '/update-password') {
          return null;
        }
        if (!onboardingComplete) {
          return '/onboarding/$onboardingStep';
        }
        return '/dashboard';
      }

      if (isLoggedIn && !onboardingComplete && !isOnboardingRoute && !needsPasswordSet) {
        return '/onboarding/$onboardingStep';
      }

      if (isLoggedIn && onboardingComplete && isOnboardingRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Offline screen
      GoRoute(
        path: '/offline',
        builder: (context, state) => OfflineScreen(
          fromPath: state.uri.queryParameters['from'],
        ),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),

      // Onboarding routes
      GoRoute(
        path: '/onboarding/intro',
        builder: (context, state) => const OnboardingIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding/center-setup',
        builder: (context, state) => const CenterSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/optional-profile',
        builder: (context, state) => const OptionalProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/dashboard-empty',
        builder: (context, state) => const DashboardEmptyScreen(),
      ),
      GoRoute(
        path: '/onboarding/add-student',
        builder: (context, state) => const AddFirstStudentScreen(),
      ),
      GoRoute(
        path: '/onboarding/first-payment',
        builder: (context, state) => FirstPaymentScreen(
          studentId: state.uri.queryParameters['studentId'],
        ),
      ),
      GoRoute(
        path: '/onboarding/receipt-preview',
        builder: (context, state) => ReceiptPreviewScreen(
          args: state.extra as ReceiptPreviewArgs?,
        ),
      ),

      // Main app routes with shell
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) {
          return MainShell(navigationShell: navigationShell, children: children);
        },
        builder: (context, state, navigationShell) {
          // Must return navigationShell so GoRouter puts StatefulNavigationShell
          // in the widget tree. navigatorContainerBuilder is then invoked by
          // navigationShell.build() to produce the actual MainShell UI.
          // Returning SizedBox.shrink() here caused the black screen — the shell
          // was never rendered because navigationShell was never mounted.
          return navigationShell;
        },

        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
              GoRoute(
                path: '/fees',
                builder: (context, state) => const FeesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/batches',
                builder: (context, state) => const BatchListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/students',
                builder: (context, state) => const StudentListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payments',
                builder: (context, state) => PaymentListScreen(
                  studentId: state.uri.queryParameters['studentId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes (Outside Shell)
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings/institution',
        builder: (context, state) => const InstitutionSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/billing',
        builder: (context, state) => const BillingSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/automation',
        builder: (context, state) => const AutomationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/ai',
        builder: (context, state) => const AiSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/data',
        builder: (context, state) => const DataManagementScreen(),
      ),
      GoRoute(
        path: '/settings/data/import',
        builder: (context, state) => const ImportDataScreen(),
      ),
      GoRoute(
        path: '/settings/data/export',
        builder: (context, state) => const ExportDataScreen(),
      ),
      GoRoute(
        path: '/settings/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings/staff',
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: '/settings/staff/invite',
        builder: (context, state) => InviteEditStaffScreen(
          existingStaff: state.extra as UserProfile?,
        ),
      ),
      GoRoute(
        path: '/settings/policy',
        builder: (context, state) => PolicyViewerScreen(
          type: state.uri.queryParameters['type'] ?? 'terms',
        ),
      ),
      GoRoute(
        path: '/batches/create',
        builder: (context, state) => BatchCreationScreen(
          batchId: state.uri.queryParameters['batchId'],
        ),
      ),
      GoRoute(
        path: '/batches/:id',
        builder: (context, state) => BatchDetailScreen(
          batchId: state.pathParameters['id']!,
          initialTabIndex: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/students/add',
        builder: (context, state) => AddEditStudentScreen(
          initialBatchId: state.uri.queryParameters['batchId'],
        ),
      ),
      GoRoute(
        path: '/students/edit/:id',
        builder: (context, state) => AddEditStudentScreen(
          studentId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (context, state) => StudentDetailsScreen(
          studentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/payments/record',
        builder: (context, state) => RecordPaymentScreen(
          student: state.extra as Student?,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );

  // Listen for password recovery events to navigate to update-password
  final subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      router.go('/update-password');
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });

  return router;
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> authStream) {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    _authSubscription = authStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
