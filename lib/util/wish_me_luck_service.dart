
import 'dart:async';
import 'dart:io';

import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/wishMeLuck/model/wish_me_luck_event.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:app_flutter/util/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';


class WishMeLuckService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final Connectivity _connectivity = Connectivity();

  static const String _lastWishedDateKey = 'last_wished_date';
  static const String _pendingSyncKey = 'pending_sync_last_wished_date';

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _hasInternet = true;


  //Lista para poblar la base de datos
  List<Map<String, dynamic>> studentEvents = [
  ];

  void initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        await _onConnectivityChanged(result);
      },
    );
    
    // Check initial connectivity
    _checkInitialConnectivity();
  }

  /// Check initial connectivity state
  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (result == ConnectivityResult.none) {
      _hasInternet = false;
    } else {
      _hasInternet = await _checkInternetConnection();
    }
    debugPrint('Estado inicial de internet: $_hasInternet');
  }

  /// Dispose connectivity listener
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    debugPrint('Connectivity changed: $result');
    
    final wasOffline = !_hasInternet;
    
    if (result == ConnectivityResult.none) {
      // Lost connection
      debugPrint('Internet connection lost');
      _hasInternet = false;
    } else {
      // Potentially gained connection - verify real connectivity
      debugPrint('Connection detected, verifying...');
      final realConnection = await _checkInternetConnection();
      
      if (realConnection && !_hasInternet) {
        // Internet recovered
        debugPrint('Internet connection recovered!');
        _hasInternet = true;
        
        // If was offline, sync pending data
        if (wasOffline) {
          debugPrint('Was offline, syncing pending data...');
          await _syncPendingData();
        }
      } else if (!realConnection) {
        // False positive - still no real internet
        debugPrint('Connected but no real internet');
        _hasInternet = false;
      }
    }
  }

  /// Sync pending data with Firebase when internet is restored
  Future<void> _syncPendingData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final pendingSyncDate = prefs.getString(_pendingSyncKey);

      if (pendingSyncDate != null) {
        final milliseconds = int.tryParse(pendingSyncDate);
        if (milliseconds != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
          
          try {
            await _firestore.collection('users').doc(user.uid).set({
              'stats': {
                'last_wish_me_luck': Timestamp.fromDate(date),
              }
            }, SetOptions(merge: true));

            await _analytics.logWishMeLuckUsed(user.uid);
            
            // Clear pending sync flag
            await prefs.remove(_pendingSyncKey);
            debugPrint('Datos sincronizados exitosamente con Firebase WhishMeLuck');
          } catch (e) {
            debugPrint('Error al sincronizar datos pendientes: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error en _syncPendingData: $e');
    }
  }

  /// Check if device has internet connectivity
  Future<bool> _checkInternetConnection() async {
    try {
      // Try to ping a reliable server to confirm actual internet access
      try {
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 5),
        );
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException catch (_) {
        return false;
      } on TimeoutException catch (_) {
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }

  Future<WishMeLuckEvent> getWishMeLuckEvent() async {
  try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _analytics.logDiscoveryMethod(DiscoveryMethod.wishMeLuck);

      await _analytics.logDiscoveryMethod(DiscoveryMethod.wishMeLuck);

      String category_event = "Nothing"; 
      List categories_user = []; 

      debugPrint("Buscando ultimo evento usuario y categorias favoritas del usuario");

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

      debugPrint('Buscando evento aleatorio...');

      final QuerySnapshot snapshot = await _firestore
          .collection('events')
          .get();

      debugPrint('Eventos encontrados: ${snapshot.docs.length}');

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

      debugPrint('Eventos filtrados: ${filteredDocs.length}');

      List<QueryDocumentSnapshot> searchDocs = 
          filteredDocs.isEmpty ? snapshot.docs : filteredDocs;

      // Select Random event
      final random = Random();
      final randomIndex = random.nextInt(searchDocs.length);
      final selectedDoc = searchDocs[randomIndex];
      
      final data = selectedDoc.data() as Map<String, dynamic>;
      final docId = selectedDoc.id; 

      final event = WishMeLuckEvent.fromJson(data, docId);

      debugPrint('Evento seleccionado: ${event.title} - ID: $docId');

      return event;
    } catch (e) {
      debugPrint('Error en getWishMeLuckEvent: $e');
      throw Exception('Error al obtener evento: $e');
    }
  }

  Future<Event?> getWishMeLuckEventDetail(String? eventId) async {
    if (eventId == null) return null;
    debugPrint(eventId);
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
          debugPrint(respuesta["last_event"]);
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

      final prefs = await SharedPreferences.getInstance();
      final hasInternet = _hasInternet;

      if (hasInternet) {
        try {
          // Try to fetch from Firebase
          final doc = await _firestore.collection('users').doc(user.uid).get().timeout(
            const Duration(seconds: 10),
          );
          if (doc.exists) {
            final data = doc.data();
            if (data != null && data.containsKey('stats')) {
              final stats = data['stats'] as Map<String, dynamic>;
              if (stats.containsKey('last_wish_me_luck')) {
                final date = (stats['last_wish_me_luck'] as Timestamp).toDate();
                
                // Update SharedPreferences with the fetched value
                await prefs.setString(
                  _lastWishedDateKey,
                  date.millisecondsSinceEpoch.toString(),
                );
                
                debugPrint('Fecha obtenida desde Firebase y guardada en caché');
                return date;
              }
            }
          }
        } catch (e) {
          debugPrint('Error al obtener desde Firebase, usando caché local: $e');
          // Update internet status
          _hasInternet = false;
        }
      } else {
        debugPrint('Sin conexión a internet, usando caché local');
      }

      // If no internet or Firebase fetch failed, get from SharedPreferences
      final cachedDateString = prefs.getString(_lastWishedDateKey);
      if (cachedDateString != null) {
        final milliseconds = int.tryParse(cachedDateString);
        if (milliseconds != null) {
          debugPrint('Fecha obtenida desde caché local');
          return DateTime.fromMillisecondsSinceEpoch(milliseconds);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error al obtener la última fecha: $e');
      return null;
    }
  }

  Future<void> setLastWishedDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final prefs = await SharedPreferences.getInstance();

      // Always save to SharedPreferences first
      await prefs.setString(
        _lastWishedDateKey,
        date.millisecondsSinceEpoch.toString(),
      );
      debugPrint('Fecha guardada en SharedPreferences');

      // Check internet and try to update Firebase if available
      if (_hasInternet) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'stats': {
              'last_wish_me_luck': Timestamp.fromDate(date),
            }
          }, SetOptions(merge: true)).timeout(
            const Duration(seconds: 10),
          );

          await _analytics.logWishMeLuckUsed(user.uid);
          
          // Clear pending sync if it exists
          await prefs.remove(_pendingSyncKey);
          debugPrint('Fecha sincronizada con Firebase exitosamente');
        } catch (e) {
          debugPrint('Error al sincronizar con Firebase: $e');
          
          // Update internet status
          _hasInternet = false;
          
          // Mark as pending sync
          await prefs.setString(_pendingSyncKey, date.millisecondsSinceEpoch.toString());
          debugPrint('Sin conexión real a Firebase. Datos guardados para sincronizar después');
        }
      } else {
        // Mark as pending sync
        await prefs.setString(_pendingSyncKey, date.millisecondsSinceEpoch.toString());
        debugPrint('Sin internet, fecha guardada localmente para sincronizar después');
      }
    } catch (e) {
      debugPrint('Error al establecer la última fecha: $e');
    }
  }

  Future<void> addEvents(List<Map<String, dynamic>> events) async {
    try {
      for (var event in events) {
        await _firestore.collection('events').add(event);
      }
      debugPrint('Todos los eventos se añadieron correctamente!');
    } catch (e) {
      debugPrint('Error al añadir eventos: $e');
    }
  }
}
