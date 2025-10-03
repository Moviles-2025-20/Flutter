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
  List<Event> _sortedEvents = [];
  final int limit = 3; 


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
    
    List<Event> eventsToShow =
        _sortedEvents.isNotEmpty ? _sortedEvents : widget.events;

    _markers = eventsToShow.map((event) {
      if (event.location.coordinates.length < 2) return null;

      final lat = event.location.coordinates[0];
      final lng = event.location.coordinates[1];
      if (lat == 0 && lng == 0) return null;

      double? distanceKm;
      if (_userPosition != null) {
        distanceKm = Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          lat,
          lng,
        ) /
            1000;
      }

      return Marker(
        markerId: MarkerId(event.name),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: event.name,
          snippet: distanceKm != null
              ? '${event.location.city} - ${distanceKm.toStringAsFixed(1)} km'
              : event.location.city,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          event.isPositive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      );
    }).whereType<Marker>().toSet();

    // USER LOCATION
    if (_userPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: _userPosition!,
          infoWindow: const InfoWindow(title: "You are here"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
        //USER DISTANCE SORT - THIS MAKE TO SELECT THE NEAREST EVENTS
        _sortedEvents = List.from(widget.events);
        _sortedEvents.sort((a, b) {
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

        if (limit != null && limit > 0 && _sortedEvents.length > limit) {
          _sortedEvents = _sortedEvents.sublist(0, limit);
        }

        _createMarkers();
      });
    }
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