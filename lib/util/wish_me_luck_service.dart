import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class WishMeLuckService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<WishMeLuckEvent> getWishMeLuckEvent() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('Buscando evento aleatorio...');

      final QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('active', isEqualTo: true)
          .limit(10)
          .get();

      print('Eventos encontrados: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        throw Exception('No hay eventos disponibles');
      }

      // Seleccionar evento aleatorio
      final random = Random();
      final randomDoc = snapshot.docs[random.nextInt(snapshot.docs.length)];
      
      final data = randomDoc.data() as Map<String, dynamic>;
      final event = WishMeLuckEvent.fromJson(data);
      
      print('Evento seleccionado: ${event.title}');
      
      return event;

    } catch (e) {
      print('Error en getWishMeLuckEvent: $e');
      throw Exception('Error al obtener evento: $e');
    }
  }
}