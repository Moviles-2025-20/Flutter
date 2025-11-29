import 'dart:async';
import 'dart:io';

import 'package:app_flutter/pages/login/models/auth_models.dart';
import 'package:app_flutter/pages/login/viewmodels/register_viewmodel.dart';
import 'package:app_flutter/util/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../util/local_DB_service.dart';
import '../../../util/quizConstant.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';


class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _db = FirebaseService.firestore;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isFirstTimeUser = false;
  bool _isCheckingInternet = false;
  Timer? _authTimeoutTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isWaitingForAuth = false;
  bool _shouldStopWaiting = false;

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
  bool get isCheckingInternet => _isCheckingInternet;


  // Verificar si hay conexión real a internet
  Future<bool> hasInternetConnection() async {
    try {
      // Conectividad básica
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Verificar conexión real
      final results = await Future.wait([
        InternetAddress.lookup('google.com')
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );

      return results.any((result) => result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } catch (e) {
      print('Error verificando conexión a internet: $e');
      return false;
    }
  }

  // Monitorear conexión mientras espera autenticación del navegador
  void _startAuthConnectivityMonitor() {
    _connectivitySubscription?.cancel();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (_isWaitingForAuth && result == ConnectivityResult.none) {
        print("Conexión perdida durante autenticación en navegador");
        
        // Esperar 1 minuto para ver si recupera
        await Future.delayed(const Duration(seconds: 5));
        
        if (!await hasInternetConnection()) {
          print("Sin internet después de espera inicial, iniciando espera de 1 minuto...");
          _isCheckingInternet = true;
          notifyListeners();
          
          bool recovered = await _waitForConnection(const Duration(minutes: 1));
          print("Tiempo esperado");
          
          if (!recovered) {
            print("No se recuperó internet en 1 minuto, cancelando autenticación");
            _cancelAuthProcess();
          } else {
            print("Internet recuperado, continuando...");
            _isCheckingInternet = false;
            notifyListeners();
          }
        }
      }
    });
  }

  // Esperar conexión con verificaciones periódicas
  Future<bool> _waitForConnection(Duration timeout) async {
    final endTime = DateTime.now().add(timeout);
    int attempts = 0;
    
    while (attempts < 12) {
      attempts++;
      print("Intento $attempts de verificar internet...");
      
      if (await hasInternetConnection()) {
        print("Internet recuperado en intento $attempts");
        return true;
      }
      
      // Esperar 5 segundos antes de verificar nuevamente
      await Future.delayed(const Duration(seconds: 5));
    }
    print("Completo los 12");
    return false;
  }

  // Cancelar proceso de autenticación
  void _cancelAuthProcess() {
    _isWaitingForAuth = false;
    _isLoading = false;
    _isCheckingInternet = false;
    _authTimeoutTimer?.cancel();
    _connectivitySubscription?.cancel();
    _error = "Login canceled: No internet connection available. Please check your connection and try again.";
    notifyListeners();
  }




  // Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((firebaseUser) async{
      if (firebaseUser != null) {
        final providerId = firebaseUser.providerData.isNotEmpty
            ? firebaseUser.providerData.first.providerId
            : 'unknown';
        _user = UserModel.fromFirebase(firebaseUser, providerId);
        await QuizStorageManager.syncPendingQuizToFirebase(_user!.uid);

        final registerVM = RegisterViewModel(authViewModel: this);
        final localUserService = LocalUserService();
        final profileVM = ProfileViewModel();
        await localUserService.debugPrintUsers();
        await profileVM.syncUserPhotoIfNeeded(_user!.uid);
        await registerVM.syncPendingUsers();
        await isFirstTimeUser;

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
        if (await hasInternetConnection()) {
          print(" Intentando sincronizar datos del usuario: ${_user!.uid}");
          final registerVM = RegisterViewModel(authViewModel: this);
          final localUserService = LocalUserService();
          final profileVM = ProfileViewModel();
          await localUserService.debugPrintUsers();
          await profileVM.syncUserPhotoIfNeeded(_user!.uid);
          await registerVM.syncPendingUsers();
          await QuizStorageManager.syncPendingQuizToFirebase(_user!.uid);


        }
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


  // Private login method
  Future<void> _login(AuthProviderType type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Verificar internet ANTES de iniciar sesión
      print("Verificando conexión a internet...");
      bool hasInternet = await hasInternetConnection();
      
      if (!hasInternet) {
        _error = "No internet connection detected. Please check your connection and try again.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      print("Conexión a internet verificada. Iniciando sesión...");
      _isWaitingForAuth = true;
      _startAuthConnectivityMonitor();

      // Timeout de 5 minutos para todo el proceso
      _authTimeoutTimer = Timer(const Duration(minutes: 5), () {
        if (_isWaitingForAuth) {
          _cancelAuthProcess();
          _error = "Login timeout. Please try again.";
          notifyListeners();
        }
      });

      // Intentar login 
      final userCredential = await _authService.loginWithProvider(type).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException("Authentication timeout");
        },
      );

      // Si llegamos aquí, el login fue exitoso
      _isWaitingForAuth = false;
      _authTimeoutTimer?.cancel();
      _connectivitySubscription?.cancel();


      //Durante el login, verificar si perdió internet
      hasInternet = await hasInternetConnection();
      
      if (!hasInternet) {
        print("Conexión perdida durante el login. Esperando 1 minuto...");
        _error = "Connection lost. Waiting for internet connection...";
        notifyListeners();
        
        // Esperar hasta 1 minuto por internet
        bool recovered = await _waitForConnection(const Duration(minutes: 1));
        
        if (!recovered) {
          _error = "No internet connection. Login cannot be completed. Please try again when you have a stable connection.";
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        print("Conexión recuperada. Continuando con el login...");
        _error = null;
        notifyListeners();
      }

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
    } on TimeoutException catch (e) {
      print("Timeout en autenticación: $e");
      _error = "Login timeout. Please check your connection and try again.";
      _user = null;
    } catch (e) {
      print("Error at login $e");

      // Verificar si el error es por falta de internet
      bool hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        _error = "No internet connection. Login cannot be completed.";
      } else {
        _error = "Oops! Something went wrong while signing in. Try again.";
      }

      _user = null;
    } finally {
      _isWaitingForAuth = false;
      _isLoading = false;
      _isCheckingInternet = false;
      _authTimeoutTimer?.cancel();
      _connectivitySubscription?.cancel();
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      // Limpiar estado del perfil
      final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
      profileVM.clearUserData();
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