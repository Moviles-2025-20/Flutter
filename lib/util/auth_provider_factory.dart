import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProviderFactory {
  // Factory method to create authentication credentials
  static Future<OAuthCredential?> createCredential(
    AuthProviderType type,
  ) async {
    switch (type) {
      case AuthProviderType.google:
        return await _createGoogleCredential();
      case AuthProviderType.github:
        return await _createGithubCredential();
    }
  }

  // Google Authentication
  static Future<OAuthCredential?> _createGoogleCredential() async {
    try {
      final GoogleSignIn googleSignIn =  GoogleSignIn(
        scopes: ['email', 'profile'], //Ask permissions
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credentials = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return credentials;

    } catch (e) {
      print('Error creating Google credential: $e');
      rethrow;
    }
  }

  // GitHub Authentication
  static Future<OAuthCredential?> _createGithubCredential() async {
    return null;
  }

  //Other Authentication



  
}