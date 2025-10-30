import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final String? time;
  final String? day;
  final String? duration;
  final String? location;
  final Color tagColor;
  final VoidCallback onTap;

  const RecommendationCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.time,
    this.day,
    this.duration,
    this.location,
    required this.tagColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra superior con título
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(
              height: 150,
              child: Row(
                children: [
                  // Imagen - 35%
                  Expanded(
                    flex: 35,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image(
                        image: imagePath.startsWith('http')
                            ? NetworkImage(imagePath)
                            : AssetImage(imagePath) as ImageProvider,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/event.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                      ),
                    ),
                  ),
                  // Contenido - 65%
                  Expanded(
                    flex: 65,
                    child: _CardContent(
                      description: description,
                      time: time,
                      day: day,
                      duration: duration,
                      location: location,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final String description;
  final String? time;
  final String? day;
  final String? duration;
  final String? location;

  const _CardContent({
    required this.description,
    this.time,
    this.day,
    this.duration,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🔥 evita overflow
        children: [
          // Descripción
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Ubicación debajo de la descripción
          if (location != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          // Día, hora y duración
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (day != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(day!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              if (time != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(time!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              if (duration != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(duration!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
