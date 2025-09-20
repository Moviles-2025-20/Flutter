import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final String? time;
  final String? duration;
  final String? location;

  const RecommendationCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.time,
    this.duration,
    this.location,
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
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _CardImage(
              imagePath: imagePath,
              title: title,
            ),
            _CardContent(
              description: description,
              time: time,
              duration: duration,
              location: location,
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

  const _CardImage({
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
                if (!showLocationInfo && time != null) ...[
                  SizedBox(height: 8),
                  _TimeInfo(time: time!, duration: duration),
                ],
              ],
            ),
          ),
          if (showLocationInfo) ...[
            SizedBox(width: 10),
            _LocationInfo(location: location, time: time),
          ],
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
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (duration != null) ...[
          SizedBox(width: 15),
          Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            duration!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final String? location;
  final String? time;

  const _LocationInfo({this.location, this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
        if (location != null)
          Text(
            location!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        if (time != null)
          Text(
            time!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
}