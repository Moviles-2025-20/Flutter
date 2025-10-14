import 'package:app_flutter/pages/weekly/viewmodel/weekly_challenge_view_model.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_flutter/util/user_activity_service.dart';


class WeeklyChallengeView extends StatefulWidget {
  final AnalyticsService _analytics = AnalyticsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  

  WeeklyChallengeView({Key? key}) : super(key: key);

  @override
  State<WeeklyChallengeView> createState() => _WeeklyChallengeViewState();
}

class _WeeklyChallengeViewState extends State<WeeklyChallengeView> {
  final TextEditingController _commentController = TextEditingController();
  final UserActivityService _userActivityService = UserActivityService();
  bool _isCheckedIn = false;
  int _completedCount = 0;
  bool _isLoadingStats = true;
  

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final viewModel = Provider.of<WeeklyChallengeViewModel>(context, listen: false);
    viewModel.loadWeeklyChallenge();
    viewModel.loadUserWeeklyChallengeStats();

  });
}

void _loadCheckIn(event) async {
    final userId = widget._auth.currentUser?.uid;
    final existing = await _userActivityService.getCheckIn(userId!, event.id);
    setState(() {
      _isCheckedIn = existing != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyChallengeViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (viewModel.errorMessage != null) {
          return Scaffold(
              backgroundColor: const Color(0xFFFEFAED),
            appBar: AppBar(
              title: const Text("Weekly Challenge"),
              backgroundColor: const Color(0xFF6389E2),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    "An error occurred while loading events",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.loadWeeklyChallenge();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    
                  ),
                ],
              ),
            ),
          );
        }

        final event = viewModel.weeklyEvent;
        _loadCheckIn(event);
        if (event == null) {
          return const Scaffold(
            body: Center(child: Text("No weekly challenge found")),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFEFAED),
          appBar: AppBar(
            title: const Text("Weekly Challenge"),
            backgroundColor: const Color(0xFF6389E2),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del evento
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    event.metadata.imageUrl.isNotEmpty
                        ? event.metadata.imageUrl
                        : 'https://via.placeholder.com/300x200',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  event.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 4),
                    Text(event.durationFormatted),
                    const SizedBox(width: 12),
                    const Icon(Icons.monetization_on, size: 18),
                    const SizedBox(width: 4),
                    Text(event.formattedCost),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),

                
                viewModel.isLoadingStats
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6389E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insights, color: Color(0xFF6389E2)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "You’ve completed ${viewModel.completedCount} weekly challenges in the last 30 days.",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 20),
                const Divider(),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCheckedIn ? Colors.green : Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {

                        await widget._analytics.logWeeklyChallengeCompleted(user.uid, event.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Challenge marked as completed!")),
                        );
                        _loadCheckIn(event);
                        viewModel.loadUserWeeklyChallengeStats();
                      }
                    },

                    child: const Text("Mark as Completed"),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  "Comments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (viewModel.comments.isEmpty)
                  const Text("No comments yet. Be the first!"),
                ...viewModel.comments.map((c) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(c.userName),
                      subtitle: Text(c.description),
                    )),

                const SizedBox(height: 12),
                
              ],
            ),
          ),
        );
      },
    );
  }
}
