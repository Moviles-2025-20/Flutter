class UserBadge {
  final String id;                 // ID del documento UserBadge
  final String userId;             // Usuario dueño del badge
  final String badgeId;            // Badge que está progresando
  final bool isUnlocked;           // Si ya lo ganó
  final int progress;              // Progreso actual
  final DateTime? earnedAt;        // Fecha del logro
  final List<String> completedActivityIds; // IDs de actividades que contribuyeron al progreso

  UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.isUnlocked,
    required this.progress,
    required this.earnedAt,
    this.completedActivityIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'badgeId': badgeId,
      'isUnlocked': isUnlocked,
      'progress': progress,
      'earnedAt': earnedAt?.toIso8601String(),
      'completedActivityIds': completedActivityIds,
    };
  }

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      id: map['id'],
      userId: map['userId'],
      badgeId: map['badgeId'],
      isUnlocked: map['isUnlocked'] ?? false,
      progress: map['progress'] ?? 0,
      earnedAt: map['earnedAt'] != null ? DateTime.parse(map['earnedAt']) : null,
      completedActivityIds: List<String>.from(map['completedActivityIds'] ?? []),
    );
  }
}
