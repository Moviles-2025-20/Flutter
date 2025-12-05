class Option {
  final String text;
  final String category;
  final int points;

  Option({
    required this.text,
    required this.category,
    required this.points,
  });

  factory Option.fromMap(Map<String, dynamic> data) {
    return Option(
      text: data['text'],
      category: data['category'],
      points: data['points'],
    );
  }
}
