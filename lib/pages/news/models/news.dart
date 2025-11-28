

class News {
  final String id;
  final String description;
  final String eventId;
  final String photoUrl;
  final List<String> ratings;
  final String eventName ;

  News({
    required this.id,
    required this.description,
    required this.eventId,
    required this.photoUrl,
    required this.ratings, 
    this.eventName = 'Unknown Event 333333333',
  });

  factory News.fromJson(String id, Map<String, dynamic> json) {
    return News(
      id: id,
      description: json['description'] ?? '',
      eventId: json['event_id'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      ratings: List<String>.from(json['ratings'] ?? []),
      eventName: json['event_name'] ?? 'Unknown Event 22222222',

    );
    }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'event_id': eventId,
      'photo_url': photoUrl,
      'ratings': ratings,
    };
  }
}
