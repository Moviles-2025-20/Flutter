import 'package:intl/intl.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String category;
  final String location;
  final String day;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String organizer;
  final String imageUrl;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.organizer,
    required this.imageUrl,
  });

  /// Parsea la hora tanto en formato "10:30 AM" como "17:10"
  static DateTime parseTime(String timeStr) {
    try {
      final formatAmPm = DateFormat('h:mm a');
      final dt = formatAmPm.parse(timeStr);
      return DateTime(2025, 1, 1, dt.hour, dt.minute);
    } catch (_) {
      final format24 = DateFormat('H:mm');
      final dt = format24.parse(timeStr);
      return DateTime(2025, 1, 1, dt.hour, dt.minute);
    }
  }

  factory Event.fromMap(Map<String, dynamic> data) {
    final schedule = data['schedule'] as Map<String, dynamic>;
    final days = (schedule['days'] as List<dynamic>? ?? []);
    final times = (schedule['times'] as List<dynamic>? ?? []);

    final startStr = times.isNotEmpty ? times[0] as String : "00:00";
    final duration = (data['metadata']?['duration_minutes'] as num?)?.toInt() ?? 0;

    final startTime = parseTime(startStr);
    final endTime = startTime.add(Duration(minutes: duration));

    return Event(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Untitled',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      location: data['location']?['address'] ?? 'Unknown',
      day: days.isNotEmpty ? days[0] as String : '',
      startTime: startTime,
      endTime: endTime,
      durationMinutes: duration,
      organizer: data['organizer'] ?? '',
      imageUrl: data['metadata']?['image_url'] ?? '',
    );
  }

  @override
  String toString() {
    final timeFormat = DateFormat('h:mm a');
    return 'Event: $name ($category), $day, '
        '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)} '
        '@ $location';
  }
}
