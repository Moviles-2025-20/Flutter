import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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
      case AuthProviderType.facebook:
        return await _createFacebookCredential();
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

  //facebook Authentication
  //static Future<OAuthCredential?> _createFacebookCredential() async {
    //final LoginResult result = await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);
    //if (result.status == LoginStatus.success) {
      //final AccessToken accessToken = result.accessToken!;
      //return FacebookAuthProvider.credential(accessToken.tokenString);
    //} else {
      //throw Exception('Facebook login cancelled or failed: ${result.message}');
    //}
  //}
  static Future<OAuthCredential?> _createFacebookCredential() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile'],
      );
      if (result.status == LoginStatus.success) {
        final AccessToken? accessToken = result.accessToken;
        if (accessToken == null) {
          throw Exception('Facebook access token is null');
        }
        final credential = FacebookAuthProvider.credential(accessToken.tokenString);
        return credential;
      }
      else {
        throw Exception(
            'Facebook login failed: ${result.status} - ${result.message}'
        );
      }
    } catch (e) {
      print('Error creating Google credential: $e');
      rethrow;
    }
  }


  
}