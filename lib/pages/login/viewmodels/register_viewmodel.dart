import 'package:app_flutter/util/analytics_service.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../util/local_DB_service.dart';
import 'auth_viewmodel.dart';

class RegisterViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseService.firestore;
  final AnalyticsService _analytics = AnalyticsService();
  final LocalUserService _localUserService = LocalUserService();
  final AuthViewModel authViewModel;

  RegisterViewModel({required this.authViewModel});

  String? name;
  String? email;
  String? major;
  String? gender;
  DateTime? birthDate;
  List<Map<String, String>> freeTimeSlots = []; // [{start, end}]
  List<String> favoriteCategories = [];

  int indoorOutdoorScore = 50;

  void toggleCategory(String category) {
    if (favoriteCategories.contains(category)) {
      favoriteCategories.remove(category);
    } else {
      favoriteCategories.add(category);
    }
  }

  //  Métodos para manejar freeTimeSlots
  void addFreeTimeSlot(String start, String end) {
    freeTimeSlots.add({"start": start, "end": end});
  }

  void removeFreeTimeSlot(int index) {
    if (index >= 0 && index < freeTimeSlots.length) {
      freeTimeSlots.removeAt(index);
    }
  }

  void updateFreeTimeSlot(int index, String start, String end) {
    if (index >= 0 && index < freeTimeSlots.length) {
      freeTimeSlots[index] = {"start": start, "end": end};
    }
  }


  Future<void> saveUserData(String uid) async {
    String? errorMessage;

    final photoPath = authViewModel.user?.photoURL ?? '';
    print("1. Porcentaje:");
    print(indoorOutdoorScore);

    // Validar campos requeridos primero
    final missingFields = <String>[];

    if (name == null || name!.trim().isEmpty) missingFields.add("name");
    if (email == null || email!.trim().isEmpty) missingFields.add("email");
    if (major == null || major!.trim().isEmpty) missingFields.add("major");
    if (gender == null) missingFields.add("gender");
    if (birthDate == null) missingFields.add("birth date");
    if (favoriteCategories.isEmpty) missingFields.add("preferences");
    if (freeTimeSlots.isEmpty) missingFields.add("free time slots");

    if (missingFields.isNotEmpty) {
      errorMessage =
      "Please complete the following fields: ${missingFields.join(", ")}";
      notifyListeners();
      throw Exception(errorMessage);
    }

    //  Ya está validado que birthDate no sea null
    final now = DateTime.now();
    final age = now.year - birthDate!.year -
        ((now.month < birthDate!.month ||
            (now.month == birthDate!.month && now.day < birthDate!.day))
            ? 1
            : 0);

    if (age < 10 || age > 120) {
      throw Exception("Age must be between 10 and 120 years");
    }

    // 2. Guardar localmente
    debugPrint('INSERT LOCAL START');
    await _localUserService.insertUser({
      "id": uid,
      "name": name,
      "email": email,
      "photo": photoPath,
      "major": major,
      "gender": gender,
      "age": age,
      "indoorOutdoorScore": indoorOutdoorScore,
      "favoriteCategories": favoriteCategories.join(','),
      "freeTimeSlots": freeTimeSlots.map((slot) => "${slot['day']}-${slot['start']}-${slot['end']}").join(','),
      "createdAt": now.toIso8601String(),
      "synced": 0, //  marca como pendiente
    });
    debugPrint('LOCAL SAVED');
    await _localUserService.debugPrintUsers();
    _analytics.logOutdoorIndoorActivity(indoorOutdoorScore);

    // Verificar conexión
    debugPrint('CHECKIN INTERNET');
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (hasInternet) {
      debugPrint('HAS INTERNET');
      await _db.collection("users").doc(uid).set({
        "profile": {
          "name": name,
          "email": email,
          "photo": photoPath,
          "major": major,
          "gender": gender,
          "age": age,
          "created": FieldValue.serverTimestamp(),
          "last_active": FieldValue.serverTimestamp(),
        },
        "preferences": {
          "favorite_categories": favoriteCategories,
          "indoor_outdoor_score": indoorOutdoorScore,
          "notifications": {
            "free_time_slots": freeTimeSlots,
          },
        },
      }, SetOptions(merge: true));

      await _localUserService.markUserAsSynced(uid);
      _analytics.logOutdoorIndoorActivity(indoorOutdoorScore);
    }

    debugPrint('FINISH');
  }


  Future<void> syncPendingUsers() async {
    debugPrint('SYNC PENDINDG USER');
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    final pendingUsers = await _localUserService.getUnsyncedUsers();

    for (final user in pendingUsers) {
      try {
        await _db.collection("users").doc(user['id']).set({
          "profile": {
            "name": user['name'],
            "email": user['email'],
            "photo": user['photo'],
            "major": user['major'],
            "gender": user['gender'],
            "age": user['age'],
            "created": FieldValue.serverTimestamp(),
            "last_active": FieldValue.serverTimestamp(),
          },
          "preferences": {
            "favorite_categories": user['favoriteCategories'].toString().split(','),
            "indoor_outdoor_score": user['indoorOutdoorScore'],
            "notifications": {
              "free_time_slots": user['freeTimeSlots'].toString().split(',').map((e) {
                final parts = e.split('-');
                if (parts.length == 3) {
                  return {
                    "day": parts[0],
                    "start": parts[1],
                    "end": parts[2],
                  };
                }
              }).toList(),
            },
          },
        }, SetOptions(merge: true));

        await _localUserService.markUserAsSynced(user['id']);
      } catch (e) {
        print("Error al sincronizar usuario ${user['id']}: $e");
      }
    }
  }



}
