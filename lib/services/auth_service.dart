import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/auth_request.dart';
import '../model/auth_response.dart';

class AuthService {
  // URL API backend
  final String baseUrl = 'https://music-app-10.onrender.com/api/auth';
  /// Đăng nhập
  Future<AuthResponse> login(AuthRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      final token = authResponse.token;
      if (token == null || token.isEmpty) {
        throw Exception('Token nhận được từ server bị null hoặc rỗng.');
      }


      await saveToken(token);

      return authResponse;
    } else {
      throw Exception('❌ Đăng nhập thất bại: ${response.body}');
    }
  }

  /// Đăng ký
  Future<String> register(AuthRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return "✅ Đăng ký thành công!";
    } else {
      return '❌ Đăng ký thất bại: ${response.body}';
    }
  }

  /// ✅ Lưu token vào SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print("🔐 Token đã được lưu.");
  }

  /// ✅ Lấy token đã lưu
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      print("⚠️ Token không tồn tại hoặc rỗng.");
      return null;
    }

    print("✅ Lấy token thành công: $token");
    return token;
  }

  /// ✅ Xóa token (đăng xuất)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print("🚪 Token đã được xóa. Người dùng đã đăng xuất.");
  }
}
