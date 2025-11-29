
import 'dart:async';

import 'package:app_flutter/pages/badges/model/badge.dart';
import 'package:app_flutter/pages/badges/model/user_badge.dart';
import 'package:app_flutter/util/badges_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Ejemplo de evento ya creado
  final asistenteEvento = Badge_Medal(
    id: "asistente_evento",
    name: "Asistente de Evento",
    description: "Participaste en tu primer evento del campus.",
    icon: "icons/event_attendee.png",
    rarity: "common",
    criteriaType: "events_attended",
    criteriaValue: 1,
    isSecret: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );


class BadgeMedalViewModel extends ChangeNotifier {
  final String userId;
  
  List<Badge_Medal> allBadgeMedals = [];
  List<UserBadge> userBadges = [];
  List<UserBadge> unlockedBadgeMedals = [];

  bool isLoading = false;
  String? errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final BadgeRepository badgeRepository;
  final _prefsService = BadgePreferences();
  final _fileStorage = UserBadgeFileStorage();

  bool isOfflineError = false; 
  StreamSubscription? _badgesSubscription;
  StreamSubscription? _connectivitySubscription;
  bool noBadgesAvailable = false;
  bool _isRetryingConnection = false;

  BadgeMedalViewModel({required this.userId, required this.badgeRepository});

  final List<Badge_Medal> defaultBadges = [
    Badge_Medal(
      id: "asistente_evento",
      name: "Asistente de Evento",
      description: "Participaste en tu primer evento del campus.",
      icon: "icons/event_attendee.png",
      rarity: "common",
      criteriaType: "events_attended",
      criteriaValue: 1,
      isSecret: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<void> crearBadgesIniciales() async {
    debugPrint("Creando badges iniciales");
    await badgeRepository.createBadges(defaultBadges);
  }

  Future<void> loadAllBadgeMedals() async {
    isLoading = true;
    errorMessage = null;
    noBadgesAvailable = false;
    isOfflineError = false;
    notifyListeners();
    
    try {
      debugPrint("Cargando catálogo de badges...");
      allBadgeMedals = await badgeRepository.getAllBadges();
      
      if (allBadgeMedals.isEmpty) {
        debugPrint("No hay badges en el sistema");
        noBadgesAvailable = true;
        errorMessage = "No hay medallas disponibles en el sistema.";
        isLoading = false; // ⚡ IMPORTANTE
        notifyListeners();
        return;
      }
      
      debugPrint("Catálogo cargado: ${allBadgeMedals.length} badges");
      await loadUserBadges();
      
    } catch (e) {
      debugPrint("Error al cargar catálogo: $e");
      errorMessage = 'Error al cargar medallas: $e';
      isLoading = false; // ⚡ IMPORTANTE
      notifyListeners();
    }
  }

  Future<void> loadUserBadges() async {
    try {
      debugPrint("Cargando badges del usuario...");
      isOfflineError = false;
      isLoading = true;
      notifyListeners();
      
      // Suscribirse a actualizaciones de fondo
      _badgesSubscription?.cancel();
      _badgesSubscription = badgeRepository.badgesUpdateStream.listen((newBadges) {
        debugPrint("Actualización en segundo plano recibida");
        userBadges = newBadges;
        unlockedBadgeMedals = userBadges.where((b) => b.isUnlocked).toList();
        _updateStatsPrefs();
        notifyListeners();
      });
      
      userBadges = await badgeRepository.getUserBadges(userId);
      debugPrint("Badges del usuario cargadas: ${userBadges.length}");
      
      // Si es la primera vez
      if (userBadges.isEmpty && allBadgeMedals.isNotEmpty) {
        debugPrint(" Primera vez: inicializando badges del usuario...");
        final badgeIds = allBadgeMedals.map((badge) => badge.id).toList();
        await badgeRepository.initializeUserBadges(userId, badgeIds);
        userBadges = await badgeRepository.getUserBadges(userId);
        debugPrint(" UserBadges inicializados: ${userBadges.length}");
      }
      
      unlockedBadgeMedals = userBadges.where((b) => b.isUnlocked).toList();
      debugPrint(" Badges desbloqueadas: ${unlockedBadgeMedals.length}");
      
      await _updateStatsPrefs();
      

      isLoading = false;
      errorMessage = null;
      isOfflineError = false;
      notifyListeners();
      
    } on NoInternetException catch (e) {
      debugPrint(" Sin internet y sin caché: $e");
      isOfflineError = true;
      isLoading = false; // ⚡ IMPORTANTE: Dejar de cargar
      errorMessage = "Sin conexión. Se volverá a intentar automáticamente.";
      notifyListeners();
      
      // Auto-reconectar
      _listenForConnectionRestored();
      
    } catch (e) {
      debugPrint(" Error general: $e");
      errorMessage = 'Error al cargar medallas: $e';
      isLoading = false; // ⚡ IMPORTANTE
      isOfflineError = false;
      notifyListeners();
    }
  }

  void _listenForConnectionRestored() {
    debugPrint(" Escuchando cambios de conectividad...");
    _connectivitySubscription?.cancel();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (!isOfflineError || _isRetryingConnection) {
        debugPrint("⏭ Ignorando cambio (no offline o ya reintentando)");
        return;
      }
      
      if (result == ConnectivityResult.none) {
        debugPrint(" Aún sin conexión");
        return;
      }
      
      debugPrint(" Cambio de conexión detectado a: $result");
      
      _isRetryingConnection = true;
      isLoading = true; // ⚡ Mostrar loading durante reconexión
      errorMessage = "Reconectando...";
      notifyListeners();
      
      // Esperar un poco para que la conexión se estabilice
      await Future.delayed(const Duration(seconds: 1));
      
      try {
        final hasRealInternet = await badgeRepository.checkRealConnection();
        
        if (hasRealInternet) {
          debugPrint(" Conexión confirmada. Reintentando carga...");
          await loadUserBadges(); // Esto ya maneja isLoading
        } else {
          debugPrint(" Sin acceso real a internet.");
          errorMessage = "Conectado pero sin acceso a internet";
          isLoading = false; // ⚡ IMPORTANTE
          notifyListeners();
        }
      } catch (e) {
        debugPrint(" Error al reintentar: $e");
        errorMessage = "Error al reconectar: $e";
        isLoading = false; // ⚡ IMPORTANTE
        notifyListeners();
      } finally {
        _isRetryingConnection = false;
      }
    });
  }

  Future<void> _updateStatsPrefs() async {
    final int totalBadges = allBadgeMedals.length;
    final int unlockedCount = userBadges.where((ub) => ub.isUnlocked).length;
    await _prefsService.saveBadgeStats(totalBadges, unlockedCount);
    debugPrint(" Stats actualizados: $unlockedCount / $totalBadges");
  }

  Badge_Medal? getBadgeMedalById(String badgeMedalId) {
    try {
      return allBadgeMedals.firstWhere((b) => b.id == badgeMedalId);
    } catch (e) {
      return null;
    }
  }

  UserBadge? getUserBadgeProgress(String badgeMedalId) {
    try {
      return userBadges.firstWhere((ub) => ub.badgeId == badgeMedalId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBadgeMedalProgress(
    String badgeMedalId,
    int newProgress, {
    List<String>? criteria,
  }) async {
    try {
      UserBadge? userBadge = getUserBadgeProgress(badgeMedalId);
      if (userBadge == null) return;

      Badge_Medal? badgeMedal = getBadgeMedalById(badgeMedalId);
      if (badgeMedal == null) return;

      bool shouldUnlock = false;

      switch (badgeMedal.criteriaType) {
        case 'tasks_completed':
          shouldUnlock = newProgress >= (badgeMedal.criteriaValue as int);
          break;
        case 'streak_days':
          shouldUnlock = newProgress >= (badgeMedal.criteriaValue as int);
          break;
        case 'total_hours':
          shouldUnlock = newProgress >= (badgeMedal.criteriaValue as int);
          break;
        case 'categories_explored':
          shouldUnlock = (criteria?.length ?? 0) >= (badgeMedal.criteriaValue as int);
          break;
        case 'custom_challenge':
          shouldUnlock = criteria?.contains(badgeMedal.criteriaValue) ?? false;
          break;
      }

      final updatedUserBadge = UserBadge(
        id: userBadge.id,
        userId: userBadge.userId,
        badgeId: userBadge.badgeId,
        isUnlocked: userBadge.isUnlocked || shouldUnlock,
        progress: shouldUnlock ? (badgeMedal.criteriaValue as int) : newProgress,
        earnedAt: shouldUnlock ? DateTime.now() : userBadge.earnedAt,
      );

      await badgeRepository.updateUserBadge(updatedUserBadge);

      final index = userBadges.indexWhere((ub) => ub.badgeId == badgeMedalId);
      if (index != -1) {
        userBadges[index] = updatedUserBadge;
        if (updatedUserBadge.isUnlocked && 
            !unlockedBadgeMedals.any((b) => b.badgeId == badgeMedalId)) {
          unlockedBadgeMedals.add(updatedUserBadge);
        }
      }
      
      await _fileStorage.saveUserBadges(userBadges);
      await _updateStatsPrefs();
      notifyListeners();
      
    } catch (e) {
      errorMessage = 'Error actualizando progreso: $e';
      notifyListeners();
    }
  }

  /// Obtener medallas por rareza
  List<Badge_Medal> getBadgeMedalsByRarity(String rarity) {
    return allBadgeMedals.where((b) => b.rarity == rarity).toList();
  }

  /// Obtener medallas secretas que no están desbloqueadas
  List<Badge_Medal> getSecretLockedBadgeMedals() {
    final unlockedIds = unlockedBadgeMedals.map((ub) => ub.badgeId).toSet();
    return allBadgeMedals
        .where((b) => b.isSecret && !unlockedIds.contains(b.id))
        .toList();
  }

  /// Calcular progreso general (0-100)
  int getOverallProgress() {
    if (allBadgeMedals.isEmpty) return 0;
    final unlocked = unlockedBadgeMedals.length;
    return ((unlocked / allBadgeMedals.length) * 100).toInt();
  }

}
