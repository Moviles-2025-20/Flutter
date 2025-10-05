import 'package:app_flutter/pages/weekly/viewmodel/weekly_challenge_view_model.dart';
import 'package:app_flutter/util/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class WeeklyChallengeView extends StatefulWidget {
  final AnalyticsService _analytics = AnalyticsService();
  WeeklyChallengeView({Key? key}) : super(key: key);

  @override
  State<WeeklyChallengeView> createState() => _WeeklyChallengeViewState();
}

class _WeeklyChallengeViewState extends State<WeeklyChallengeView> {
  final TextEditingController _commentController = TextEditingController();

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final viewModel = Provider.of<WeeklyChallengeViewModel>(context, listen: false);
    viewModel.loadWeeklyChallenge();
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
            body: Center(child: Text(viewModel.errorMessage!)),
          );
        }

        final event = viewModel.weeklyEvent;
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
                ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await widget._analytics.logWeeklyChallengeCompleted(user.uid, event.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Challenge marked as completed!")),
                        );
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
