import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userName;
  final String avatar;
  final String event_id;
  final String description;
  final DateTime createdAt;
  final String? imageUrl;

  Comment({
    required this.id,
    required this.userName,
    required this.avatar,
    required this.event_id,
    required this.description,
    required this.createdAt,
    this.imageUrl,
  });

  factory Comment.fromJson(String id, Map<String, dynamic> json) {
    return Comment(
      id: id,
      userName: json['userName'] ?? '',
      avatar: json['avatar'] ?? '',
      event_id: json['event_id'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : (json['createdAt'] as Timestamp).toDate())
          : DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }
}