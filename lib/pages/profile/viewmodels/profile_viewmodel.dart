import 'dart:async';
import 'package:crypto/crypto.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../util/firebase_service.dart';
import '../../../util/local_DB_service.dart';
import '../../../util/quizConstant.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileViewModel extends ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final localUserService = LocalUserService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  List<String> _quizCategories = [];

  List<String> get quizCategories => _quizCategories;


  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Cargar datos del usuario actual
  Future<void> loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = "No user authenticated";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.any([
        _loadUserDataInternal(user.uid),
        Future.delayed(const Duration(seconds: 5), () {
          throw TimeoutException("Timeout al cargar datos del usuario");
        }),
      ]);
      await loadQuizCategories();

    } catch (e) {
      _error = "There is no network or local data save for this user";
      debugPrint("Error loading user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserDataInternal(String uid) async{

    // 1. load cache
    String? cachedPhotoPath;
    final appDir = await getApplicationDocumentsDirectory();
    final cachedImage = File('${appDir.path}/profile_$uid.jpg');
    if (await cachedImage.exists()) {
      cachedPhotoPath = cachedImage.path;
      debugPrint("Imagen cacheada encontrada: $cachedPhotoPath");
    }



    // 2. Intentar cargar desde SQLite
    final localUsers = await localUserService.getUsers();
    final localUser = localUsers.firstWhere(
          (u) => u['id'] == uid,
      orElse: () => {},
    );

    if (localUser.isNotEmpty) {
      debugPrint("Cargando desde SQLite");
      final userFromLocal = UserModel(
        uid: localUser['id'],
        profile: Profile(
          name: localUser['name'],
          email: localUser['email'],
          city: localUser['city'],
          gender: localUser['gender'],
          age: localUser['age'] ?? 0,
          major: localUser['major'],
          photo: cachedPhotoPath ?? localUser['photo'],
          created: localUser['createdAt'] != null
              ? DateTime.parse(localUser['createdAt'])
              : null,
          lastActive: null, // SQLite no guarda esto
        ),
        preferences: Preferences(
          favoriteCategories: (localUser['favoriteCategories'] as String)
              .split(',')
              .where((e) => e.isNotEmpty)
              .toList(),
          indoorOutdoorScore: localUser['indoorOutdoorScore'] ?? 0,
          freeTimeSlots: (localUser['freeTimeSlots'] as String)
              .split(',')
              .map((s) {
            final parts = s.split('-');
            if (parts.length == 3) {
              return FreeTimeSlot(
                day: parts[0],
                start: parts[1],
                end: parts[2],
              );
            } else {
              return FreeTimeSlot(day: '', start: '', end: '');
            }
          })
              .toList(),

        ),
        stats: null, // Not save in sqlite
      );

      _currentUser = userFromLocal;
      notifyListeners(); // show local
    }

    // 3. check network
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;
    if (!hasInternet) {
      debugPrint("Sin conexión. Usando solo cache + local.");

      if (_currentUser == null) {
        _error = "No connection and no local data for this user.";
        notifyListeners();
      }

      return;
    }

    // 4. load from Firestore
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists && doc.data() != null) {
      debugPrint("Cargando desde Firebase");

      _currentUser = UserModel.fromFirestore(uid, doc.data()!);

      // Actualizar last_active
      await _updateLastActive(uid);
    } else {
      _error = "User not found";
    }
  }

  /// Actualizar last_active del usuario
  Future<void> _updateLastActive(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profile.last_active': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating last_active: $e");
    }
  }

  /// Actualizar nombre del usuario
  Future<void> updateName(String newName) async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;
    final localUsers = await localUserService.getUsers();
    final isLocalUser = localUsers.any((u) => u['id'] == _currentUser?.uid);


      if (!hasInternet && !isLocalUser) {
        _error = "There is no connection and the user has no local data. No changes can be made.";
        notifyListeners();
        throw StateError(_error!); // Corta TODO el flujo, incluidos microtasks futuros

      }



    _currentUser = _currentUser!.copyWith(
      profile: _currentUser!.profile.copyWith(name: newName),
    );
    notifyListeners();

    // 2. Guardar y sincronizar en segundo plano
    Future.microtask(() async {
      await localUserService.updateUser(_currentUser!.uid, {
        "name": newName,
        "synced": 0,
      });

      if (hasInternet)  {
        try {
          await _firestore.collection('users').doc(_currentUser!.uid).update({
            'profile.name': newName,
          });
          await localUserService.updateUser(_currentUser!.uid, {"synced": 1});
        } catch (e) {
          _error = "Error al sincronizar nombre: $e";
          debugPrint("Error syncing name: $e");
        }
      }
    });
  }

  Future<void> updateMajor(String major) async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;
    final localUsers = await localUserService.getUsers();
    final isLocalUser = localUsers.any((u) => u['id'] == _currentUser?.uid);

    if (!hasInternet && !isLocalUser) {
      _error = "There is no connection and the user has no local data. No changes can be made.";
      notifyListeners();
      throw StateError(_error!); // Corta TODO el flujo, incluidos microtasks futuros

    }

    _currentUser = _currentUser!.copyWith(
      profile: _currentUser!.profile.copyWith(major: major),
    );
    notifyListeners();
    Future.microtask(() async {
    await localUserService.updateUser(_currentUser!.uid, {
      "major": major,
      "synced": 0,
    });

    if (hasInternet)  {

    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'profile.major': major,
      });

      await localUserService.updateUser(_currentUser!.uid, {"synced": 1});
    } catch (e) {
      _error = "Error al actualizar major: $e";
      debugPrint("Error updating major: $e");
    }
    }
    });
  }

  Future<void> updatePhotoInstantly(String localPath) async {
    if (_currentUser == null) return;

    final uid = _currentUser!.uid;

    // 1. Guardar en SharedPreferences localmente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo_$uid', localPath);
    debugPrint("!!!!!!! SharedPreferences: guardado localPath = $localPath para uid = $uid");

    // 2. Mostrar la foto inmediatamente en la UI
    _currentUser = _currentUser!.copyWith(
      profile: _currentUser!.profile.copyWith(photo: localPath),
    );
    notifyListeners();

    // Lanzar sincronización en segundo plano (Future con handler)
    syncPhotoInBackground(uid, localPath)
        .then((downloadUrl) async {


      if (downloadUrl != null) {
        await prefs.setString('profile_photo_$uid', downloadUrl);
        debugPrint("SharedPreferences: guardado downloadUrl = $downloadUrl para uid = $uid");
        final savedPhoto = prefs.getString('profile_photo_$uid');
        if (savedPhoto == downloadUrl) {
          debugPrint("✅ SharedPreferences verificada: la URL se guardó correctamente.");
        } else {
          debugPrint("⚠️ SharedPreferences no coincide. Guardado: $savedPhoto, esperado: $downloadUrl");
        }
      }
    }).catchError((e) {
      debugPrint("Error en la sincronización de foto: $e");
    });
  }


  Future<String?> syncPhotoInBackground(String uid, String localPath) async {
    String? downloadUrl;


    // Verificar si el usuario existe en SQLite
    final userExists = await localUserService.userExists(uid);
    debugPrint(" SQLite: ¿usuario existe localmente? $userExists");

    if (userExists) {
      await localUserService.updateUser(uid, {
        "photo": localPath,
        "synced": 0,
      });
      debugPrint(" SQLite: guardado localPath = $localPath con synced = 0 para uid = $uid");

    }

    final connectivity = await Connectivity().checkConnectivity();
    debugPrint(" Conectividad: ${connectivity.toString()}");
    if (connectivity != ConnectivityResult.none) {
      try {
        File file = File(localPath);
        final ref = FirebaseStorage.instance
            .ref()
            .child('users/${_currentUser!.uid}/profile.jpg');
        await ref.putFile(file);

        // Obtener URL de descarga
        downloadUrl = await ref.getDownloadURL();
        debugPrint(" Firebase Storage: URL pública obtenida = $downloadUrl");

        await _firestore.collection('users').doc(uid).update({
          'profile.photo': downloadUrl,
        });
        debugPrint(" Firestore: actualizado profile.photo con URL = $downloadUrl para uid = $uid");

        if (userExists) {
          await localUserService.updateUser(uid, {
            "photo": downloadUrl,
            "synced": 1,
          });
        }
      } catch (e) {
        debugPrint("Error al sincronizar con Firebase: $e");
      }
    }return downloadUrl;
  }

  Future<void> syncUserPhotoIfNeeded(String uid) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        debugPrint("Sin conexión. No se puede sincronizar fotos.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // 1 Intentar obtener el usuario de la base de datos local
      final user = await localUserService.getUser(uid);
      final userExists = await localUserService.userExists(uid);
      bool needsSync = true;
      String? localPath;

      if (userExists) {
        // Usuario existe en la base local
        final syncedFlag = user?['synced'] ?? 1;
        localPath = user?['photo'];
        if (syncedFlag ==0 ){needsSync = true;}
        if(syncedFlag == 1){needsSync = false;}
      }
      else {
        // No está en base local → usar SharedPreferences
        localPath = prefs.getString('profile_photo_$uid');
        debugPrint(" Usuario $uid sin base local, se usa SharedPreference.");
      }

      // Si no hay foto local, no se puede sincronizar
      if (localPath == null || localPath.isEmpty) {
        debugPrint("No hay foto local para $uid.");
        return;
      }

      // Verificar que el archivo exista localmente
      if (!File(localPath).existsSync()) {
        debugPrint("⚠️ Archivo local no existe: $localPath");
        return;
      }

      // 2 Obtener la foto actual desde Firebase
      final firebaseDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      final firebasePhotoUrl = firebaseDoc.data()?['profile']?['photo'];

      // 3 Comparar las imágenes
      bool shouldUpload = false;

        final isSame = await _arePhotosSame(firebasePhotoUrl, localPath);
        if (!isSame) {
          debugPrint("Foto diferente detectada. Se subirá la local.");
          shouldUpload = true;
        } else {
          return;
        }


      // Subir y actualizar si hace falta
      if (shouldUpload || needsSync) {
        debugPrint("Subiendo foto de $uid a Firebase...");

        final file = File(localPath);
        final ref = FirebaseStorage.instance
            .ref()
            .child('users/$uid/profile.jpg');

        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        // Actualizar Firebase
        await _firestore.collection('users').doc(uid).update({
          'profile.photo': downloadUrl,
        });

        // Actualizar base de datos local (si existe)

        if (userExists) {
          await localUserService.updateUser(uid, {
            "photo": downloadUrl,
            "synced": 1,
          });
        }

        // Actualizar SharedPreferences
        await prefs.setString('profile_photo_$uid', downloadUrl);

        debugPrint("✅ Foto sincronizada correctamente para $uid.");
      }
    } catch (e) {
      debugPrint("❌ Error en sincronización de foto ($uid): $e");
    }
  }


  Future<bool> _arePhotosSame(String firebasePhotoUrl, String localPath) async {
    try {
      final fileBytes = await File(localPath).readAsBytes();
      final localHash = md5.convert(fileBytes).toString();

      final request = await HttpClient().getUrl(Uri.parse(firebasePhotoUrl));
      final response = await request.close();
      final remoteBytes = await response.fold<List<int>>([], (prev, element) => prev..addAll(element));
      final remoteHash = md5.convert(remoteBytes).toString();

      return localHash == remoteHash;
    } catch (e) {
      debugPrint("⚠️ Error comparando imágenes: $e");
      return false;
    }
  }





  /// Agregar categoría favorita
  Future<void> addFavoriteCategory(String category) async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;
    final localUsers = await localUserService.getUsers();
    final isLocalUser = localUsers.any((u) => u['id'] == _currentUser?.uid);

    if (!hasInternet && !isLocalUser) {
      _error = "There is no connection and the user has no local data. No changes can be made.";
      notifyListeners();
      throw StateError(_error!); // Corta TODO el flujo, incluidos microtasks futuros

    }
    // 1. Crear la nueva lista actualizada
    final updatedList = [
      ..._currentUser!.preferences.favoriteCategories,
      category,
    ];

    // 2. Actualizar el modelo en memoria
    _currentUser = _currentUser!.copyWith(
      preferences: _currentUser!.preferences.copyWith(
        favoriteCategories: updatedList,
      ),
    );
    notifyListeners();

    // 2. Guardar y sincronizar en segundo plano
    Future.microtask(() async {
      await localUserService.updateUser(_currentUser!.uid, {
        "favoriteCategories": updatedList.join(','),
        "synced": 0,
      });

      if (hasInternet) {
        try {
          await _firestore.collection('users').doc(_currentUser!.uid).update({
            'preferences.favorite_categories': FieldValue.arrayUnion([category]),
          });
          await localUserService.updateUser(_currentUser!.uid, {"synced": 1});
        } catch (e) {
          _error = "Error al agregar categoría: $e";
          debugPrint("Error adding category: $e");
        }
      }
    });
  }

  /// Eliminar categoría favorita
  Future<void> removeFavoriteCategory(String category) async {

    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;

// Verificar si el usuario actual tiene respaldo local
    final localUsers = await localUserService.getUsers();
    final isLocalUser = localUsers.any((u) => u['id'] == _currentUser?.uid);

    if (!hasInternet && !isLocalUser) {
      _error = "There is no connection and the user has no local data. No changes can be made.";
      notifyListeners();
      throw StateError(_error!); // Corta TODO el flujo, incluidos microtasks futuros

    }
    final updatedList = _currentUser!.preferences.favoriteCategories
        .where((c) => c != category)
        .toList();

    _currentUser = _currentUser!.copyWith(
      preferences: _currentUser!.preferences.copyWith(
        favoriteCategories: updatedList,
      ),
    );
    notifyListeners();

    // 2. Guardar y sincronizar en segundo plano
    Future.microtask(() async {
      await localUserService.updateUser(_currentUser!.uid, {
        "favoriteCategories": updatedList.join(','),
        "synced": 0,
      });

      if (hasInternet)  {
        try {
          await _firestore.collection('users').doc(_currentUser!.uid).update({
            'preferences.favorite_categories': FieldValue.arrayRemove([category]),
          });
          await localUserService.updateUser(_currentUser!.uid, {"synced": 1});
        } catch (e) {
          _error = "Error al eliminar categoría: $e";
          debugPrint("Error removing category: $e");
        }
      }
    });
  }

  Future<bool> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Eliminar documento de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Eliminar usuario de Authentication
      await user.delete();

      //  Eliminar usuario de la base local
      await localUserService.deleteUser(user.uid);
      debugPrint("user eliminado local");

      // Eliminar imagen cacheada
      final appDir = await getApplicationDocumentsDirectory();
      final imageFile = File('${appDir.path}/profile_${user.uid}.jpg');
      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint("Imagen cacheada eliminada");
      }

      _currentUser = null;
      return true;
    } catch (e) {
      _error = "Error al eliminar cuenta: $e";
      debugPrint("Error deleting account: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  String getPersonalityType() {
    if (_currentUser == null) return "Unknown";

    final categories = _currentUser!.preferences.favoriteCategories;

    if (categories.contains("Sports") || categories.contains("Outdoor")) {
      return "Extroverted";
    } else if (categories.contains("Literature") || categories.contains("Academic")) {
      return "Introverted";
    } else {
      return "Ambivert";
    }
  }

  Future<void> loadQuizCategories() async {
    if (_currentUser == null) return;

    _quizCategories =
    await QuizStorageManager.getCategories(_currentUser!.uid);

    notifyListeners();
  }


  Future<void> refreshQuizResult(String userId) async {
  final result = await QuizStorageManager.getLatestResult(userId);

  if (result == null) return;

  _quizCategories = result.resultCategories;
  notifyListeners();
  }





  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearUserData() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

}