import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:app_flutter/util/auth_service.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthViewModel({required AuthService authService})
      : _authService = authService {
    _initAuthListener();
  }

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        final providerId = firebaseUser.providerData.isNotEmpty
            ? firebaseUser.providerData.first.providerId
            : 'unknown';
        _user = UserModel.fromFirebase(firebaseUser, providerId);
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  // Login methods
  Future<void> loginWithGoogle() async {
    await _login(AuthProviderType.google);
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

  @override
  void dispose() {
    super.dispose();
  }
}