import 'package:app_flutter/pages/events/model/event.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EventsMapView extends StatefulWidget {
  final List<Event> events;

  const EventsMapView({Key? key, required this.events}) : super(key: key);

  @override
  State<EventsMapView> createState() => _EventsMapViewState();
}

class _EventsMapViewState extends State<EventsMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
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

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Calcular centro del mapa
    final LatLng center = widget.events.isNotEmpty
        ? LatLng(
            widget.events.first.location.coordinates[0],
            widget.events.first.location.coordinates[1],
          )
        : const LatLng(4.7110, -74.0721); // Bogotá por defecto

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