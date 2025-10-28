import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:app_flutter/pages/login/viewmodels/register_viewmodel.dart';
import 'package:app_flutter/util/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../util/local_DB_service.dart';


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
        final registerVM = RegisterViewModel(authViewModel: this);
        final localUserService = LocalUserService();
        await localUserService.debugPrintUsers();
        await registerVM.syncPendingUsers();
        await _checkFirstTimeUser();
        _startConnectivityListener();
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        _user = null;
        _isFirstTimeUser = false;
      }

      notifyListeners();
    });
  }


  void _startConnectivityListener() {
    
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      print("Cambio de conectividad detectado: $result");
      if (result != ConnectivityResult.none && _user != null) {
        print(" Intentando sincronizar datos del usuario: ${_user!.uid}");
        final registerVM = RegisterViewModel(authViewModel: this);
        final localUserService = LocalUserService();
        await localUserService.debugPrintUsers();
        await registerVM.syncPendingUsers();
      }
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

      //  Guardar imagen en caché
      final photoUrl = _user?.photoURL;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        final file = await DefaultCacheManager().getSingleFile(photoUrl);
        debugPrint('cache');

        //  Copiar a directorio persistente
        final appDir = await getApplicationDocumentsDirectory();
        final savedImage = await file.copy('${appDir.path}/profile_${_user!.uid}.jpg');
        debugPrint('imagen guardad');

        //  Guardar ruta local en memoria
        _user = UserModel(
          uid: _user!.uid,
          email: _user!.email,
          displayName: _user!.displayName,
          photoURL: savedImage.path, // ahora es ruta local
          providerId: _user!.providerId,
        );
        debugPrint('FINISH');
      }

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