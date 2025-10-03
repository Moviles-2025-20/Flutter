import 'package:app_flutter/pages/events/model/event.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class EventsMapView extends StatefulWidget {
  final List<Event> events;

  const EventsMapView({Key? key, required this.events}) : super(key: key);

  @override
  State<EventsMapView> createState() => _EventsMapViewState();
}

class _EventsMapViewState extends State<EventsMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  // USER LOCATION
  LatLng? _userPosition;


  @override
  void initState() {
    super.initState();
    _determinePosition();
    _createMarkers();
    
  }

  @override
  void didUpdateWidget(EventsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    _markers = widget.events.map((event) {
      // Validar coordenadas
      if (event.location.coordinates.length < 2) {
        return null;
      }
      
      final lat = event.location.coordinates[0];
      final lng = event.location.coordinates[1];
      
      if (lat == 0 && lng == 0) {
        return null;
      }

      return Marker(
        markerId: MarkerId(event.name),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: event.name,
          snippet: '${event.location.city} - ${event.stats.rating}⭐',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          event.isPositive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      );
    }).whereType<Marker>().toSet();

    if (_userPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: _userPosition!,
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    if (mounted) setState(() {});
  }


  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // GPS active
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current location
    final position = await Geolocator.getCurrentPosition().catchError((e) {
  print("Error al obtener ubicación: $e");
  return null;
});

if (position != null) {
  setState(() {
    _userPosition = LatLng(position.latitude, position.longitude);
    _createMarkers();
  });
} else {
  print("No se pudo obtener ubicación, usando fallback Bogotá.");
}
    setState(() {
      _userPosition = LatLng(position.latitude, position.longitude);
      _createMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcular centro del mapa
    final LatLng center = _userPosition ??
        (widget.events.isNotEmpty
            ? LatLng(
                widget.events.first.location.coordinates[0],
                widget.events.first.location.coordinates[1],
              )
            : const LatLng(4.7110, -74.0721)); // Bogotá por defecto

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 12,
      ),
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}