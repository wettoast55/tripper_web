import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationApi {
  static Future<Map<String, dynamic>> fetchRecommendations({
    required List<String> activities,
    required String budget,
    required String month,
    List<String>? travelMethods,
    List<String>? accommodations,
    List<String>? destinations,
    List<String>? interests,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final uri = Uri.parse("http://localhost:8000/recommendations");

    final body = jsonEncode({
      "activities": activities,
      "budget": budget,
      "month": month,
      "travelMethods": travelMethods ?? [],
      "accommodations": accommodations ?? [],
      "destinations": destinations ?? [],
      "interests": interests ?? [],
      "startDate": startDate?.toIso8601String(),
      "endDate": endDate?.toIso8601String(),
    });

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch recommendations: ${response.statusCode}");
    }
  }
}
