import 'package:flutter/material.dart';
import 'package:app_flutter/pages/events/model/event.dart';
import 'package:app_flutter/pages/events/model/comment.dart';
import 'package:app_flutter/util/comment_service.dart';
import 'package:app_flutter/pages/events/view/make_comment_view.dart';

class DetailEvent extends StatefulWidget {
  final Event event;

  const DetailEvent({super.key, required this.event});

  @override
  State<DetailEvent> createState() => _DetailEventState();
}

class _DetailEventState extends State<DetailEvent> {
  final CommentService _commentService = CommentService();
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _commentService.getCommentsForEvent(widget.event.id);
  }

  void _refreshComments() {
    setState(() {
      _commentsFuture = _commentService.getCommentsForEvent(widget.event.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      appBar: AppBar(
        title: const Text(
          "Event Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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


            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MakeCommentPage(eventId: widget.event.id),
                  ),
                );
                _refreshComments();
              },
              child: const Text("Make a Comment"),
            ),

            // Asisted check-in button
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Implement check-in logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Checked in successfully!")),
                );
              },
              child: const Text("Check In"),
            ),

            const Divider(),
            _buildRatingSection(),

            const SizedBox(height: 16),
            const Divider(),

            const Text("Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

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
                  children: comments.map((c) {
                    return _buildComment(
                      c.metadata.imageUrl.isNotEmpty
                          ? c.metadata.imageUrl
                          : "assets/images/Perfil2.jpg", 
                      c.user_id, 
                      c.created.toString(),
                      c.metadata.text,
                    );
                  }).toList(),
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
                  Image.asset("assets/images/event.jpg", height: 180),
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
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(widget.event.location.address),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(widget.event.schedule.times.isNotEmpty
                        ? widget.event.schedule.times.first
                        : ""),
                  ],
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
      // 🔸 Parte izquierda (score + estrellas + reviews)
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
                      minHeight: 6, // grosor de la barra
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

Widget _buildComment(
    String avatar, String name, String date, String comment) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(backgroundImage: AssetImage(avatar)),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔸 Encabezado naranja con nombre + fecha
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 🔸 Texto del comentario
              Text(
                comment,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      )
    ],
  );
}
}
