import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../util/firebase_service.dart';
import '../../../util/free_time_storage_service.dart';
import '../model/event.dart';
import '../model/free_time_slot.dart';
import 'package:app_flutter/pages/events/model/event.dart' as EventsModel;

class FreeTimeViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final EventStorageService _eventStorageService = EventStorageService();

  List<EventsModel.Event> _availableEvents = [];
  List<EventsModel.Event> get availableEvents => _availableEvents;


  List<FreeTimeSlot> _freeTimeSlots = [];

  List<FreeTimeSlot> get freeTimeSlots => _freeTimeSlots;



  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<bool> hasInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> loadAvailableEvents(String userId) async {
    _isLoading = true;

    _error = null;
    notifyListeners();

    final isConnected = await hasInternetConnection();
    final offlineEvents = await _eventStorageService.loadUserEvents(userId);

    try {


      // Mostrar desde cache o disco
      final offlineEvents = await _eventStorageService.loadUserEvents(userId);
      for (final e in offlineEvents) {
        debugPrint('🧪 Evento desde disco: $e');
        debugPrint('🧪 ID detectado: ${e['id']}');
      }
      if (!isConnected) {
        if (offlineEvents.isNotEmpty) {
          _availableEvents = offlineEvents
              .map((e) => EventsModel.Event.fromJson(e['id'], e))
              .toList();
          notifyListeners(); // Mostrar rápido
        }else {
          _error = "There is no network and no saved events, try later.";
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cargar los datos del usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();
      debugPrint("Loading free time for userId: $userId");
      if (!userDoc.exists || userDoc.data() == null) {
        _error = "User not found";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userData = userDoc.data()!;
      final freeSlotsData = ((userData['preferences']?['notifications']?['free_time_slots']) as List<dynamic>?) ?? [];



      // Mapear free time slots
      _freeTimeSlots = freeSlotsData.map((slot) {
        return FreeTimeSlot.fromMap(slot as Map<String, dynamic>);
      }).toList();


      // Cargar eventos activos
      final eventsSnapshot = await _firestore.collection('events').where('active', isEqualTo: true).get();
      final events = eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Event.fromMap(data);
      }).toList();

      // Filtrar por tiempos libres
      final matched = events.where((event) {
        return _freeTimeSlots.any((slot) =>
        slot.day.toLowerCase() == event.day.toLowerCase() &&
            (slot.startTime.isBefore(event.startTime) || slot.startTime.isAtSameMomentAs(event.startTime)) &&
            (slot.endTime.isAfter(event.endTime) || slot.endTime.isAtSameMomentAs(event.endTime))
        );
      }).toList();

      // Obtener versión detallada para todos los eventos filtrados
      final detailedEvents = <EventsModel.Event>[];
      for (final e in matched) {
        final detailed = await getEventById(e.id);
        if (detailed != null) detailedEvents.add(detailed);
      }
      print("vamos a guardarlossss 3");
      // 7️⃣ Guardar los 3 primeros en cache y disco
      await _eventStorageService.saveUserEvents(userId, detailedEvents.take(3).toList());

      // 8️⃣ Mostrar todos los eventos detallados
      _availableEvents = detailedEvents;
      notifyListeners();

      debugPrint("Total available events: ${_availableEvents.length}");
    } catch (e) {
      _error = "Error loading data: $e";
      debugPrint("Error in FreeTimeViewModel: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EventsModel.Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      // doc.data() es Map<String, dynamic>
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Llamamos al factory correcto (en tu modelo grande es fromJson)
      return EventsModel.Event.fromJson(doc.id, data);
    } catch (e) {
      debugPrint("Error fetching event by id: $e");
      return null;
    }
  }


}
