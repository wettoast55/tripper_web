import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationApi {
  static Future<Map<String, dynamic>> fetchRecommendations({
    required List<String> activities,
    required String budget,
    required String month,
  }) async {
    final url = Uri.parse('http://localhost:8000/recommendations');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "activities": activities,
        "budget": budget,
        "month": month,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // ✅ decode once here
    } else {
      throw Exception("Failed to get recommendations: ${response.body}");
    }
  }
}
