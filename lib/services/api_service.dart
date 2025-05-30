import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiService {
  // ✔️  Thêm /api nếu controller của bạn nằm dưới /api/**
  static const String _baseUrl = 'https://music-app-10.onrender.com/api';

  /// Trả về:
  ///   * true   → vừa like
  ///   * false  → vừa bỏ like
  ///   * null   → lỗi (404, 5xx, network, v.v.)
  static Future<bool?> toggleLike(int id, String token) async {
    final uri = Uri.parse('$_baseUrl/songs/$id/like');

    try {
      final res = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          // KHÔNG gửi Content-Type khi không có body
          // Browser tự thêm Accept: */*
        },
      );

      if (res.statusCode == 200) {
        final txt = res.body.trim().toLowerCase();
        if (txt.startsWith('liked'))   return true;
        if (txt.startsWith('unliked')) return false;
        // Trường hợp backend thay đổi format
        log('toggleLike: unexpected body "$txt"');
        return null;
      }

      // 401: token hết hạn → cho logout/refresh token
      if (res.statusCode == 401) {
        log('toggleLike: unauthorized (401)');
        return null;
      }

      // 404: bài hát không tồn tại
      if (res.statusCode == 404) return null;

      // Các mã khác
      log('toggleLike: error ${res.statusCode}');
      return null;
    } catch (e, st) {
      log('toggleLike exception', error: e, stackTrace: st);
      return null;
    }
  }
}