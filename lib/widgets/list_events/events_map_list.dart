import 'package:app_flutter/pages/events/model/event.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyEventsBottomSheet extends StatelessWidget {
  final List<Event> events;
  final LatLng? userPosition;
  final Function(Event) onEventTap;

  const NearbyEventsBottomSheet({
    Key? key,
    required this.events,
    required this.userPosition,
    required this.onEventTap,
  }) : super(key: key);

  String _getDistanceText(Event event) {
    if (userPosition == null || event.location.coordinates.length < 2) {
      return '';
    }

    final distanceInMeters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      event.location.coordinates[0],
      event.location.coordinates[1],
    );

    final distanceKm = distanceInMeters / 1000;
    
    if (distanceKm < 1) {
      return '${distanceInMeters.toInt()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            color: Colors.white,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: const Color(0xFFE3944F)),
                      const SizedBox(width: 8),
                      const Text(
                        'Nearby Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text('${events.length}', style:TextStyle(color:Color(0xFFE3944F), fontWeight: FontWeight.bold)),
                        backgroundColor: const Color.fromARGB(46, 227, 148, 79),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Events list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: events.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final distance = _getDistanceText(event);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => onEventTap(event),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Rank badge
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color:  const Color(0xFFE3944F),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Event info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_city,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.location.city,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (distance.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(71, 227, 148, 79),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                distance,
                                                style: TextStyle(
                                                  color: const Color(0xFFE3944F),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (event.metadata.tags.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          children: event.metadata.tags
                                              .take(2)
                                              .map((tag) => Chip(
                                                    label: Text(
                                                      tag,
                                                      style: const TextStyle(fontSize: 10),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize.shrinkWrap,
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // Distance
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    
                                    const SizedBox(height: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}