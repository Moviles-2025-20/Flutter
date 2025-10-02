
import 'package:cloud_firestore/cloud_firestore.dart';

class EventLocation {
  final String city;
  final String type;
  final String address;
  final List<double> coordinates;

  EventLocation({
    required this.city,
    required this.type,
    required this.address,
    required this.coordinates,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      city: json['city'] ?? '',
      type: json['type'] ?? '',
      address: json['address'] ?? '',
      coordinates: json['coordinates'] != null
          ? List<double>.from(json['coordinates'])
          : [0.0, 0.0],
    );
  }
}

class EventMetadata {
  final String imageUrl;
  final List<String> tags;
  final int durationMinutes;
  final String cost;

  EventMetadata({
    required this.imageUrl,
    required this.tags,
    required this.durationMinutes,
    required this.cost,
  });

  factory EventMetadata.fromJson(Map<String, dynamic> json) {
    return EventMetadata(
      imageUrl: json['image_url'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      durationMinutes: json['duration_minutes'] ?? 0,
      cost: json['cost'] ?? '',
    );
  }
}

class EventSchedule {
  final List<String> days;
  final List<String> times;

  EventSchedule({
    required this.days,
    required this.times,
  });

  factory EventSchedule.fromJson(Map<String, dynamic> json) {
    return EventSchedule(
      days: json['days'] != null ? List<String>.from(json['days']) : [],
      times: json['times'] != null ? List<String>.from(json['times']) : [],
    );
  }
}

class EventStats {
  final int popularity;
  final int totalCompletions;
  final double rating;

  EventStats({
    required this.popularity,
    required this.totalCompletions,
    required this.rating,
  });

  factory EventStats.fromJson(Map<String, dynamic> json) {
    return EventStats(
      popularity: json['popularity'] ?? 0,
      totalCompletions: json['total_completions'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}

class Event {
  final String id;
  final List<String> eventType;
  final bool active;
  final String category;
  final DateTime created;
  final String description;
  final EventLocation location;
  final EventMetadata metadata;
  final String name;
  final EventSchedule schedule;
  final EventStats stats;
  final String title;
  final String type;
  final bool weatherDependent;

  Event({
    required this.id,
    required this.eventType,
    required this.active,
    required this.category,
    required this.created,
    required this.description,
    required this.location,
    required this.metadata,
    required this.name,
    required this.schedule,
    required this.stats,
    required this.title,
    required this.type,
    required this.weatherDependent,
  });

  factory Event.fromJson(String id, Map<String, dynamic> json) {
    return Event(
      id: id,
      eventType: json['EventType'] != null 
          ? List<String>.from(json['EventType']) 
          : [],
      active: json['active'] ?? false,
      category: json['category'] ?? '',
      created: json['created'] != null
          ? (json['created'] is String 
              ? DateTime.parse(json['created'])
              : (json['created'] as Timestamp).toDate())
          : DateTime.now(),
      description: json['description'] ?? '',
      location: EventLocation.fromJson(json['location'] ?? {}),
      metadata: EventMetadata.fromJson(json['metadata'] ?? {}),
      name: json['name'] ?? '',
      schedule: EventSchedule.fromJson(json['schedule'] ?? {}),
      stats: EventStats.fromJson(json['stats'] ?? {}),
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      weatherDependent: json['weather_dependent'] ?? false,
    );
  }

  bool get isPositive => stats.rating >= 4.0 || stats.popularity > 50;
  bool get isNeutral => stats.rating >= 2.5 && stats.rating < 4.0;
  bool get isNegative => stats.rating < 2.5;
}