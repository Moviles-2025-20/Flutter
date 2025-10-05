import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../util/firebase_service.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
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

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'profile.name': newName,
      });

      // Actualizar el modelo local
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        profile: Profile(
          name: newName,
          email: _currentUser!.profile.email,
          city: _currentUser!.profile.city,
          gender: _currentUser!.profile.gender,
          age: _currentUser!.profile.age,
          major: _currentUser!.profile.major,
          photo: _currentUser!.profile.photo,
          created: _currentUser!.profile.created,
          lastActive: _currentUser!.profile.lastActive,
        ),
        preferences: _currentUser!.preferences,
        stats: _currentUser!.stats,
      );
    } catch (e) {
      _error = "Error al actualizar nombre: $e";
      debugPrint("Error updating name: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMajor(String major) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'profile.major': major,
      });

      _currentUser = UserModel(
        uid: _currentUser!.uid,
        profile: Profile(
          name: _currentUser!.profile.name,
          email: _currentUser!.profile.email,
          city: _currentUser!.profile.city,
          gender: _currentUser!.profile.gender,
          age: _currentUser!.profile.age,
          major: major,
          photo: _currentUser!.profile.photo,
          created: _currentUser!.profile.created,
          lastActive: _currentUser!.profile.lastActive,
        ),
        preferences: _currentUser!.preferences,
        stats: _currentUser!.stats,
      );
    } catch (e) {
      _error = "Error al actualizar major: $e";
      debugPrint("Error updating major: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    if (_currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'preferences.favorite_categories': FieldValue.arrayUnion([category]),
      });

      await loadUserData(); // Recargar datos
    } catch (e) {
      _error = "Error al agregar categoría: $e";
      debugPrint("Error adding category: $e");
    }
  }

  /// Eliminar categoría favorita
  Future<void> removeFavoriteCategory(String category) async {
    if (_currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'preferences.favorite_categories': FieldValue.arrayRemove([category]),
      });

      await loadUserData(); // Recargar datos
    } catch (e) {
      _error = "Error al eliminar categoría: $e";
      debugPrint("Error removing category: $e");
    }
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