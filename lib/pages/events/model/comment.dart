import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userName;
  final String avatar;
  final String event_id;
  final String description;
  final DateTime created;
  final String? imageUrl;

  Comment({
    required this.id,
    required this.userName,
    required this.avatar,
    required this.event_id,
    required this.description,
    required this.created,
    this.imageUrl,
  });

  factory Comment.fromJson(String id, Map<String, dynamic> json) {
    return Comment(
      id: id,
      userName: json['userName'] ?? '',
      avatar: json['avatar'] ?? '',
      event_id: json['event_id'] ?? '',
      description: json['description'] ?? '',
      created: json['created'] != null
          ? (json['created'] is String
              ? DateTime.parse(json['created'])
              : (json['created'] as Timestamp).toDate())
          : DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }
}