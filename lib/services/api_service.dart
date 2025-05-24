import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://your-ip:your-port"; // ví dụ http://localhost:8080 hoặc IP máy thật

  static Future<String?> toggleLike(int id, String token) async {
    final response = await http.put(
      Uri.parse("$baseUrl/songs/$id/like"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      print("Error: ${response.statusCode}");
      return null;
    }
  }
}
