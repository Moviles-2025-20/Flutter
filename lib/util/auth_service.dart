import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_provider_factory.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Login with provider using Factory
  Future<UserCredential> loginWithProvider(AuthProviderType type) async {
    try {
      // For Google
      if (type == AuthProviderType.google) {
        final credential = await AuthProviderFactory.createCredential(type);
        if (credential == null) {
          throw Exception('Google sign-in cancelled');
        }
        return await _auth.signInWithCredential(credential);
      }

      // AGREGAR DEMAS ------------------------------------------------------------------------


      throw UnimplementedError('Provider not implemented');
      
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    // Sign out from Google
    if (_auth.currentUser?.providerData
        .any((info) => info.providerId == 'google.com') ?? false) {
      await GoogleSignIn().signOut();
    }

    // AGREGAR DEMAS ------------------------------------------------------------------------
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}