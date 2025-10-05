import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../util/firebase_service.dart';
import '../model/event.dart';
import '../model/free_time_slot.dart';
import 'package:app_flutter/pages/events/model/event.dart' as EventsModel;

class FreeTimeViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  List<Event> _availableEvents = [];
  List<Event> get availableEvents => _availableEvents;

  List<FreeTimeSlot> _freeTimeSlots = [];

  List<FreeTimeSlot> get freeTimeSlots => _freeTimeSlots;



  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;



  Future<void> loadAvailableEvents(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1️⃣ Cargar los datos del usuario
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
        final fts = FreeTimeSlot.fromMap(slot as Map<String, dynamic>);
        debugPrint("FreeSlot: ${fts.day}, "
            "${fts.startTime.hour}:${fts.startTime.minute.toString().padLeft(2,'0')} - "
            "${fts.endTime.hour}:${fts.endTime.minute.toString().padLeft(2,'0')}");
        return fts;
      }).toList();





      // 2️⃣ Cargar todos los eventos activos
      final eventsSnapshot =
      await _firestore.collection('events').where('active', isEqualTo: true).get();

      final events = eventsSnapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        final ev = Event.fromMap(data);
        debugPrint("Event: ${ev.id}, ${ev.day}, ${ev.startTime} - ${ev.endTime}");
        return ev;
      }).toList();

      // 3️⃣ Filtrar eventos según free slots
      _availableEvents = events.where((event) {
        final match = _freeTimeSlots.any((slot) {
          return slot.day.toLowerCase() == event.day.toLowerCase() &&
              (slot.startTime.isBefore(event.startTime) ||
                  slot.startTime.isAtSameMomentAs(event.startTime)) &&
              (slot.endTime.isAfter(event.endTime) ||
                  slot.endTime.isAtSameMomentAs(event.endTime));
        });

        if (match) {
          debugPrint("Matched Event: ${event.name} on ${event.day}");
        }

        return match;
      }).toList();


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
