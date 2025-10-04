import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationService {
  final String baseUrl = "https://us-central1-parchandes-7e096.cloudfunctions.net";

  Future<Map<String, dynamic>> getRecommendations(String userId) async {
    final url = Uri.parse("$baseUrl/get_recommendations?user_id=$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Error getting recommendations: ${response.statusCode}");
    }
  }
}
