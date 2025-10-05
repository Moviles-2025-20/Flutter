import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



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
    try {
      
      final clientId = "Ov23liDy80ePqIOMxaDd";
      final clientSecret = "ac30ba61ce22ef0bff0fc73b0995c2fe624dd971"; 
      final redirectUri = "parchandes://auth/callback";

      final result = await FlutterWebAuth2.authenticate(
        url: "https://github.com/login/oauth/authorize"
            "?client_id=$clientId"
            "&redirect_uri=$redirectUri"
            "&scope=read:user,user:email",
        callbackUrlScheme: "parchandes",
      );

      
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      
      final tokenResponse = await http.post(
        Uri.parse("https://github.com/login/oauth/access_token"),
        headers: {
          "Accept": "application/json",
        },
        body: {
          "client_id": clientId,
          "client_secret": clientSecret,
          "code": code,
          "redirect_uri": redirectUri,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception("Error obteniendo access_token: ${tokenResponse.body}");
      }

      final body = jsonDecode(tokenResponse.body);
      final accessToken = body["access_token"];

      if (accessToken == null) {
        throw Exception("GitHub no devolvió access_token");
      }


      final credential = GithubAuthProvider.credential(accessToken);
      return credential;

    } catch (e) {
      print("Error creando credenciales GitHub: $e");
      rethrow;
    }
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