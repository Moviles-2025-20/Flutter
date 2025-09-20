import 'package:flutter/material.dart';
import 'notification.dart';
import 'detailEvent.dart';

class ListEvents extends StatelessWidget {
  const ListEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: const Text(
          "Events",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
              color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3C5BA9),
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
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Filter + Map view
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_alt_outlined,
                      color: Color(0xFFE3944F),
                      size: 30,),
                  label: const Text(
                    "Filter",
                    style: TextStyle(
                      color: Color(0xFFE3944F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text("Map view", style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold),),
                    // check according map view
                    Switch(
                      value: false,
                      onChanged: (val) {},
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Text(
              "Activities",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lista de eventos (scrollable)
            Expanded(
              child: ListView(
                children: const [
                  EventCard(
                    title: "Obra de teatro",
                    description:
                    "Vive la magia del teatro con una obra que te atrapará desde el primer acto.",
                    location: "El bobo",
                    time: "Tomorrow\n6:00 pm",
                    walkTime: "2 min",
                  ),
                  EventCard(
                    title: "TITLE",
                    description: "Description",
                    location: "Plaza Ll",
                    time: "Tomorrow\n9:00 pm",
                    walkTime: "5 min",
                  ),
                  EventCard(
                    title: "TITLE",
                    description: "Description",
                    location: "C Block",
                    time: "Monday\n2:00 pm",
                    walkTime: "4 min",
                  ),
                  EventCard(
                    title: "TITLE",
                    description: "Description",
                    location: "B Block",
                    time: "Monday\n4:00 pm",
                    walkTime: "2 min",
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Tarjeta de Evento
class EventCard extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final String time;
  final String walkTime;

  const EventCard({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    required this.time,
    required this.walkTime,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DetailEvent(),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 120,
                  child: Image.asset(
                    "assets/images/event.jpg",
                    fit: BoxFit.cover, // llena alto disponible sin dejar bordes
                  ),
                ),
              ),

              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título naranja
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3944F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Fila principal: descripción + detalles
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Descripción (ocupa lo que quede)
                          Expanded(
                            child: Text(
                              description,
                              maxLines: 6, // ajusta si quieres más/menos líneas
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Detalles a la derecha
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16),
                                  const SizedBox(width: 4),
                                  Text(location),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 4),
                                  Text(time),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_walk, size: 16),
                                  const SizedBox(width: 4),
                                  Text(walkTime),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
