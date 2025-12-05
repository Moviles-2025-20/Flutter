import 'optionModel.dart';

class Question {
  final String id;
  final String text;
  final List<Option> options;

  Question({
    required this.id,
    required this.text,
    required this.options,
  });

  factory Question.fromMap(Map<String, dynamic> data) {
    return Question(
      id: data['id'],
      text: data['text'],
      options: (data['options'] as List)
          .map((o) => Option.fromMap(o))
          .toList(),
    );
  }
}

