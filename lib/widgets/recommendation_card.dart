import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final String? time;
  final String? duration;
  final String? location;
  final Color tagColor;
  final bool showLocationInfo;
  final VoidCallback onTap;

  const RecommendationCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.time,
    this.duration,
    this.location,
    required this.tagColor,
    this.showLocationInfo = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [

            SizedBox(
              height: 150, 
              child: Row(
                children: [
                  // Imagen - 35% del ancho
                  Expanded(
                    flex: 35,
                    child: _CardImage(
                      imagePath: imagePath,
                      title: title,
                      tagColor: tagColor,
                    ),
                  ),
                  // Contenido - 65% del ancho
                  Expanded(
                    flex: 65,
                    child: _CardContent(
                      description: description,
                      time: time,
                      duration: duration,
                      location: location,
                      showLocationInfo: showLocationInfo,
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

class _CardImage extends StatelessWidget {
  final String imagePath;
  final String title;
  final Color tagColor;

  const _CardImage({
    required this.imagePath,
    required this.title,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Tag posicionado en la esquina superior izquierda
          Positioned(
            top: 8,
            left: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final String description;
  final String? time;
  final String? duration;
  final String? location;
  final bool showLocationInfo;

  const _CardContent({
    required this.description,
    this.time,
    this.duration,
    this.location,
    required this.showLocationInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Descripción en la parte superior
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Información de tiempo/ubicación en la parte inferior
          if (showLocationInfo)
            _LocationInfoHorizontal(location: location, time: time)
          else if (time != null)
            _TimeInfo(time: time!, duration: duration),
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String time;
  final String? duration;

  const _TimeInfo({required this.time, this.duration});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey[800]),
            SizedBox(width: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        if (duration != null) ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[800]),
              SizedBox(width: 4),
              Text(
                duration!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LocationInfoHorizontal extends StatelessWidget {
  final String? location;
  final String? time;

  const _LocationInfoHorizontal({this.location, this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.grey[800]),
        SizedBox(width: 4),
        if (location != null)
          Text(
            location!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
            ),
          ),
        if (location != null && time != null) 
          Text(" • ", style: TextStyle(color: Colors.grey[800])),
        if (time != null)
          Text(
            time!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
            ),
          ),
      ],
    );
  }
}

