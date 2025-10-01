import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String providerId;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.providerId,
  });

  factory UserModel.fromFirebase(User firebaseUser, String providerId) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      providerId: providerId,
    );
  }
}

enum AuthProviderType {
  google,
  github,
  //Other
}