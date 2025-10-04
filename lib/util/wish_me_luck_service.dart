import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';


class WishMeLuckService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService();


  //Lista para poblar la base de datos
  List<Map<String, dynamic>> studentEvents = [];

  Future<WishMeLuckEvent> getWishMeLuckEvent() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _analytics.logDiscoveryMethod(DiscoveryMethod.wishMeLuck);

      /*
      print('Creando eventos...');
      await addEvents(studentEvents);
      */

      print('Buscando evento aleatorio...');

      final QuerySnapshot snapshot = await _firestore
          .collection('events')
          .get();

      print('Eventos encontrados: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        throw Exception('No hay eventos disponibles');
      }

      // Seleccionar evento aleatorio AGREGAR SMART
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

  Future<DateTime?> getLastWishedDate() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('lastWished')) {
          return (data['lastWished'] as Timestamp).toDate();
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener la última fecha: $e');
      return null;
    }
  }

  Future<void> setLastWishedDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _firestore.collection('users').doc(user.uid).set({
        'lastWished': Timestamp.fromDate(date),
      }, SetOptions(merge: true));

      _analytics.logWishMeLuckUsed(user.uid);

    } catch (e) {
      print('Error al establecer la última fecha: $e');
    }
  }

  Future<void> addEvents(List<Map<String, dynamic>> events) async {
    try {
      for (var event in events) {
        await _firestore.collection('events').add(event);
      }
      print('Todos los eventos se añadieron correctamente!');
    } catch (e) {
      print('Error al añadir eventos: $e');
    }
  }
}
