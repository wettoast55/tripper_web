import 'dart:convert';
import 'package:http/http.dart' as http;

class DealsApi {
  static const String baseUrl = "http://127.0.0.1:8000"; // Or your deployed backend URL

  static Future<Map<String, dynamic>> fetchLiveDeals({
    required String origin,
    int maxPrice = 1000,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/live-deals"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "origin": origin,
        "max_price": maxPrice,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch flight deals");
    }
  }
}


// SURVEY STATUS NAME NEEDS TO BE CHANGED FROM AUTOMATICALLY SAYING GUEST TO ACUTAL USERNAMES