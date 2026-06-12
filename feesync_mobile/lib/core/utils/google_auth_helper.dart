import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Helper class to handle Google Sign-In and Supabase integration.
class GoogleAuthHelper {
  /// Performs Google Sign-In.
  /// Uses native Google Sign-In if googleWebClientId is configured.
  /// Falls back to browser-based OAuth flow if no client ID is set.
  static Future<void> signInWithGoogle() async {
    final clientId = SupabaseConfig.googleWebClientId;

    if (clientId.isEmpty || clientId.startsWith('YOUR_')) {
      await _signInWithOAuth();
    } else {
      await _signInNatively(clientId);
    }
  }

  /// Performs browser-based OAuth sign-in fallback.
  static Future<void> _signInWithOAuth() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'feesync://reset-password',
    );
  }

  /// Performs native Google Sign-In using the configured Web Client ID.
  static Future<void> _signInNatively(String webClientId) async {
    final nativeGoogleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: const ['email', 'profile'],
    );

    final googleUser = await nativeGoogleSignIn.signIn();
    if (googleUser == null) {
      throw 'Google Sign-In was canceled by the user.';
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw 'Failed to retrieve Google ID token.';
    }

    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
