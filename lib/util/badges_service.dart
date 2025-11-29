import 'dart:convert';
import 'dart:io';

import 'package:app_flutter/pages/badges/model/badge.dart';
import 'package:app_flutter/pages/badges/model/user_badge.dart';
import 'package:app_flutter/util/badges_cache.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:app_flutter/util/local_DB_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============= ABSTRACT REPOSITORY =============

abstract class IBadgeRepository {
  Future<List<Badge_Medal>> getAllBadges();
  Future<List<UserBadge>> getUserBadges(String userId);
  Future<UserBadge?> getUserBadgeProgress(String userId, String badgeId);
  Future<void> updateUserBadge(UserBadge userBadge);
  Future<void> createUserBadge(UserBadge userBadge);
  Future<List<UserBadge>> getUnlockedBadges(String userId);
  Future<void> syncOfflineBadges(String userId);
}



// ============= FIRESTORE IMPLEMENTATION =============

class BadgeRepository implements IBadgeRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final LocalUserService _localService = LocalUserService(); 
   final _fileStorage = UserBadgeFileStorage();

  static const String _badgesCollection = 'badges';
  static const String _userBadgesCollection = 'user_badges';
  final _memoryCache = UserBadgesLruCache(capacity: 6);


  @override
  Future<List<Badge_Medal>> getAllBadges() async {
    try {

      try {
        // Intenta leer del caché interno de Firebase primero
        final snapshot = await _firestore
            .collection('badges_definitions')
            .get(const GetOptions(source: Source.cache)); //Con source se indica que cache
        if (snapshot.docs.isNotEmpty) {
          debugPrint("Firebase Cache HIT: Retornando catálogo local");
          return snapshot.docs.map((d) => Badge_Medal.fromMap(d.data())).toList();
        }
      } catch (e) {
        // Si falla (cache vacío), ignoramos y vamos a local storage
      }

      final localBadges = await _localService.getAllBadges();
      
      if (localBadges.isNotEmpty) {
        debugPrint("Se usaron las Badges de local Storage");
        return localBadges;
      }

      final snapshot = await _firestore
          .collection(_badgesCollection)
          .get();

      final remoteBadges = snapshot.docs
          .map((doc) => Badge_Medal.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      await _localService.insertBadges(remoteBadges);
      return remoteBadges;

    } catch (e) {
      throw Exception('Error al cargar medallas: $e');
    }
  }


  @override
  Future<List<UserBadge>> getUserBadges(String userId) async {
    try {

      final cachedBadges = _memoryCache.get(userId);
      if (cachedBadges != null) {
        debugPrint("Cache HIT (RAM): Retornando badges desde memoria");
        return cachedBadges;
      }
      debugPrint("Cache MISS (RAM): Buscando en disco...");


      final localUserBadges = await _fileStorage.getUserBadges();
      if (localUserBadges.isNotEmpty) {
        debugPrint("Disk HIT: Retornando badges desde archivo local");
        
        // IMPORTANTE: Subir a cache para la próxima
        _memoryCache.put(userId, localUserBadges);
        
        return localUserBadges;
      }


      debugPrint("Disk MISS: Descargando de Firebase...");
      final snapshot = await _firestore
          .collection(_userBadgesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final remoteBadges = snapshot.docs
          .map((doc) => UserBadge.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      // Si encontramos datos, guardamos en TODAS las capas de caché
      if (remoteBadges.isNotEmpty) {
        await _fileStorage.saveUserBadges(remoteBadges); 
        _memoryCache.put(userId, remoteBadges);         
      }
      return remoteBadges;
    } catch (e) {
      debugPrint('Error al cargar medallas del usuario: $e');
      // En caso de error, retornamos lista vacía para no romper la UI
      return [];
    }
  }

  @override
  Future<UserBadge?> getUserBadgeProgress(
    String userId,
    String badgeId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_userBadgesCollection)
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return UserBadge.fromMap({
        ...snapshot.docs.first.data(),
        'id': snapshot.docs.first.id,
      });
    } catch (e) {
      throw Exception('Error al obtener progreso: $e');
    }
  }

  @override
  Future<List<UserBadge>> getUnlockedBadges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_userBadgesCollection)
          .where('userId', isEqualTo: userId)
          .where('isUnlocked', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserBadge.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar medallas desbloqueadas: $e');
    }
  }

  // ========== USER BADGES (ESCRITURA) ==========

  @override
  Future<void> updateUserBadge(UserBadge userBadge) async {
    try {
      final data = userBadge.toMap();
      data['synced'] = 1; // Marcar como sincronizado

      await _firestore
          .collection(_userBadgesCollection)
          .doc(userBadge.id)
          .set(data, SetOptions(merge: true));

    } catch (e) {
      throw Exception('Error al actualizar medalla: $e');
    }
  }

  @override
  Future<void> createUserBadge(UserBadge userBadge) async {
    try {
      final data = userBadge.toMap();

      await _firestore
          .collection(_userBadgesCollection)
          .doc(userBadge.id)
          .set(data);
    } catch (e) {
      throw Exception('Error al crear medalla de usuario: $e');
    }
  }

  // ========== SINCRONIZACIÓN OFFLINE ==========

  @override
  Future<void> syncOfflineBadges(String userId) async {
    try {
      // Obtener medallas no sincronizadas localmente
      final unsyncedBadges = await _firestore
          .collection(_userBadgesCollection)
          .where('userId', isEqualTo: userId)
          .where('synced', isEqualTo: 0)
          .get();

      for (final doc in unsyncedBadges.docs) {
        final userBadge = UserBadge.fromMap({...doc.data(), 'id': doc.id});

        try {
          await updateUserBadge(userBadge);
        } catch (e) {
          debugPrint('Error sincronizando medalla ${userBadge.id}: $e');
        }
      }
    } catch (e) {
      throw Exception('Error en sincronización: $e');
    }
  }


  // ========== Creacion y manejo Badges ==========

  /// Crear múltiples medallas (admin)
  Future<void> createBadges(List<Badge_Medal> badges) async {
    try {
      final batch = _firestore.batch();

      for (final badge in badges) {
        final docRef = _firestore
            .collection(_badgesCollection)
            .doc(badge.id);

        batch.set(docRef, badge.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al crear medallas: $e');
    }
  }

  /// Inicializar medallas de usuario
  Future<void> initializeUserBadges(
    String userId,
    List<String> badgeIds,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final badgeId in badgeIds) {
        final userBadge = UserBadge(
          id: '${userId}_$badgeId',
          userId: userId,
          badgeId: badgeId,
          isUnlocked: false,
          progress: 0,
          earnedAt: null,
        );

        final docRef = _firestore
            .collection(_userBadgesCollection)
            .doc(userBadge.id);

        batch.set(docRef, userBadge.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error inicializando medallas: $e');
    }
  }

  /// Obtener estadísticas de medallas
  Future<Map<String, dynamic>> getBadgeStats(String userId) async {
    try {
      final userBadges = await getUserBadges(userId);
      final allBadges = await getAllBadges();

      final unlocked = userBadges.where((ub) => ub.isUnlocked).length;
      final rare = allBadges
          .where((b) => b.rarity == 'rare')
          .map((b) => b.id)
          .where((id) => userBadges.any((ub) => ub.badgeId == id && ub.isUnlocked))
          .length;
      final epic = allBadges
          .where((b) => b.rarity == 'epic')
          .map((b) => b.id)
          .where((id) => userBadges.any((ub) => ub.badgeId == id && ub.isUnlocked))
          .length;
      final legendary = allBadges
          .where((b) => b.rarity == 'legendary')
          .map((b) => b.id)
          .where((id) => userBadges.any((ub) => ub.badgeId == id && ub.isUnlocked))
          .length;

      return {
        'total_unlocked': unlocked,
        'total_badges': allBadges.length,
        'completion_percentage': ((unlocked / allBadges.length) * 100).toInt(),
        'rare_count': rare,
        'epic_count': epic,
        'legendary_count': legendary,
      };
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }

  /// Resetear progreso (admin/debug)
  Future<void> resetUserBadges(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_userBadgesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error reseteando medallas: $e');
    }
  }
}

// ============= LOCAL CACHE IMPLEMENTATION (OFFLINE) =============

//=== Shared Preferences====
class BadgePreferences {
  
  // Guardar contadores
  Future<void> saveBadgeStats(int totalBadges, int completedBadges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_badges_count', totalBadges);
    await prefs.setInt('completed_badges_count', completedBadges);
  }

  // Leer contadores (retorna una lista o un objeto simple)
  Future<Map<String, int>> getBadgeStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'total': prefs.getInt('total_badges_count') ?? 0,
      'completed': prefs.getInt('completed_badges_count') ?? 0,
    };
  }
}

//====== Archivos Locales =============
class UserBadgeFileStorage {
  
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/user_badges_detail.json');
  }
  // Guardar lista de UserBadges
  Future<void> saveUserBadges(List<UserBadge> userBadges) async {
    final file = await _getLocalFile();
    final String jsonString = jsonEncode(
      userBadges.map((ub) => ub.toMap()).toList()
    );
    await file.writeAsString(jsonString);
  }
  // Leer lista de UserBadges
  Future<List<UserBadge>> getUserBadges() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => UserBadge.fromMap(json)).toList();
    } catch (e) {
      debugPrint("Error leyendo archivo de badges: $e");
      return [];
    }
  }
}


class LocalBadgeRepository implements IBadgeRepository {
  // Para usar con Hive, Isar o similar
  // Este es un ejemplo con memoria local

  final Map<String, Badge_Medal> _badgesCache = {};
  final Map<String, List<UserBadge>> _userBadgesCache = {};

  @override
  Future<List<Badge_Medal>> getAllBadges() async {
    return _badgesCache.values.toList();
  }

  @override
  Future<List<UserBadge>> getUserBadges(String userId) async {
    return _userBadgesCache[userId] ?? [];
  }

  @override
  Future<UserBadge?> getUserBadgeProgress(
    String userId,
    String badgeId,
  ) async {
    final userBadges = _userBadgesCache[userId] ?? [];
    try {
      return userBadges.firstWhere((ub) => ub.badgeId == badgeId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<UserBadge>> getUnlockedBadges(String userId) async {
    final userBadges = _userBadgesCache[userId] ?? [];
    return userBadges.where((ub) => ub.isUnlocked).toList();
  }

  @override
  Future<void> updateUserBadge(UserBadge userBadge) async {
    final userId = userBadge.userId;
    _userBadgesCache.putIfAbsent(userId, () => []);

    final index = _userBadgesCache[userId]!
        .indexWhere((ub) => ub.badgeId == userBadge.badgeId);

    if (index != -1) {
      _userBadgesCache[userId]![index] = userBadge;
    }
  }

  @override
  Future<void> createUserBadge(UserBadge userBadge) async {
    final userId = userBadge.userId;
    _userBadgesCache.putIfAbsent(userId, () => []);
    _userBadgesCache[userId]!.add(userBadge);
  }

  @override
  Future<void> syncOfflineBadges(String userId) async {
    // No necesaria para local
  }

  Future<void> cacheBadges(List<Badge_Medal> badges) async {
    for (final badge in badges) {
      _badgesCache[badge.id] = badge;
    }
  }

  Future<void> clearCache() async {
    _badgesCache.clear();
    _userBadgesCache.clear();
  }
}

// Crear badges base





