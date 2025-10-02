class UserModel {
  final String uid;
  final String name;
  final String email;
  final String day;
  final String time;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.day,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'day': day,
      'time': time,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      day: map['day'],
      time: map['time'],
    );
  }
}
