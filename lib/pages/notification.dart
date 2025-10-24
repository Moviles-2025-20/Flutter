import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6389E2),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                NotificationCard(
                  avatar: Icons.person,
                  text:
                      "Paolo has added you as a friend! Plan your first get together.",
                ),
                NotificationCard(
                  avatar: Icons.person,
                  text:
                      "Paolo invited you to an event! Click to see all the details.",
                ),
                NotificationCard(
                  image:
                      "https://picsum.photos/200/100", 
                  text:
                      "An event that you may like was added near you! Check it out.",
                ),
                NotificationCard(
                  image: "https://picsum.photos/200/101",
                  text:
                      "The event you saved is starting soon! Get there on time.",
                ),
                NotificationCard(
                  avatar: Icons.person,
                  text:
                      "Paolo has a free period at noon, do you want to plan an activity?",
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE76F6F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  "Manage push notifications",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String? image;
  final IconData? avatar;
  final String text;

  const NotificationCard({
    super.key,
    this.image,
    this.avatar,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (avatar != null)
              CircleAvatar(
                radius: 24,
                child: Icon(avatar, size: 28),
              )
            else if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(image!, width: 48, height: 48, fit: BoxFit.cover),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
