import 'package:app_flutter/pages/events/view/event_detail_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_flutter/util/recommendation_service.dart';
import 'package:app_flutter/widgets/recommendation_card.dart';

import '../pages/events/model/event.dart' as EventsModel;
import '../util/firebase_service.dart';

class RecommendationsSection extends StatelessWidget {
  RecommendationsSection({super.key});
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  Future<EventsModel.Event?> _getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;
      return EventsModel.Event.fromJson(doc.id, data);
    } catch (e) {
      debugPrint("Error fetching event: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Text("Please log in to see recommendations.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "What's best for you"),
        const SizedBox(height: 10),
        FutureBuilder<Map<String, dynamic>?>(
          future: RecommendationService().getRecommendations(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || snapshot.data == null) {
              return const Text("No recommendations available.");
            } else {
              final recs = snapshot.data!["recommendations"] as List<dynamic>;
              if (recs.isEmpty) {
                return const Text("No recommendations available.");
              }

              return Column(
                children: recs.map((rec) {
                  final eventId = rec["id"] as String;
                  return FutureBuilder<EventsModel.Event?>(
                    future: _getEventById(eventId),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (eventSnapshot.hasError || eventSnapshot.data == null) {
                        return const SizedBox(
                          height: 100,
                          child: Center(child: Text("Event not available")),
                        );
                      } else {
                        final event = eventSnapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0), // separación
                          child: RecommendationCard(
                            title: event.title,
                            description: event.description,
                            imagePath: event.metadata.imageUrl.isNotEmpty
                                ? event.metadata.imageUrl
                                : 'assets/images/event.jpg',
                            day: event.schedule.days.isNotEmpty
                                ? event.schedule.days.join(", ")
                                : null,
                            time: event.schedule.times.isNotEmpty
                                ? event.schedule.times.join(", ")
                                : null,
                            duration: event.durationFormatted,
                            location: event.location.address,
                            tagColor: const Color(0xFF6389E2),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailEvent( event : event),
                                ),
                              );
                            },
                          ),


                        );
                      }
                    },
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
