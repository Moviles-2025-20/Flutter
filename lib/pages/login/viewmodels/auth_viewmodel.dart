import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:app_flutter/util/auth_service.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _db = FirebaseService.firestore;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isFirstTimeUser = false;

  AuthViewModel({required AuthService authService})
      : _authService = authService {
    _initAuthListener();
  }

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isFirstTimeUser => _isFirstTimeUser;

  // Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((firebaseUser) async{
      if (firebaseUser != null) {
        final providerId = firebaseUser.providerData.isNotEmpty
            ? firebaseUser.providerData.first.providerId
            : 'unknown';
        _user = UserModel.fromFirebase(firebaseUser, providerId);
        await _checkFirstTimeUser();
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        _user = null;
        _isFirstTimeUser = false;
      }

      notifyListeners();
    });
  }




  //Check first time user usando Firestore
  Future<void> _checkFirstTimeUser() async {
    if (_user == null) return;

    final doc = await _db
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (!doc.exists || !doc.data()!.containsKey('profile')) {
      _isFirstTimeUser = true;
    } else {
      _isFirstTimeUser = false;
    }
  }

  // Login methods
  Future<void> loginWithGoogle() async {
    try{
      await _login(AuthProviderType.google);
    }catch(e){
      print("Error al iniciar sesion con Google: ");
    }
  }

  // Add login with GitHub
  Future<void> loginWithGithub() async {
    await _login(AuthProviderType.github);
  }

  Future<void> loginWithFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      await _login(AuthProviderType.facebook);

    } catch (e) {
      print('Error en loginWithFacebook: $e');
    }
  }

  //Agregar los que Faltan---------------------------------------------------------------------



  // Private login method
  Future<void> _login(AuthProviderType type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.loginWithProvider(type);
      final providerId = userCredential.credential?.providerId ?? type.name;
      
      _user = UserModel.fromFirebase(userCredential.user!, providerId);
      await _checkFirstTimeUser();
      _error = null;
    } catch (e) {
      print("Error at login $e");

      _error = ("Oops! Something went wrong while signing in. Try again.");
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
    } catch (e) {
      print("Error in the logout: $e");
      _error = "There was a problem during the logout.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markUserAsNotFirstTime() {
    _isFirstTimeUser = false;
    notifyListeners();
  }




  @override
  void dispose() {
    super.dispose();
  }
}