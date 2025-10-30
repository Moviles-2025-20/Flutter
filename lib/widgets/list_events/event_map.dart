import 'package:app_flutter/pages/events/view/event_detail_view.dart';
import 'package:app_flutter/widgets/list_events/events_map_list.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/viewmodel/events_map_viewmodel.dart';

class EventsMapView extends StatefulWidget {
  final List<Event> events;
  
  const EventsMapView({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  State<EventsMapView> createState() => _EventsMapViewState();
}

class _EventsMapViewState extends State<EventsMapView> {
  GoogleMapController? _mapController;
  late EventsMapViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EventsMapViewModel();
    _viewModel.setEvents(widget.events);
    _viewModel.initializeLocation();
  }

  @override
  void didUpdateWidget(EventsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _viewModel.setEvents(widget.events);
    }
  }

  Future<void> _retryLoadLocation() async {
    await _viewModel.initializeLocation();
  }

  bool _isNoInternetError() {
    final error = _viewModel.errorMessage?.toLowerCase() ?? '';
    return error.contains('internet') || error.contains('connection');
  }

  
  void _showNearbyEventsBottomSheet() {
    final nearbyEvents = _viewModel.getNearbyEvents();
    
    if (nearbyEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There are no events available.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:  Colors.transparent,
      builder: (context) => NearbyEventsBottomSheet(
        events: nearbyEvents,
        userPosition: _viewModel.userPosition,
        onEventTap: (event) {
          Navigator.pop(context); // close the bottom sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailEvent(event: event),
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<EventsMapViewModel>(
        builder: (context, viewModel, child) {

        if (viewModel.errorMessage != null) {
          return Container(
            color: Colors.transparent,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isNoInternetError() ? Icons.wifi_off : Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _retryLoadLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }


          return Scaffold(
            body: Stack(
              children: [
                // Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: viewModel.mapCenter,
                    zoom: 12,
                  ),
                  markers: viewModel.markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                ),
                
                // Loading indicator
                if (viewModel.isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        margin: EdgeInsets.all(24),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Loading location...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Error message with retry button
               
              ],
            ),
            // Floating Action Button
            floatingActionButton: viewModel.userPosition != null
                ? FloatingActionButton.extended(
                    onPressed: _showNearbyEventsBottomSheet,
                    icon: const Icon(Icons.near_me, color: Colors.white),
                    label: const Text('Eventos cercanos', style: TextStyle(fontSize: 16, color: Colors.white)),
                    backgroundColor: Colors.pink.shade400,
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}