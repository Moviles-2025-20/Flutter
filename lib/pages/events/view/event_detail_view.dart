import 'package:flutter/material.dart';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/comment.dart';
import 'package:app_flutter/util/comment_service.dart';
import 'package:app_flutter/util/user_activity_service.dart';
import 'package:app_flutter/pages/events/view/make_comment_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../util/analytics_service.dart';

class DetailEvent extends StatefulWidget {
  final Event event;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DetailEvent({super.key, required this.event});
  

  @override
  State<DetailEvent> createState() => _DetailEventState();
}

class _DetailEventState extends State<DetailEvent> {
  final CommentService _commentService = CommentService();
  final AnalyticsService _analytics = AnalyticsService();
  late Future<List<Comment>> _commentsFuture;
  final UserActivityService _userActivityService = UserActivityService();
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _commentService.loadComments(widget.event.id);
    print(_commentsFuture);
    _loadCheckIn();
  }

  void _loadCheckIn() async {
    final userId = widget._auth.currentUser?.uid;
    final existing = await _userActivityService.getCheckIn(userId!, widget.event.id);
    setState(() {
      _isCheckedIn = existing != null;
    });
  }

    void _toggleCheckIn() async {
      await _userActivityService.toggleCheckIn(widget.event.id, widget.event.category);
      print(widget.event.id);
      print(widget.event.category);
      await _analytics.logCheckIn(widget.event.id, widget.event.category);
      _loadCheckIn();
  }

  void _refreshComments() {
    setState(() {
      _commentsFuture = _commentService.loadComments(widget.event.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: const Text(
          "Event Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6389E2),
        actions: const [
          Icon(Icons.notifications_none),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventCard(),
            const SizedBox(height: 16),



            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MakeCommentPage(eventId: widget.event.id),
                          
                        ),
                      );
                      _refreshComments();
                    },
                    child: const Text("Make a Comment"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCheckedIn ? Colors.green : Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _toggleCheckIn();
                    },
                    child: const Text("Check In"),
                  ),
                ),
              ],
            ),

            const Divider(),
            _buildRatingSection(),
            const SizedBox(height: 16),
            const Divider(),

            const Text(
              "Comments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            //  FutureBuilder de comentarios
            FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No comments yet. Be the first!");
                }

                final comments = snapshot.data!;
                return Column(
                  children: comments.map((c) => _buildCommentCard(c)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEventCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              widget.event.metadata.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.asset("assets/images/events/event.jpg", height: 180),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(widget.event.title),
                  backgroundColor: Colors.orangeAccent,
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.place_outlined, size: 16),
                        SizedBox(width: 4),
                      ],
                    ),
                    SizedBox(
                      width: 200,
                      child: Text(
                        widget.event.location.address,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.access_time, size: 16),
                        SizedBox(width: 4),
                      ],
                    ),
                    Text(
                      widget.event.schedule.times.isNotEmpty
                          ? widget.event.schedule.times.first
                          : "",
                    ),
                  ]
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }


  Widget _buildRatingSection() {
    final percentages = [0.40, 0.30, 0.15, 0.10, 0.05];
    final labels = [5, 4, 3, 2, 1];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "4.5",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 20),
                Icon(Icons.star, color: Colors.orange, size: 20),
                Icon(Icons.star, color: Colors.orange, size: 20),
                Icon(Icons.star, color: Colors.orange, size: 20),
                Icon(Icons.star_border, color: Colors.orange, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            const Text("125 reviews"),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(labels[i].toString(),
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentages[i],
                        color: Colors.orange,
                        backgroundColor: Colors.grey[300],
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("${(percentages[i] * 100).toInt()}%",
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }


  Widget _buildCommentCard(Comment comment) {
    final formattedDate =
        DateFormat('MMM d, yyyy • hh:mm a').format(comment.created);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(comment.avatar.isNotEmpty
                        ? comment.avatar
                        : 'assets/images/avatar_placeholder.png'),
                    radius: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.userName.isNotEmpty
                        ? "${comment.userName.substring(0, 10)}..."
                        : "Anonymous",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            comment.description.isNotEmpty
                ? comment.description
                : "No description provided.",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
           if (comment.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                comment.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
