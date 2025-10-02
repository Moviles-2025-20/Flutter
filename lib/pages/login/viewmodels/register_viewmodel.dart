import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RegisterViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseService.firestore;

  String? name;
  String? email;
  String? major;
  String? gender;
  DateTime? birthDate;
  List<Map<String, String>> freeTimeSlots = []; // [{start, end}]
  List<String> favoriteCategories = [];

  //  Métodos para manejar categorías
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
    if (name == null ||
        email == null ||
        major == null ||
        gender == null ||
        birthDate == null ||
        favoriteCategories.isEmpty ||
        freeTimeSlots.isEmpty) {
      throw Exception("Debes completar todos los campos");
    }

    await _db.collection("users").doc(uid).set({
      "profile": {
        "name": name,
        "email": email,
        "major": major,
        "gender": gender,
        "age": DateTime.now().year - birthDate!.year,
        "created": FieldValue.serverTimestamp(),
        "last_active": FieldValue.serverTimestamp(),
      },
      "preferences": {
        "favorite_categories": favoriteCategories,
        "notifications": {
          "free_time_slots": freeTimeSlots,
        },
      }
    }, SetOptions(merge: true));
  }
}


