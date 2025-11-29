import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:app_flutter/pages/badges/model/badge.dart';
import 'package:app_flutter/pages/badges/model/user_badge.dart';
import 'package:app_flutter/util/badges_cache.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:app_flutter/util/local_DB_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

// ========= Eventual Connectivity ==========
class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);
  @override
  String toString() => message;
}



// ============= FIRESTORE IMPLEMENTATION =============


class BadgeRepository implements IBadgeRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final LocalUserService _localService = LocalUserService(); 
  final _fileStorage = UserBadgeFileStorage();

  static const String _badgesCollection = 'badges';
  static const String _userBadgesCollection = 'user_badges';
  final _memoryCache = UserBadgesLruCache(capacity: 6);

  final _badgesUpdateController = StreamController<List<UserBadge>>.broadcast();
  Stream<List<UserBadge>> get badgesUpdateStream => _badgesUpdateController.stream;

  // Cache de estado de conexión
  DateTime? _lastConnectionCheck;
  bool? _lastConnectionStatus;
  static const _connectionCacheDuration = Duration(seconds: 10);

  // ========== GET ALL BADGES ==========
  @override
  Future<List<Badge_Medal>> getAllBadges() async {
    try {
      // 1. Intentar caché de Firebase
      try {
        final snapshot = await _firestore
            .collection('badges_definitions')
            .get(const GetOptions(source: Source.cache));
        if (snapshot.docs.isNotEmpty) {
          debugPrint("Firebase Cache HIT: Retornando catálogo local");
          return snapshot.docs.map((d) => Badge_Medal.fromMap(d.data())).toList();
        }
      } catch (e) {
        // Cache vacío, continuar
      }

      // 2. Local storage
      final localBadges = await _localService.getAllBadges();
      if (localBadges.isNotEmpty) {
        debugPrint("Local Storage HIT: Badges encontradas");
        return localBadges;
      }

      // 3. Firebase remoto
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

  // ========== GET USER BADGES ==========
  @override
  Future<List<UserBadge>> getUserBadges(String userId) async {
    try {
      List<UserBadge> localData = [];

      // 1. Cache en RAM
      final cachedBadges = _memoryCache.get(userId);
      if (cachedBadges != null) {
        debugPrint("Cache HIT (RAM): Retornando badges desde memoria");
        localData = cachedBadges;
      } else {
        debugPrint("Cache MISS (RAM): Buscando en disco...");

        // 2. Cache en disco
        final localUserBadges = await _fileStorage.getUserBadges();
        if (localUserBadges.isNotEmpty) {
          debugPrint("Disk HIT: Retornando badges desde archivo local");
          _memoryCache.put(userId, localUserBadges);
          localData = localUserBadges;
        }
      }

      // Si hay datos locales, retornarlos y sincronizar en fondo
      if (localData.isNotEmpty) {
        _backgroundSync(userId); 
        return localData;
      }

      // 3. Verificar conexión con timeout corto
      debugPrint("Disk MISS: Verificando conexión...");
      final hasConnection = await _checkConnectionFast();

      if (!hasConnection) {
        throw NoInternetException("No tienes conexión y no hay datos guardados.");
      }

      // 4. Descargar de Firebase
      debugPrint("Descargando de Firebase...");
      return await _fetchAndSaveFromFirebase(userId);
      
    } on NoInternetException {
      rethrow;
    } catch (e) {
      debugPrint('Error al cargar medallas del usuario: $e');
      return [];
    }
  }

  // ========== GET USER BADGE PROGRESS ==========
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

  // ========== GET UNLOCKED BADGES ==========
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

  // ========== UPDATE USER BADGE ==========
  @override
  Future<void> updateUserBadge(UserBadge userBadge) async {
    try {
      final data = userBadge.toMap();
      data['synced'] = 1;

      await _firestore
          .collection(_userBadgesCollection)
          .doc(userBadge.id)
          .set(data, SetOptions(merge: true));

    } catch (e) {
      throw Exception('Error al actualizar medalla: $e');
    }
  }

  // ========== CREATE USER BADGE ==========
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

  // ========== SYNC OFFLINE BADGES ==========
  @override
  Future<void> syncOfflineBadges(String userId) async {
    try {
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

  // ========== MÉTODOS AUXILIARES ==========

  /// Verificación rápida de conexión (solo conectividad local)
  Future<bool> _checkConnectionFast() async {
    // Usar cache si es reciente
    if (_lastConnectionCheck != null && 
        _lastConnectionStatus != null &&
        DateTime.now().difference(_lastConnectionCheck!) < _connectionCacheDuration) {
      debugPrint("Usando estado de conexión en cache: $_lastConnectionStatus");
      return _lastConnectionStatus!;
    }

    // Solo verificar conectividad local
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;
    
    _lastConnectionCheck = DateTime.now();
    _lastConnectionStatus = isConnected;
    
    debugPrint("Estado de conexión: $isConnected");
    return isConnected;
  }

  /// Verificación completa de conexión (con ping real)
  Future<bool> checkRealConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    try {
      // Timeout reducido a 2 segundos
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  /// Sincronización en segundo plano
  bool _isSyncing = false;
  
  Future<void> _backgroundSync(String userId) async {
    if (_isSyncing) {
      debugPrint("[Background] Sync ya en progreso, omitiendo...");
      return;
    }
    
    _isSyncing = true;
    
    // Usar verificación rápida primero
    final hasBasicConnection = await _checkConnectionFast();
    if (!hasBasicConnection) {
      debugPrint("[Background] Sin conexión local, cancelando sync");
      _isSyncing = false;
      return;
    }
    
    try {
      debugPrint("[Background] Iniciando sincronización...");
      final newBadges = await _fetchAndSaveFromFirebase(userId);
      
      _badgesUpdateController.add(newBadges);
      debugPrint("[Background] Sincronización completada.");
    } catch (e) {
      debugPrint("[Background] Error en sync: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// Descargar y guardar desde Firebase
  Future<List<UserBadge>> _fetchAndSaveFromFirebase(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_userBadgesCollection) 
          .where('userId', isEqualTo: userId)
          .get(const GetOptions(
            source: Source.serverAndCache,
          ))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout al cargar badges');
            },
          );

      final rawData = snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      
      // Solo usar Isolate si hay muchos datos
      List<UserBadge> parsedBadges;
      if (rawData.length > 50) {
        parsedBadges = await Isolate.run(() {
          return rawData.map((map) => UserBadge.fromMap(map)).toList();
        });
      } else {
        parsedBadges = rawData.map((map) => UserBadge.fromMap(map)).toList();
      }

      if (parsedBadges.isNotEmpty) {
        await _fileStorage.saveUserBadges(parsedBadges);
        _memoryCache.put(userId, parsedBadges);
      }
      
      return parsedBadges;
    } catch (e) {
      debugPrint("Error en _fetchAndSaveFromFirebase: $e");
      rethrow;
    }
  }

  // ========== MÉTODOS ADICIONALES ==========

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





