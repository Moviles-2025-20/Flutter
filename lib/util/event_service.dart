import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/event_filter.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class EventsService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener eventos con filtros
  Future<List<Event>> getEvents({EventFilters? filters}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      Query query = _firestore.collection('events').where('active', isEqualTo: true);

      // Aplicar filtros de Firestore (solo los que Firestore soporta directamente)
      if (filters?.category != null) {
        query = query.where('category', isEqualTo: filters!.category);
      }

      if (filters?.city != null) {
        query = query.where('location.city', isEqualTo: filters!.city);
      }

      if (filters?.weatherDependent != null) {
        query = query.where('weather_dependent', isEqualTo: filters!.weatherDependent);
      }

      // Limitar resultados
      query = query.limit(100);

      final QuerySnapshot snapshot = await query.get();
      
      List<Event> events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Event.fromJson(doc.id, data);
      }).toList();

      // Aplicar filtros en memoria (los que Firestore no soporta bien)
      events = _applyInMemoryFilters(events, filters);

      return events;
    } catch (e) {
      print('Error al obtener eventos: $e');
      throw Exception('Error al obtener eventos: $e');
    }
  }

  // Filtros en memoria
  List<Event> _applyInMemoryFilters(
    List<Event> events,
    EventFilters? filters,
  ) {
    if (filters == null) return events;

    return events.where((event) {
      // Filtro por búsqueda (nombre, descripción, título)
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final query = filters.searchQuery!.toLowerCase();
        final matchesName = event.name.toLowerCase().contains(query);
        final matchesDescription = event.description.toLowerCase().contains(query);
        final matchesTitle = event.title.toLowerCase().contains(query);
        if (!matchesName && !matchesDescription && !matchesTitle) {
          return false;
        }
      }

      // Filtro por tipos de evento
      if (filters.eventTypes != null && filters.eventTypes!.isNotEmpty) {
        final hasMatchingType = filters.eventTypes!.contains(event.eventType);
        if (!hasMatchingType) return false;
      }

      // Filtro por rating mínimo
      if (filters.minRating != null) {
        if (event.stats.rating.isNotEmpty && (event.stats.rating.reduce((a, b) => a + b) / event.stats.rating.length) < filters.minRating!) return false;
      }

      return true;
    }).toList();
  }

  // Obtener evento por ID
    Future<Event?> getEventById(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final doc = await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists) return null;


      final data = doc.data() as Map<String, dynamic>;
      print("DEBUG EVENT DATA: $data");
      return Event.fromJson(doc.id, data);
    } catch (e) {
      
      print('Error al obtener evento por ID: $e ');
      throw Exception('Error al obtener evento por ID: $e');
    }
  }

  // Obtener ciudades únicas (para el filtro)
  Future<List<String>> getAvailableCities() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('active', isEqualTo: true)
          .get();

      final cities = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['location']?['city'] as String?;
          })
          .where((city) => city != null)
          .toSet()
          .toList();

      return cities.cast<String>();
    } catch (e) {
      print('Error al obtener ciudades: $e');
      return [];
    }
  }

  // Obtener categorías únicas
  Future<List<String>> getAvailableCategories() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('active', isEqualTo: true)
          .get();

      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String?)
          .where((category) => category != null)
          .toSet()
          .toList();

      return categories.cast<String>();
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }
}