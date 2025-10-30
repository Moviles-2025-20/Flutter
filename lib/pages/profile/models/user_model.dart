import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final Profile profile;
  final Preferences preferences;
  final Stats? stats;

  UserModel({
    required this.uid,
    required this.profile,
    required this.preferences,
    this.stats,
  });

  UserModel copyWith({
    Profile? profile,
    Preferences? preferences,
    Stats? stats,
  }) {
    return UserModel(
      uid: uid,
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
    );
  }


  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      profile: Profile.fromMap(data['profile'] ?? {}),
      preferences: Preferences.fromMap(data['preferences'] ?? {}),
      stats: data['stats'] != null ? Stats.fromMap(data['stats']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile': profile.toMap(),
      'preferences': preferences.toMap(),
      if (stats != null) 'stats': stats!.toMap(),
    };
  }
}

class Profile {
  final String name;
  final String email;
  final String? city;
  final String? gender;
  final int age;
  final String? major;
  final String? photo;
  final DateTime? created;
  final DateTime? lastActive;

  Profile({
    required this.name,
    required this.email,
    this.city,
    this.gender,
    required this.age,
    this.major,
    this.photo,
    this.created,
    this.lastActive,
  });

  Profile copyWith({
    String? name,
    String? email,
    String? city,
    String? gender,
    int? age,
    String? major,
    String? photo,
    DateTime? created,
    DateTime? lastActive,
  }) {
    return Profile(
      name: name ?? this.name,
      email: email ?? this.email,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      major: major ?? this.major,
      photo: photo ?? this.photo,
      created: created ?? this.created,
      lastActive: lastActive ?? this.lastActive,
    );
  }


  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      city: map['city'],
      gender: map['gender'],
      age: map['age'] ?? 0,
      major: map['major'],
      photo: map['photo'],
      created: map['created'] != null
          ? (map['created'] as Timestamp).toDate()
          : null,
      lastActive: map['last_active'] != null
          ? (map['last_active'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      if (city != null) 'city': city,
      if (gender != null) 'gender': gender,
      'age': age,
      if (major != null) 'major': major,
      if (photo != null) 'photo': photo,
      if (created != null) 'created': Timestamp.fromDate(created!),
      if (lastActive != null) 'last_active': Timestamp.fromDate(lastActive!),
    };
  }
}

class Preferences {
  final List<String> favoriteCategories;
  final List<String> completedCategories;
  final int indoorOutdoorScore;
  final List<FreeTimeSlot> freeTimeSlots;

  Preferences({
    required this.favoriteCategories,
    this.completedCategories = const [],
    this.indoorOutdoorScore = 0,
    this.freeTimeSlots = const [],
  });

  Preferences copyWith({
    List<String>? favoriteCategories,
    List<String>? completedCategories,
    int? indoorOutdoorScore,
    List<FreeTimeSlot>? freeTimeSlots,
  }) {
    return Preferences(
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      completedCategories: completedCategories ?? this.completedCategories,
      indoorOutdoorScore: indoorOutdoorScore ?? this.indoorOutdoorScore,
      freeTimeSlots: freeTimeSlots ?? this.freeTimeSlots,
    );
  }


  factory Preferences.fromMap(Map<String, dynamic> map) {
    final notifications = map['notifications'] as Map<String, dynamic>?;
    final slotsData = notifications?['free_time_slots'] as List<dynamic>? ?? [];

    return Preferences(
      favoriteCategories: List<String>.from(map['favorite_categories'] ?? []),
      completedCategories: List<String>.from(map['completed_categories'] ?? []),
      indoorOutdoorScore: map['indoor_outdoor_score'] ?? 0,
      freeTimeSlots: slotsData
          .map((slot) => FreeTimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'favorite_categories': favoriteCategories,
      'completed_categories': completedCategories,
      'indoor_outdoor_score': indoorOutdoorScore,
      'notifications': {
        'free_time_slots': freeTimeSlots.map((slot) => slot.toMap()).toList(),
      },
    };
  }
}

class FreeTimeSlot {
  final String day;
  final String start;
  final String end;

  FreeTimeSlot({
    required this.day,
    required this.start,
    required this.end,
  });

  factory FreeTimeSlot.fromMap(Map<String, dynamic> map) {
    return FreeTimeSlot(
      day: map['day'] ?? '',
      start: map['start'] ?? '',
      end: map['end'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'start': start,
      'end': end,
    };
  }

  @override
  String toString() => '$day: $start - $end';
}

class Stats {
  final DateTime? lastWishMeLuck;
  final int totalWeeklyChallenges;
  final int streakDays;
  final int totalActivities;

  Stats({
    this.lastWishMeLuck,
    this.totalWeeklyChallenges = 0,
    this.streakDays = 0,
    this.totalActivities = 0,
  });

  factory Stats.fromMap(Map<String, dynamic> map) {
    return Stats(
      lastWishMeLuck: map['last_wish_me_luck'] != null
          ? (map['last_wish_me_luck'] as Timestamp).toDate()
          : null,
      totalWeeklyChallenges: map['total_weekly_challenges'] ?? 0,
      streakDays: map['streak_days'] ?? 0,
      totalActivities: map['total_activities'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (lastWishMeLuck != null)
        'last_wish_me_luck': Timestamp.fromDate(lastWishMeLuck!),
      'total_weekly_challenges': totalWeeklyChallenges,
      'streak_days': streakDays,
      'total_activities': totalActivities,
    };
  }
}