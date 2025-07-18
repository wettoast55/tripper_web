import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationApi {
  static Future<String> fetchRecommendations({
    required List<String> activities,
    required String budget,
    required String month,
  }) async {
    const url = 'http://localhost:8000/recommendations'; // Change if deployed

    final body = jsonEncode({
      'activities': activities,
      'budget': budget,
      'month': month,
    });

    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['recommendations'] ?? 'No recommendations found.';
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Request failed: $e';
    }
  }
}
