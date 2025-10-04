import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_flutter/pages/events/model/user_activity.dart';
import 'package:app_flutter/util/firebase_service.dart';

class UserActivityService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _collection => _firestore.collection("user_activities");


  Future<UserActivity?> getCheckIn(String userId, String eventId) async {
    final snapshot = await _collection
        .where("user_id", isEqualTo: userId)
        .where("event_id", isEqualTo: eventId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return UserActivity.fromDoc(snapshot.docs.first);
    }
    return null;
  }

  Future<void> toggleCheckIn(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    final existing = await getCheckIn(user.uid, eventId);

    if (existing == null) {

      await _collection.add(UserActivity(
        user_id: user.uid,
        event_id: eventId,
        time: DateTime.now(),
        source: "manual", 
        type: "check_in",
        withFriends: false,
      ).toMap());
    } else {
      final snapshot = await _collection
          .where("user_id", isEqualTo: user.uid)
          .where("event_id", isEqualTo: eventId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _collection.doc(snapshot.docs.first.id).delete();
      }
    }
  }
}
