import 'package:app_flutter/pages/events/view/event_detail_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_flutter/util/recommendation_service.dart';
import 'package:app_flutter/widgets/recommendation_card.dart';
import '../pages/events/model/event.dart' as EventsModel;
import '../util/firebase_service.dart';

class RecommendationsSection extends StatefulWidget {
  const RecommendationsSection({super.key});

  @override
  State<RecommendationsSection> createState() => _RecommendationsSectionState();
}

class _RecommendationsSectionState extends State<RecommendationsSection> {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final RecommendationsController _controller = RecommendationsController();
  
  Map<String, dynamic>? _recommendations;
  bool _isLoading = false;
  bool _hasInternet = true;
  String? _errorMessage;
  bool _showOnlineIndicator = false;

  @override
  void initState() {
    super.initState();
    _setupController();
    _loadRecommendations();
  }

  void _setupController() {
    // Listen to connectivity changes
    _controller.setOnConnectivityChanged((hasConnection) {
      if (!mounted) return;

      setState(() {
        _hasInternet = hasConnection;
      });

      if (hasConnection) {
        // Internet recovered
        _showTemporaryOnlineIndicator();
        _loadRecommendations();
      }
    });

    // Listen to recommendation updates (from background refresh)
    _controller.setOnRecommendationsUpdated((freshData) {
      if (!mounted) return;
      
      setState(() {
        _recommendations = freshData;
      });
      debugPrint('UI updated with fresh recommendations');
    });
  }

  void _showTemporaryOnlineIndicator() {
    setState(() => _showOnlineIndicator = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showOnlineIndicator = false);
    });
  }

  Future<void> _loadRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final recs = await _controller.getRecommendations(user.uid);
      
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoading = false;
          
          if (recs == null && !_hasInternet) {
            _errorMessage = 'No cached data available and no internet connection';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading recommendations';
        });
      }
      debugPrint('Error loading recommendations: $e');
    }
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
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Please log in to see recommendations."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with connectivity indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle(title: "What's best for you"),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Online indicator (appears temporarily when recovering)
                if (_showOnlineIndicator)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Back Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Refresh button
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: _hasInternet 
                        ? const Color(0xFF6389E2) 
                        : Colors.grey,
                  ),
                  tooltip: _hasInternet 
                      ? 'Refresh recommendations' 
                      : 'No internet connection',
                  onPressed: _hasInternet 
                      ? () => _loadRecommendations() 
                      : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Offline warning banner
        if (!_hasInternet)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off, size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No internet connection. Showing cached data.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Pending refreshes indicator
        if (_controller.pendingRefreshesCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_controller.pendingRefreshesCount} update(s) pending. Will sync when online.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Error message
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),

        // Loading state
        if (_isLoading)
          const Center(
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
          ),

        // No data state
        if (!_isLoading && _recommendations == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    _hasInternet ? Icons.inbox_outlined : Icons.wifi_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _hasInternet 
                        ? "No recommendations available"
                        : "No cached data available",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasInternet
                        ? "Check back later for personalized suggestions"
                        : "Please check your internet connection",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Success state - show recommendations
        if (!_isLoading && _recommendations != null)
          _buildRecommendationsList(),
      ],
    );
  }

  Widget _buildRecommendationsList() {
    final recs = _recommendations!["recommendations"] as List<dynamic>? ?? [];

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
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            
            if (eventSnapshot.hasError || eventSnapshot.data == null) {
              return const SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    "Event not available",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final event = eventSnapshot.data!;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: RecommendationCard(
                title: event.title,
                description: event.description,
                imagePath: event.metadata.imageUrl.isNotEmpty
                    ? event.metadata.imageUrl
                    : 'assets/images/events/event.jpg',
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
                      builder: (context) => DetailEvent(event: event),
                    ),
                  );
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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