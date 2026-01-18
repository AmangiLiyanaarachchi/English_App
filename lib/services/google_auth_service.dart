import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Auto-detects and signs in with Google account silently if possible
  /// Returns the signed-in account or null if user needs to pick account
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      print('🔍 [GoogleAuth] Attempting silent sign-in...');
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        print('✅ [GoogleAuth] Silent sign-in successful: ${account.email}');
      } else {
        print('ℹ️ [GoogleAuth] No cached account found');
      }
      return account;
    } catch (e) {
      print('❌ [GoogleAuth] Silent sign-in failed: $e');
      return null;
    }
  }

  /// Shows the Google account picker and signs in
  Future<GoogleSignInAccount?> signIn() async {
    try {
      print('📱 [GoogleAuth] Showing account picker...');
      final account = await _googleSignIn.signIn();
      if (account != null) {
        print('✅ [GoogleAuth] User selected: ${account.email}');
      } else {
        print('ℹ️ [GoogleAuth] User cancelled sign-in');
      }
      return account;
    } catch (e) {
      print('❌ [GoogleAuth] Sign-in failed: $e');
      rethrow;
    }
  }

  /// Sign in with Google and authenticate with Firebase
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // First, try silent sign-in
      GoogleSignInAccount? account = await signInSilently();

      // If no cached account, show the picker
      account ??= await signIn();

      if (account == null) {
        print('ℹ️ [GoogleAuth] User cancelled sign-in');
        return null;
      }

      print('🔐 [GoogleAuth] Authenticating with Firebase...');
      // Get the authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await account.authentication;

      // Create a credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      print(
          '✅ [GoogleAuth] Firebase authentication successful: ${userCredential.user?.uid}');

      return userCredential;
    } catch (e) {
      print('❌ [GoogleAuth] Google sign-in with Firebase failed: $e');
      rethrow;
    }
  }

  /// Get currently signed-in Google account (if any)
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if user is currently signed in to Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      print('👋 [GoogleAuth] Signing out from Google...');
      await _googleSignIn.signOut();
      await _auth.signOut();
      print('✅ [GoogleAuth] Sign-out successful');
    } catch (e) {
      print('❌ [GoogleAuth] Sign-out failed: $e');
      rethrow;
    }
  }

  /// Disconnect Google account completely
  Future<void> disconnect() async {
    try {
      print('🔌 [GoogleAuth] Disconnecting Google account...');
      await _googleSignIn.disconnect();
      await _auth.signOut();
      print('✅ [GoogleAuth] Disconnect successful');
    } catch (e) {
      print('❌ [GoogleAuth] Disconnect failed: $e');
      rethrow;
    }
  }
}
