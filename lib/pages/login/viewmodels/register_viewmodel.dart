import 'package:app_flutter/util/analytics_service.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RegisterViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseService.firestore;
  final AnalyticsService _analytics = AnalyticsService();

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

    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    print("1. Porcentaje:");
    print( indoorOutdoorScore);

    //  Validar rango de edad antes de guardar
    final now = DateTime.now();
    final age = now.year - birthDate!.year -
        ((now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) ? 1 : 0);

    if (age < 10 || age > 120) {
      throw Exception("Age must be between 10 and 120 years");
    }

    _analytics.logOutdoorIndoorActivity(indoorOutdoorScore);

    final missingFields = <String>[];

    if (name == null || name!.trim().isEmpty) missingFields.add("name");
    if (email == null || email!.trim().isEmpty) missingFields.add("email");
    if (major == null || major!.trim().isEmpty) missingFields.add("major");
    if (gender == null) missingFields.add("gender");
    if (birthDate == null) missingFields.add("birth date");
    if (favoriteCategories.isEmpty) missingFields.add("preferences");
    if (freeTimeSlots.isEmpty) missingFields.add("free time slots");

    if (missingFields.isNotEmpty) {
      errorMessage = "Please complete the following fields: ${missingFields.join(", ")}";
      notifyListeners(); // Notifica a la vista que hay un error
      throw Exception(errorMessage); // También lanza la excepción para que pueda ser atrapada en la UI
    }





    await _db.collection("users").doc(uid).set({
      "profile": {
        "name": name,
        "email": email,
        "photo": photoUrl,   // <-- foto de Auth
        "major": major,
        "gender": gender,
        "age": DateTime.now().year - birthDate!.year,
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

    _analytics.logOutdoorIndoorActivity(indoorOutdoorScore);
    
  }
}




