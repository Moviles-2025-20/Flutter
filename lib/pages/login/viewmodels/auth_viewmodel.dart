import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:app_flutter/util/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

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
      } else {
        _user = null;
        _isFirstTimeUser = false;
      }

      notifyListeners();
    });
  }

  //Check first time user
  Future<void> _checkFirstTimeUser() async {
    if (_user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'user_${_user!.uid}_has_logged_in';
    
    // Check if user has logged in before
    _isFirstTimeUser = !prefs.containsKey(key);
    
    if (_isFirstTimeUser) {
      // Mark user as having logged in
      await prefs.setBool(key, true);
    }
  }

  // Login methods
  Future<void> loginWithGoogle() async {
    await _login(AuthProviderType.google);
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
      _error = null;
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manual method to mark user as returning (optional)
  Future<void> markAsReturningUser() async {
    if (_user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'user_${_user!.uid}_has_logged_in';
    await prefs.setBool(key, true);
    _isFirstTimeUser = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}