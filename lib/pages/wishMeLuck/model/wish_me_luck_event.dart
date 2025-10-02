import 'package:app_flutter/pages/wishMeLuck/Model/event.dart';

class WishMeLuckEvent {
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

  WishMeLuckEvent({
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

  factory WishMeLuckEvent.fromJson(Map<String, dynamic> json) {
    return WishMeLuckEvent(
      eventType: json['EventType'] != null 
          ? List<String>.from(json['EventType']) 
          : [],
      active: json['active'] ?? false,
      category: json['category'] ?? '',
      created: json['created'] != null
          ? (json['created'] is String 
              ? DateTime.parse(json['created'])
              : (json['created'] as DateTime))
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

  // Helper para determinar si el evento es "positivo"
  bool get isPositive => stats.rating >= 4.0 || stats.popularity > 50;
  bool get isNeutral => stats.rating >= 2.5 && stats.rating < 4.0;
  bool get isNegative => stats.rating < 2.5;
}