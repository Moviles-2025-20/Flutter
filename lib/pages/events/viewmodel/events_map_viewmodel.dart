import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../util/analytics_service.dart';

class EventsMapViewModel extends ChangeNotifier {
  // State
  Set<Marker> _markers = {};
  LatLng? _userPosition;
  List<Event> _events = [];
  List<Event> _sortedEvents = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasInternet = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Event? _selectedEvent;
  Event? get selectedEvent => _selectedEvent;

  void selectEvent(Event event) {
    _selectedEvent = event;
    notifyListeners();
  }

  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }


  // Configuration
  final int _maxEventsToShow = 5;
  final LatLng _defaultCenter = const LatLng(4.7110, -74.0721); // Bogotá

  // Getters
  Set<Marker> get markers => _markers;
  LatLng? get userPosition => _userPosition;
  List<Event> get sortedEvents => _sortedEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasInternet => _hasInternet;
  
  LatLng get mapCenter {
    if (_userPosition != null) return _userPosition!;
    if (_events.isNotEmpty && _events.first.location.coordinates.length >= 2) {
      return LatLng(
        _events.first.location.coordinates[0],
        _events.first.location.coordinates[1],
      );
    }
    return _defaultCenter;
  }

  EventsMapViewModel() {
    _startConnectivityListener();
  }

   void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      print("Connectivity changed: $result");
      
      if (result == ConnectivityResult.none) {

        print("No internet detected");
        _hasInternet = false;
        _errorMessage = 'No internet connection. Map is unavailable.';
        notifyListeners();
      } else {

        print("Connection detected, verifying...");
        final realConnection = await hasInternetConnection();
        
        if (realConnection && !_hasInternet) {

          print("Internet recovered!");
          _hasInternet = true;
          _errorMessage = null;
          _determinePosition();
          notifyListeners();
        } else if (!realConnection) {
          print("Connected but no real internet");
          _hasInternet = false;
          _errorMessage = 'No internet connection. Map is unavailable.';
          notifyListeners();
        }
      }
    });
  }

  // Check internet connection
    Future<bool> hasInternetConnection() async {
      try {
        
        // Check basic connectivity
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          return false;
        }

        // Verify real connection with timeout
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 3),
          onTimeout: () => [],
        );
        
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        print('Error checking internet: $e');
        return false;
      }
    }

  
  // Initialize with events
  void setEvents(List<Event> events) {
    _events = events;
    _createMarkers();
  }

  // Get user location and sort events
  Future<void> initializeLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {

      // Check internet first
      final internetAvailable = await hasInternetConnection();
      
      _hasInternet = internetAvailable;
      
      if (!internetAvailable) {
        _errorMessage = 'No internet connection. Map is unavailable.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final position = await _determinePosition();
      if (position != null) {
        _userPosition = LatLng(position.latitude, position.longitude);
        _sortEventsByDistance();
        _createMarkers();
      }
    } catch (e) {
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        _errorMessage = 'No internet connection. Unable to get location.';
      } else {
        _errorMessage = 'Problem when getting location.';
      }
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Determine user position
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Location services not enabled.';
      return null;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'User location denied';
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'User location denied permanently.';
      return null;
    }

    // Get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print("Error al obtener ubicación: $e");
      return null;
    }
  }

  // Sort events by distance from user
  void _sortEventsByDistance() {
    if (_userPosition == null) return;

    _sortedEvents = List.from(_events);
    _sortedEvents.sort((a, b) {
      if (a.location.coordinates.length < 2 || b.location.coordinates.length < 2) {
        return 0;
      }

      final aDist = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        a.location.coordinates[0],
        a.location.coordinates[1],
      );
      
      final bDist = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        b.location.coordinates[0],
        b.location.coordinates[1],
      );
      
      return aDist.compareTo(bDist);
    });

  }

  bool _isNearbyEvent(Event event) {
    if (_userPosition == null || _sortedEvents.isEmpty) return false;
    
    final index = _sortedEvents.indexOf(event);
    return index >= 0 && index < _maxEventsToShow;
  }

  // Calculate distance between two points
  double? calculateDistance(LatLng from, LatLng to) {
    try {
      final distanceInMeters = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );
      return distanceInMeters / 1000; // Convert to kilometers
    } catch (e) {
      print("Error calculating distance: $e");
      return null;
    }
  }

  // Create markers for map
  void _createMarkers() {
    final eventsToShow = _sortedEvents.isNotEmpty ? _sortedEvents : _events;
    
    _markers = eventsToShow.map((event) {
      if (event.location.coordinates.length < 2) return null;

      final lat = event.location.coordinates[0];
      final lng = event.location.coordinates[1];
      
      if (lat == 0 && lng == 0) return null;

      // Calculate distance if user position is available
      double? distanceKm;
      if (_userPosition != null) {
        distanceKm = calculateDistance(
          _userPosition!,
          LatLng(lat, lng),
        );
      }

      // Determinar si es un evento cercano
      final isNearby = _isNearbyEvent(event);

      return Marker(
        markerId: MarkerId(event.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: event.name,
          snippet: _buildMarkerSnippet(event, distanceKm, isNearby),
        ),
        icon: _getMarkerIcon(event, isNearby),
        onTap: () {
          selectEvent(event); // guarda el evento seleccionado
        },
      );
    }).whereType<Marker>().toSet();

    // Add user location marker
    if (_userPosition != null) {
      _markers.add(_createUserMarker());
    }
  }

  // Build marker snippet (subtitle)
  String _buildMarkerSnippet(Event event, double? distanceKm, bool isNearby) {
    final cityInfo = event.location.city;
    final distanceInfo = distanceKm != null 
        ? '${distanceKm.toStringAsFixed(1)} km' 
        : '';
    final nearbyTag = isNearby ? '🎯 Nearby' : '';
    
    final parts = [
      if (cityInfo.isNotEmpty) cityInfo,
      if (distanceInfo.isNotEmpty) distanceInfo,
      if (nearbyTag.isNotEmpty) nearbyTag,
    ];
    
    return parts.join(' • ');
  }

  // Get marker icon based on event rating and proximity
  BitmapDescriptor _getMarkerIcon(Event event, bool isNearby) {
    // Si es cercano, usar colores vibrantes/especiales
    if (isNearby) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  // Create user location marker
  Marker _createUserMarker() {
    return Marker(
      markerId: const MarkerId("user_location"),
      position: _userPosition!,
      infoWindow: const InfoWindow(
        title: "Your location",
        snippet: "You are here",
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  // Refresh markers when events change
  void refreshMarkers() {
    _createMarkers();
    notifyListeners();
  }

  // Update max events to show (actualizado para cambiar cantidad de cercanos)
  void updateNearbyEventsCount(int count) {
    // Esta función ahora cambia cuántos eventos se marcan como "cercanos"
    // pero sigue mostrando todos en el mapa
    if (count > 0 && _sortedEvents.isNotEmpty) {
      _createMarkers();
      notifyListeners();
    }
  }
  
  // Get list of nearby events (útil para mostrar en lista)
  List<Event> getNearbyEvents() {
    if (_sortedEvents.isEmpty) return [];
    final count = _sortedEvents.length < _maxEventsToShow 
        ? _sortedEvents.length 
        : _maxEventsToShow;
    return _sortedEvents.sublist(0, count);
  }

  Future<void> requestDirections(Event event, String userId) async {
      // Construir la query con nombre + ciudad/dirección si está disponible
      final parts = <String>[
        event.name,
        if (event.location.city?.isNotEmpty == true) event.location.city!,
        if (event.location.address?.isNotEmpty == true) event.location.address!,
      ];

      // Filtrar nulos/vacíos y unir con coma
      final queryText = parts
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .join(", ");

      // Encode para URL
      final query = Uri.encodeComponent(queryText);

      // Usar Google Maps Search con texto (sin coordenadas)
      final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

      // Log en Analytics (puedes renombrar si ya no son “directions”)
      await AnalyticsService().logDirectionsRequested(event.id, userId);

      // Abrir Google Maps
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print("No se pudo abrir Google Maps: $url");
      }
    }









    @override
  void dispose() {
    super.dispose();
  }
}