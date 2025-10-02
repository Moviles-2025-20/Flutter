import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/viewmodel/event_list_view_model.dart';
import 'package:flutter/material.dart';

class EventsListView extends StatelessWidget {
  final List<Event> events;
  final EventsViewModel viewModel;

  const EventsListView({
    Key? key,
    required this.events,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (viewModel.filters.hasActiveFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: viewModel.clearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return EventCard(event: events[index]);
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navegar a detalles del evento
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (event.metadata.imageUrl.isNotEmpty && event.metadata.imageUrl != 'TEST')
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  event.metadata.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: const Color(0xFF6389E2).withValues(alpha: 0.1),
                    child: const Icon(Icons.event, size: 50),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event types
                  if (event.eventType.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: event.eventType
                          .take(2)
                          .map((type) => Chip(
                                label: Text(type, style: const TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Location and rating
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.city,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        event.stats.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}