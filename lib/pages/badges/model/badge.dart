class Badge_Medal {
  final String id;                       // ID único de la medalla
  final String name;                     // Nombre visible
  final String description;              // Descripción de cómo obtenerla
  final String icon;                     // URL o ruta del ícono
  final String rarity;                   // common, rare, epic, legendary
  final String criteriaType;             // Tipo de condición (ej: tasks_completed)
  final dynamic criteriaValue;           // Número, lista, string, etc.
  final bool isSecret;                   // Si es oculta hasta desbloquear
  final DateTime createdAt;              // Fecha de creación del badge
  final DateTime updatedAt;              // Fecha de última modificación

  Badge_Medal({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.criteriaType,
    required this.criteriaValue,
    required this.isSecret,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convertir Badge -> Map (para Firestore/NoSQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'rarity': rarity,
      'criteriaType': criteriaType,
      'criteriaValue': criteriaValue,
      'isSecret': isSecret,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crear Badge desde Map (Firestore/NoSQL -> Badge)
  factory Badge_Medal.fromMap(Map<String, dynamic> map) {
    return Badge_Medal(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
      rarity: map['rarity'],
      criteriaType: map['criteriaType'],
      criteriaValue: map['criteriaValue'],
      isSecret: map['isSecret'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
