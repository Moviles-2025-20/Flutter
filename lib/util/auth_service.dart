import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      //For Facebook
      if (type == AuthProviderType.facebook) {
        final credential = await AuthProviderFactory.createCredential(type);
        if (credential == null) {
          throw Exception('Facebook sign-in cancelled');
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
    final user = _auth.currentUser;

    if (user != null) {
      // Verificar proveedores
      final isGoogleUser = user.providerData
          .any((info) => info.providerId == 'google.com');
      final isFacebookUser = user.providerData
          .any((info) => info.providerId == 'facebook.com');

      // Cerrar sesión de proveedores
      if (isGoogleUser) {
        try {
          await GoogleSignIn().disconnect();
        } catch (e) {
          print('Error en disconnect, intentando signOut: $e');
          await GoogleSignIn().signOut();
        }
      }

      if (isFacebookUser) {
        try {
          await FacebookAuth.instance.logOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('fb_access_token');

          print('Facebook logout exitoso');
        } catch (e) {
          print('Error logout Facebook: $e');
        }
      }

      // AGREGAR DEMAS ------------------------------------------------------------------------
    }
  

    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}