import 'package:flutter/material.dart';
import 'package:app_flutter/widgets/comment/comment.dart';

class DetailEvent extends StatelessWidget {
  const DetailEvent({super.key});

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
            // 🔍 Search bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_alt_outlined,
                      color: Colors.orange),
                  label: const Text("Filter",
                      style: TextStyle(color: Colors.orange)),
                ),
                Row(
                  children: [
                    const Text("Map view"),
                    Switch(value: false, onChanged: (_) {}),
                  ],
                )
              ],
            ),


            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      "assets/images/event.jpg",
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Chip(
                          label: Text("Food Fest"),
                          backgroundColor: Colors.orangeAccent,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 16),
                            SizedBox(width: 4),
                            Text("El bobo"),
                            SizedBox(width: 16),
                            Icon(Icons.access_time, size: 16),
                            SizedBox(width: 4),
                            Text("Hoy 6:00 pm"),
                            SizedBox(width: 16),
                            Icon(Icons.directions_walk, size: 16),
                            SizedBox(width: 4),
                            Text("2 min "),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "In Centro de Japón, there is an Asian food festival "
                          "where you can try typical dishes from different "
                          "countries, sharing flavors and traditions in one place.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MakeCommentPage(eventId: "UecLLDMASUwqsFPh8zTa",)),
                );
              },
              child: const Text("Make a Comment"),
            ),

            const Divider(),
            _buildRatingSection(),

            const SizedBox(height: 16),
            const Divider(),
            const Text("Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildComment(
              "assets/images/Perfil2.jpg",
              "Sofia Garcia",
              "2 days ago",
              "The site has an amazing view and the activity was truly exciting! I had a great time and the food was amazing.",
            ),
            const SizedBox(height: 8),
            _buildComment(
              "assets/images/Perfil3.jpg",
              "Maria Linares",
              "5 days ago",
              "The food festival was fantastic, a great way to explore different cultures.",
            ),
          ],
        ),
      ),
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

}
