class WishMeLuckEvent {
  final String id;
  final String title;
  final String imageUrl;
  final String description;

  WishMeLuckEvent({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
  });

  factory WishMeLuckEvent.fromJson(Map<String, dynamic> json, String docId) {
    return WishMeLuckEvent(
      id: docId,
      title: json['title'] ?? json['name'] ?? 'Untitled Event',
      imageUrl: json['metadata']?['image_url'] ?? json['image_url'] ?? '',
      description: json['description'] ?? 'No description available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'description': description,
    };
  }
}