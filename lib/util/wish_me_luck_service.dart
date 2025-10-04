
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class WishMeLuckService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  //Lista para poblar la base de datos
  List<Map<String, dynamic>> studentEvents = [
  ];

  Future<WishMeLuckEvent> getWishMeLuckEvent() async {
  try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      String category_event = "Nothing"; 
      List categories_user = []; 

      print("Buscando ultimo evento usuario y categorias favoritas del usuario");

      Map<String,dynamic> elements = await getLastEvent();

      if (elements["last_event"] != "Nothing"){
        category_event = elements["last_event"];
      }
      if (elements["categories"] != "Nothing"){
        categories_user = elements["categories"];
      }

      //Filter categories likes
      if (category_event != "Nothing" && categories_user.isNotEmpty) {
        categories_user.removeWhere((c) => c == category_event);
      }

      print('Buscando evento aleatorio...');

      final QuerySnapshot snapshot = await _firestore
          .collection('events')
          .get();

      print('Eventos encontrados: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        throw Exception('No hay eventos disponibles');
      }

      List<QueryDocumentSnapshot> filteredDocs;

      if (categories_user.isNotEmpty) {
        filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final eventCategory = data['category'] as String?;
          return eventCategory != null && categories_user.contains(eventCategory);
        }).toList();
      } else {
        filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final eventCategory = data['category'] as String?;
          return eventCategory != category_event;
        }).toList();
      }

      print('Eventos filtrados: ${filteredDocs.length}');

      List<QueryDocumentSnapshot> searchDocs = 
          filteredDocs.isEmpty ? snapshot.docs : filteredDocs;

      // Select Random event
      final random = Random();
      final randomIndex = random.nextInt(searchDocs.length);
      final selectedDoc = searchDocs[randomIndex];
      
      final data = selectedDoc.data() as Map<String, dynamic>;
      final docId = selectedDoc.id; 

      final event = WishMeLuckEvent.fromJson(data, docId);

      print('Evento seleccionado: ${event.title} - ID: $docId');

      return event;
    } catch (e) {
      print('Error en getWishMeLuckEvent: $e');
      throw Exception('Error al obtener evento: $e');
    }
  }

  Future<Event?> getWishMeLuckEventDetail(String? eventId) async {
    if (eventId == null) return null;
    print(eventId);
    final doc = await _firestore.collection('events').doc(eventId).get(); 
    if (doc.exists) {
      final data = doc.data();
      if (data != null ) {
        return Event.fromJson(eventId,data);
      }
    }
    return null; 
  }

  Future<Map<String,dynamic>> getLastEvent() async {
    final user = _auth.currentUser;
        if (user == null) {
          throw Exception('Usuario no autenticado');
        }

        Map<String, dynamic> respuesta = {};

        final doc = await _firestore.collection('users').doc(user.uid).get(); 
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.containsKey('last_event')) {
            respuesta["last_event"] = data['last_event'] as String;
          }else{
            respuesta["last_event"] = "Nothing";
          }
          print(respuesta["last_event"]);
          if (data != null && data.containsKey('preferences')) {
            final preferences = data['preferences'] as Map<String, dynamic>;
            if (preferences.containsKey("favorite_categories")){
              respuesta["categories"] = data["preferences"]['favorite_categories'] as  List;
            } else{
            respuesta["categories"] = "Nothing";
          }
          }else{
            respuesta["categories"] = "Nothing";
          }
          print(respuesta["categories"]);
        }

        
        return respuesta;
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
        if (data != null && data.containsKey('stats')) {
          final stats = data['stats'] as Map<String, dynamic>;
          if (stats.containsKey('last_wish_me_luck')) {
            return (data['stats']['last_wish_me_luck'] as Timestamp).toDate();
          }
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
      'stats': {
        'last_wish_me_luck': Timestamp.fromDate(date),
      }
    }, SetOptions(merge: true));
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
