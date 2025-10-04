import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivity {
  final String user_id;
  final String event_id;
  final DateTime time;
  final String source;
  final String type;
  final int? rating;
  final String? commentId;
  final String? timeOfDay;
  final bool withFriends;

  UserActivity({
    required this.user_id,
    required this.event_id,
    required this.time,
    required this.source,
    this.type = "",
    this.rating,
    this.commentId,
    this.timeOfDay,
    this.withFriends = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "user_id": user_id,
      "event_id": event_id,
      "time": Timestamp.fromDate(time),
      "source": source,
      "type": type,
      "rating": rating,
      "comment_id": commentId,
      "time_of_day": timeOfDay,
      "with_friends": withFriends,
    };
  }

  factory UserActivity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserActivity(
      user_id: data["user_id"],
      event_id: data["event_id"],
      time: (data["time"] as Timestamp).toDate(),
      source: data["source"],
      type: data["type"] ?? "",
      rating: data["rating"],
      commentId: data["comment_id"],
      timeOfDay: data["time_of_day"],
      withFriends: data["with_friends"] ?? false,
    );
  }
}
