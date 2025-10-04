import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_flutter/pages/events/model/event.dart';

class EventsMapViewModel extends ChangeNotifier {
  // State
  Set<Marker> _markers = {};
  LatLng? _userPosition;
  List<Event> _events = [];
  List<Event> _sortedEvents = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Configuration
  final int _maxEventsToShow = 5;
  final LatLng _defaultCenter = const LatLng(4.7110, -74.0721); // Bogotá

  // Getters
  Set<Marker> get markers => _markers;
  LatLng? get userPosition => _userPosition;
  List<Event> get sortedEvents => _sortedEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
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
      final position = await _determinePosition();
      if (position != null) {
        _userPosition = LatLng(position.latitude, position.longitude);
        _sortEventsByDistance();
        _createMarkers();
      }
    } catch (e) {
      _errorMessage = 'Error al obtener ubicación: $e';
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
      _errorMessage = 'Los servicios de ubicación están desactivados';
      return null;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Permiso de ubicación denegado';
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'Permiso de ubicación denegado permanentemente';
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
    final nearbyTag = isNearby ? '🎯 Cercano' : '';
    
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
        title: "Tu ubicación",
        snippet: "Estás aquí",
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

  @override
  void dispose() {
    super.dispose();
  }
}