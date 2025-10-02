import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static const String _databaseId = 'default';
  
  static FirebaseFirestore get firestore {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: _databaseId,
    );
  }
}