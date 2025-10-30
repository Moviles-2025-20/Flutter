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
  final controller = RecommendationsController();

  void Function(Map<String, dynamic>)? _onRecommendationsUpdated;

  void setOnRecommendationsUpdated(void Function(Map<String, dynamic>) callback) {
    _onRecommendationsUpdated = callback;
  }

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
          future: controller.getRecommendations(user.uid),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading recommendations...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Error loading recommendations",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // No data state
            if (snapshot.data == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No recommendations available",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Check your Internet Connection.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Success state
            final recs = snapshot.data!["recommendations"] as List<dynamic>;
            
            if (recs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.recommend_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No recommendations yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Check back later for personalized suggestions",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
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
          )
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
