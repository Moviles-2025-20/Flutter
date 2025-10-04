class UserModel {
  final String uid;
  final String name;
  final String email;
  final String day;
  final String time;
  final String last_event;


  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.day,
    required this.time,
    this.last_event = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'day': day,
      'time': time,
      'last_event': last_event,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      day: map['day'],
      time: map['time'],
      last_event: map['last_event'] ?? '',
    );
  }
}
