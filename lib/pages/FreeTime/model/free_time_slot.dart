import 'package:intl/intl.dart';

class FreeTimeSlot {
  final String day;
  final DateTime startTime;
  final DateTime endTime;

  FreeTimeSlot({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  // Función helper para parsear hora con AM/PM a DateTime
  static DateTime parseTime(String timeStr) {
    final format = DateFormat('h:mm a'); // "8:00 AM" / "8:00 PM"
    final dt = format.parse(timeStr);
    return DateTime(2025, 1, 1, dt.hour, dt.minute); // día fijo
  }

  factory FreeTimeSlot.fromMap(Map<String, dynamic> data) {
    return FreeTimeSlot(
      day: data['day'] as String,
      startTime: parseTime(data['start'] as String),
      endTime: parseTime(data['end'] as String),
    );
  }
}



