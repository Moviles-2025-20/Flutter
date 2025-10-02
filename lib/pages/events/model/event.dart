
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