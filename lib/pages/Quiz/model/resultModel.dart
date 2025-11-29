class UserQuizResult {
  final String userId;
  final String quizId;
  final DateTime timestamp;
  final List<String> selectedQuestionIds;
  final Map<String, int> scores;
  final List<String> resultCategories;
  final String resultType;

  UserQuizResult({
    required this.userId,
    required this.quizId,
    required this.timestamp,
    required this.selectedQuestionIds,
    required this.scores,
    required this.resultCategories,
    required this.resultType,
  });

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "quizBankId": quizId,
      "timestamp": timestamp.toIso8601String(),
      "selectedQuestionIds": selectedQuestionIds,
      "scores": scores,
      "resultCategory": resultCategories,
      "resultType": resultType
    };
  }
}
