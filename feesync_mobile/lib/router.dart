import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/totp_prompt_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/students/student_list_screen.dart';
import 'screens/students/student_details_screen.dart';
import 'screens/students/add_edit_student_screen.dart';
import 'screens/fees/fees_screen.dart';
import 'screens/payments/payment_list_screen.dart';
import 'screens/payments/record_payment_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shell/main_shell.dart';
import 'screens/onboarding/onboarding_intro_screen.dart';
import 'screens/onboarding/center_setup_screen.dart';
import 'screens/onboarding/optional_profile_screen.dart';
import 'screens/onboarding/dashboard_empty_screen.dart';
import 'screens/onboarding/add_first_student_screen.dart';
import 'screens/onboarding/first_payment_screen.dart';
import 'screens/onboarding/receipt_preview_screen.dart';
import 'models/student.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final isSplashRoute = state.uri.path == '/splash';
      final isAuthRoute = state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/forgot-password' ||
          state.uri.path.startsWith('/auth/totp');
      final isOnboardingRoute = state.uri.path.startsWith('/onboarding');
      final user = Supabase.instance.client.auth.currentUser;
      final metadata = user?.userMetadata ?? {};
      final totpEnabled = metadata['totp_enabled'] == true;
      final totpSkipUsed = metadata['totp_skip_used'] == true;
      final onboardingComplete = metadata['onboarding_complete'] == true;
      final rawStep = metadata['onboarding_step']?.toString() ?? 'intro';
      final onboardingStep = rawStep.replaceAll('_', '-');

      if (isSplashRoute) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        if (!totpEnabled) {
          return totpSkipUsed ? '/auth/totp-required' : '/auth/totp';
        }

        if (!onboardingComplete) {
          return '/onboarding/$onboardingStep';
        }

        return '/dashboard';
      }

      if (isLoggedIn && !totpEnabled && !state.uri.path.startsWith('/auth/totp')) {
        return totpSkipUsed ? '/auth/totp-required' : '/auth/totp';
      }

      if (isLoggedIn && !onboardingComplete && !isOnboardingRoute) {
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
        path: '/auth/totp',
        builder: (context, state) => const TotpPromptScreen(
          isMandatory: false,
        ),
      ),
      GoRoute(
        path: '/auth/totp-required',
        builder: (context, state) => const TotpPromptScreen(
          isMandatory: true,
        ),
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
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddEditStudentScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => AddEditStudentScreen(
                  studentId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => StudentDetailsScreen(
                  studentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/fees',
            builder: (context, state) => const FeesScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentListScreen(),
            routes: [
              GoRoute(
                path: 'record',
                builder: (context, state) => RecordPaymentScreen(
                  student: state.extra as Student?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
