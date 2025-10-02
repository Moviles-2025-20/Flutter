import 'dart:math';

import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishMeLuckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Llamada real a tu backend/Firestore
  Future<WishMeLuckEvent> getWishMeLuckEvent() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Aquí haces la llamada a tu backend o Firestore
      // Ejemplo con Firestore:
      final QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('active', isEqualTo: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No hay eventos disponibles');
      }

      // Seleccionar un evento aleatorio
      final random = Random();
      final randomDoc = snapshot.docs[random.nextInt(snapshot.docs.length)];
      
      final data = randomDoc.data() as Map<String, dynamic>;
      return WishMeLuckEvent.fromJson(data);

    } catch (e) {
      throw Exception('Error al obtener evento: $e');
    }
  }
}