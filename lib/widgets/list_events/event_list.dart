import 'package:app_flutter/pages/events/view/event_detail_view.dart';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/viewmodel/event_list_view_model.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final AnalyticsService _analytics = AnalyticsService();
    return InkWell(
      onTap: () async {
        await _analytics.logDiscoveryMethod(DiscoveryMethod.manualBrowse);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailEvent(event: event),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventImage(
              imageUrl: event.metadata.imageUrl,
              category: event.category,
              width: 120,
            ),

              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título naranja
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3944F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Fila principal: descripción + detalles
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Descripción (ocupa lo que quede)
                          Flexible(
                            child: Text(
                              event.description,
                              maxLines: 6, // ajusta si quieres más/menos líneas
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Detalles a la derecha
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.25, // ajusta este valor según el diseño de tu card
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.location.address,
                                        maxLines:2,
                                        overflow: TextOverflow.ellipsis, // corta con "..." si es muy largo
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.access_time, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.schedule.times.join(', '),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.category, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.category,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


class EventImage extends StatelessWidget {
  final String imageUrl;
  final String category;
  final double width;

  const EventImage({
    Key? key,
    required this.imageUrl,
    required this.category,
    this.width = 120,
  }) : super(key: key);

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: SizedBox(
        width: width,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Intenta cargar imagen de categoría
            final categoryImagePath = "assets/images/events/$category.jpg";
            
            return FutureBuilder<bool>(
              future: _assetExists(categoryImagePath),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  // Existe la imagen de categoría
                  return Image.asset(
                    categoryImagePath,
                    fit: BoxFit.cover,
                  );
                } else {
                  // No existe, usar imagen por defecto
                  return Image.asset(
                    "assets/images/events/event.jpg",
                    fit: BoxFit.cover,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
