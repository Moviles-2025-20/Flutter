import 'package:cloud_firestore/cloud_firestore.dart';

class CommentMetadata {
  final String imageUrl;
  final String text;

  CommentMetadata({
    required this.imageUrl,
    required this.text,
  });

  factory CommentMetadata.fromJson(Map<String, dynamic> json) {
    return CommentMetadata(
      imageUrl: json['image_url'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class Comment {
  final String id;
  final String user_id;
  final String event_id;
  final CommentMetadata metadata;
  final DateTime created;

  Comment({
    required this.id,
    required this.user_id,
    required this.event_id,
    required this.metadata,
    required this.created,
  });

  factory Comment.fromJson(String id, Map<String, dynamic> json) {
    return Comment(
      id: id,
      user_id: json['user_id'] ?? '',
      event_id: json['event_id'] ?? '',
      metadata: CommentMetadata.fromJson(json['metadata'] ?? {}),
      created: json['created'] != null
          ? (json['created'] is String 
              ? DateTime.parse(json['created'])
              : (json['created'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }
}