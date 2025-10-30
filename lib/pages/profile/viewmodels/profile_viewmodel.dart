import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../../../util/firebase_service.dart';
import '../../../util/local_DB_service.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final localUserService = LocalUserService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

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
      final uid = user.uid;

      // 1. load cache
      String? cachedPhotoPath;
      final appDir = await getApplicationDocumentsDirectory();
      final cachedImage = File('${appDir.path}/profile_$uid.jpg');
      if (await cachedImage.exists()) {
        cachedPhotoPath = cachedImage.path;
        debugPrint("Imagen cacheada encontrada: $cachedPhotoPath");
      }

      // 2. Intentar cargar nombre desde Firebase Auth (si lo guardaste ahí)
      //final displayName = user.displayName;

      // 3. Intentar cargar desde SQLite
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

      // 4. check network
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = connectivity != ConnectivityResult.none;
      if (!hasInternet) {
        debugPrint("Sin conexión. Usando solo cache + local.");
        return;
      }

      // 5. load from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        debugPrint("Cargando desde Firebase");

        _currentUser = UserModel.fromFirestore(user.uid, doc.data()!);

        // Actualizar last_active
        await _updateLastActive(user.uid);
      } else {
        _error = "User not found";
      }
    } catch (e) {
      _error = "Error loading data: $e";
      debugPrint("Error loading user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
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
    if (_currentUser == null) return;

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

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
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
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      profile: _currentUser!.profile.copyWith(major: major),
    );
    notifyListeners();
    Future.microtask(() async {
    await localUserService.updateUser(_currentUser!.uid, {
      "major": major,
      "synced": 0,
    });

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {

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


  /// Actualizar foto de perfil
  Future<void> updatePhoto(String localPath) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Subir archivo a Firebase Storage
      File file = File(localPath);
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${_currentUser!.uid}/profile.jpg');
      await ref.putFile(file);

      // Obtener URL de descarga
      String downloadUrl = await ref.getDownloadURL();

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'profile.photo': downloadUrl,
      });

      await loadUserData(); // Recargar datos
    } catch (e) {
      _error = "Error al actualizar foto: $e";
      debugPrint("Error updating photo: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agregar categoría favorita
  Future<void> addFavoriteCategory(String category) async {
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

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
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

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
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

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}