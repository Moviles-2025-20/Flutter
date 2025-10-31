
import 'package:app_flutter/pages/FreeTime/viewmodel/free_time_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/pages/notification.dart';
import 'package:intl/intl.dart';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/view/event_detail_view.dart';





class FreeTimeView extends StatelessWidget {
  final String userId;

  const FreeTimeView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FreeTimeViewModel()..loadAvailableEvents(userId),
      child: const FreeTimeEventsListContent(),
    );
  }
}

class FreeTimeEventsListContent extends StatelessWidget {
  const FreeTimeEventsListContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FreeTimeViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          "Available Events",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6389E2),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(child: Text(viewModel.error!));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- FREE TIME SLOTS ---
              const Text(
                "Your Free Time",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...viewModel.freeTimeSlots.map((slot) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        slot.day,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        "${DateFormat.Hm().format(slot.startTime)
                        } - ${DateFormat.Hm().format(slot.endTime)
                        }",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              // --- HEADER DE EVENTS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Events That Fit Your Schedule",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${viewModel.availableEvents.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- LISTA DE EVENTOS ---
              if (viewModel.availableEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Center(
                    child: Text(
                      "There are no available events during your free time slots",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else

                ...viewModel.availableEvents.map(
                      (event) => EventCard(event: event),
                ),
            ],
          );
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
    final startStr = event.schedule.times.isNotEmpty ? event.schedule.times.first : "00:00";
    final startTime = DateFormat.Hm().parse(startStr);
    final endTime = startTime.add(Duration(minutes: event.metadata.durationMinutes));

    return InkWell(
      onTap: () async {
        final viewModel = context.read<FreeTimeViewModel>();

        // Abrir diálogo de carga y obtener el BuildContext correcto
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            // Guardamos el context del diálogo para poder cerrarlo después
            return const Center(child: CircularProgressIndicator());
          },
        );

        try {
          final fetchedEvent = await viewModel.getEventById(event.id);

          // Cerrar diálogo de carga
          Navigator.of(context, rootNavigator: true).pop();

          if (fetchedEvent != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailEvent(event: fetchedEvent),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Event not found")),
            );
          }
        } catch (e) {
          // En caso de error, cerrar diálogo y mostrar mensaje
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading event: $e")),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                event.metadata.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    "assets/images/event.jpg",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.address,
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${startTime.hour.toString().padLeft(2,'0')}:${startTime.minute.toString().padLeft(2,'0')} - "
                            "${endTime.hour.toString().padLeft(2,'0')}:${endTime.minute.toString().padLeft(2,'0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.category,
                        style: const TextStyle(color: Colors.grey),
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

