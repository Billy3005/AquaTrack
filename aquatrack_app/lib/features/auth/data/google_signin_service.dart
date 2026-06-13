import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

/// Thin wrapper around the google_sign_in plugin (ADR 0006).
///
/// Its only job is to run the platform account-picker UI and hand back the
/// Google ID token; verification and session creation belong to the backend.
/// Wrapped so the auth state notifier can be tested without the plugin.
class GoogleSignInService {
  static const String _tag = 'GoogleSignInService';

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _client {
    // serverClientId (the OAuth Web client ID) is what makes Android include
    // an ID token in the result; without it Google sign-in cannot work.
    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email'],
      serverClientId: AppConstants.googleServerClientId.isEmpty
          ? null
          : AppConstants.googleServerClientId,
    );
  }

  /// Open the Google account picker and return the ID token.
  /// Returns null when the user dismisses the picker (not an error).
  Future<String?> getIdToken() async {
    final account = await _client.signIn();
    if (account == null) {
      AppLogger.info(_tag, 'Google sign-in cancelled by user');
      return null;
    }

    final auth = await account.authentication;
    if (auth.idToken == null) {
      AppLogger.error(
        _tag,
        'Google returned no ID token — is GOOGLE_SERVER_CLIENT_ID configured?',
      );
    }
    return auth.idToken;
  }

  /// Drop the plugin's cached account so the next sign-in shows the picker.
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } catch (e) {
      AppLogger.error(_tag, 'Google sign-out failed', e);
    }
  }
}
