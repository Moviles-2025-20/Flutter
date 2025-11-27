
import 'package:app_flutter/pages/badges/model/badge.dart';
import 'package:app_flutter/pages/badges/model/user_badge.dart';
import 'package:app_flutter/util/badges_service.dart';
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
 

  BadgeMedalViewModel({required this.userId, required this.badgeRepository});

  //Badges Base
  final List<Badge_Medal> defaultBadges = [
    asistenteEvento,
  ];

  Future<void> crearBadgesIniciales() async {
    debugPrint("Se estan creando las badges");
    await badgeRepository.createBadges(defaultBadges);
  }

  /// Cargar todas las medallas disponibles
  Future<void> loadAllBadgeMedals() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      allBadgeMedals = await badgeRepository.getAllBadges();
      await loadUserBadges();
    } catch (e) {
      errorMessage = 'Error al cargar medallas: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar medallas del usuario
  Future<void> loadUserBadges() async {
    try {
      userBadges = await badgeRepository.getUserBadges(userId);
      unlockedBadgeMedals = userBadges.where((b) => b.isUnlocked).toList();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error al cargar medallas del usuario: $e';
      notifyListeners();
    }
  }

  /// Obtener información de una medalla específica
  Badge_Medal? getBadgeMedalById(String badgeMedalId) {
    try {
      return allBadgeMedals.firstWhere((b) => b.id == badgeMedalId);
    } catch (e) {
      return null;
    }
  }

  /// Obtener progreso del usuario en una medalla
  UserBadge? getUserBadgeProgress(String badgeMedalId) {
    try {
      return userBadges.firstWhere((ub) => ub.badgeId == badgeMedalId);
    } catch (e) {
      return null;
    }
  }

  /// Actualizar progreso de una medalla
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

      // Validar criterios según el tipo
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

      // Actualizar UserBadge
      final updatedUserBadge = UserBadge(
        id: userBadge.id,
        userId: userBadge.userId,
        badgeId: userBadge.badgeId,
        isUnlocked: userBadge.isUnlocked || shouldUnlock,
        progress: shouldUnlock ? (badgeMedal.criteriaValue as int) : newProgress,
        earnedAt: shouldUnlock ? DateTime.now() : userBadge.earnedAt,
        synced: 0,
      );

      // Guardar en Firestore
      await badgeRepository.updateUserBadge(updatedUserBadge);

      // Actualizar lista local
      final index = userBadges.indexWhere((ub) => ub.badgeId == badgeMedalId);
      if (index != -1) {
        userBadges[index] = updatedUserBadge;
        if (updatedUserBadge.isUnlocked && 
            !unlockedBadgeMedals.any((b) => b.badgeId == badgeMedalId)) {
          unlockedBadgeMedals.add(updatedUserBadge);
        }
      }

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

  /// Demo data
  List<Badge_Medal> _getDemoBadgeMedals() {
    return [
      Badge_Medal(
        id: '1',
        name: 'Primer Paso',
        description: 'Completa tu primera tarea',
        icon: 'assets/Badge_Medals/first_step.png',
        rarity: 'common',
        criteriaType: 'tasks_completed',
        criteriaValue: 1,
        isSecret: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Badge_Medal(
        id: '2',
        name: 'Productivo',
        description: 'Completa 10 tareas',
        icon: 'assets/Badge_Medals/productive.png',
        rarity: 'rare',
        criteriaType: 'tasks_completed',
        criteriaValue: 10,
        isSecret: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Badge_Medal(
        id: '3',
        name: 'Streaker',
        description: 'Mantén una racha de 7 días',
        icon: 'assets/Badge_Medals/streaker.png',
        rarity: 'epic',
        criteriaType: 'streak_days',
        criteriaValue: 7,
        isSecret: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<UserBadge> _getDemoUserBadges() {
    return allBadgeMedals.map((badgeMedal) {
      return UserBadge(
        id: 'ub_${badgeMedal.id}',
        userId: userId,
        badgeId: badgeMedal.id,
        isUnlocked: badgeMedal.id == '1',
        progress: badgeMedal.id == '1' ? 1 : 0,
        earnedAt: badgeMedal.id == '1' ? DateTime.now() : null,
        synced: 1,
      );
    }).toList();
  }
}
