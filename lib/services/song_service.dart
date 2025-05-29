import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SongService {
  static String get baseUrl {
    const String apiUrl = 'https://music-app-10.onrender.com/api';
    return apiUrl;
  }

  static String checkToken(String? token) {
    if (token == null || token.isEmpty) {
      throw Exception('⚠️ Token không hợp lệ hoặc bị null');
    }
    return token;
  }

  static Future<List<Map<String, dynamic>>> fetchSongs(String token) async {
    final url = Uri.parse('$baseUrl/songs');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      print("📥 [fetchSongs] Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body);
      } else {
        throw Exception('❌ Lỗi khi tải bài hát: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ [fetchSongs] Exception: $e");
      throw Exception("Không thể tải danh sách bài hát");
    }
  }

  static Future<List<Map<String, dynamic>>> searchSongs({
    required String? token,
    required String query,
  }) async {
    if (query.isEmpty) {
      throw Exception('⚠️ Từ khóa tìm kiếm không thể để trống');
    }

    final validToken = checkToken(token);
    final url = Uri.parse('$baseUrl/songs/search?query=$query');
    final headers = {
      'Authorization': 'Bearer $validToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      print("🔍 [searchSongs] Status: ${response.statusCode}");
      print("🔍 [searchSongs] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body != null && body.isNotEmpty) {
          return body.whereType<Map<String, dynamic>>().toList();
        } else {
          throw Exception('❌ Không có bài hát nào được tìm thấy');
        }
      } else {
        throw Exception('❌ Lỗi khi tìm kiếm bài hát: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ [searchSongs] Exception: $e");
      throw Exception("Không thể thực hiện tìm kiếm bài hát");
    }
  }

  static Future<bool> uploadSongWithFile({
    required String token,
    required String title,
    required String artist,
    required String genre,
    required http.MultipartFile audioFile,
  }) async {
    final uri = Uri.parse('$baseUrl/songs/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = title
      ..fields['artist'] = artist
      ..fields['genre'] = genre
      ..files.add(audioFile);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📤 [uploadSongWithFile] Status: ${response.statusCode}");
      print("📤 Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("❌ [uploadSongWithFile] Exception: $e");
      return false;
    }
  }

  static Future<bool> deleteSongById({required String token, required String id}) async {
    final url = Uri.parse('$baseUrl/songs/$id');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.delete(url, headers: headers);
      print("🗑️ [deleteSong] Status: ${response.statusCode}");
      print("🗑️ Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("❌ [deleteSong] Exception: $e");
      return false;
    }
  }

  static Future<bool> addToFavorites({
    required String token,
    required String songId,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/songs/$songId/favorite');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({'userId': userId});

    try {
      final response = await http.post(url, headers: headers, body: body);
      print("❤️ [addToFavorites] Status: ${response.statusCode}");
      print("❤️ [addToFavorites] Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 400 && response.body.contains('đã được yêu thích')) {
        print("⚠️ Bài hát đã được yêu thích trước đó.");
        return false;
      } else {
        print("❌ [addToFavorites] Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ [addToFavorites] Exception: $e");
      return false;
    }
  }

  static Future<bool> removeFromFavorites({
    required String token,
    required String songId,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/songs/$songId/favorite');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({'userId': userId});

    try {
      final response = await http.delete(url, headers: headers, body: body);
      print("💔 [removeFromFavorites] Status: ${response.statusCode}");
      print("💔 [removeFromFavorites] Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("❌ [removeFromFavorites] Exception: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFavorites(String token) async {
    final url = Uri.parse('$baseUrl/songs/favorites');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      print("💖 [fetchFavorites] Status: ${response.statusCode}");
      print("💖 [fetchFavorites] Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          return List<Map<String, dynamic>>.from(body.map((item) => item as Map<String, dynamic>));
        } else {
          throw Exception('❌ Dữ liệu trả về không đúng định dạng danh sách');
        }
      } else {
        throw Exception('❌ Lỗi khi lấy danh sách yêu thích: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ [fetchFavorites] Exception: $e");
      throw Exception("Không thể tải danh sách yêu thích");
    }
  }


  static Future<void> increaseShareCount(String songId) async {
    final url = Uri.parse("$baseUrl/songs/$songId/share");

    try {
      final token = await getToken();
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.put(url, headers: headers);
      print("📈 [increaseShareCount] Status: ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception("❌ Failed to increase share count: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [increaseShareCount] Exception: $e");
      throw Exception("Không thể cập nhật lượt chia sẻ");
    }
  }

  static Future<String?> getShareLink(String songId, String token) async {
    final url = Uri.parse("$baseUrl/songs/$songId/share-link");

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      print("🔗 [getShareLink] Status: ${response.statusCode}");
      print("🔗 [getShareLink] Body: ${response.body}");

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print("❌ [getShareLink] Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ [getShareLink] Exception: $e");
      return null;
    }
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('⚠️ Token không tồn tại hoặc rỗng');
    }

    return token;
  }
  static Future<int> getShareCount(String songId) async {
    final url = Uri.parse('$baseUrl/songs/$songId/share-count');

    try {
      final token = await getToken();
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);
      print("🔢 [getShareCount] Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // API trả về số nguyên dạng plain text hoặc JSON số nguyên
        // Dùng int.parse với response.body
        final shareCount = int.tryParse(response.body);
        if (shareCount != null) {
          return shareCount;
        } else {
          throw Exception('❌ Dữ liệu trả về không hợp lệ');
        }
      } else {
        throw Exception('❌ Lỗi khi lấy lượt chia sẻ: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ [getShareCount] Exception: $e");
      return 0; // Trả về 0 nếu có lỗi
    }
  }
  static Future<bool> incrementView(int songId, String token) async {
    final url = Uri.parse('$baseUrl/songs/$songId/view');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http
          .put(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      print("📈 [incrementView] Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return true;
      } else {
        print("⚠️ Không thể tăng view. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print('❌ [incrementView] Lỗi: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTopViewSongs(String token,
      {int limit = 10}) async {
    final url = Uri.parse('$baseUrl/songs/top?limit=$limit');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response =
      await http.get(url, headers: headers).timeout(
          const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body);
      } else {
        print("⚠️ Lỗi lấy top view: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print('❌ [fetchTopViewSongs] Lỗi: $e');
      return [];
    }
  }
  /// Toggle Like/Unlike cho bài hát
  static Future<bool> toggleLike({
    required String token,
    required String songId,
  }) async {
    final url = Uri.parse('$baseUrl/songs/$songId/like');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.put(url, headers: headers);
      print("👍 [toggleLike] Status: ${response.statusCode} Body: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        print("❌ [toggleLike] Failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ [toggleLike] Exception: $e");
      return false;
    }
  }
  /// Lấy danh sách bài hát được like nhiều nhất
  static Future<List<Map<String, dynamic>>> fetchTopLikedSongs({
    required String token,
    int limit = 10,
  }) async {
    final url = Uri.parse('$baseUrl/songs/top-liked?limit=$limit');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body);
      } else {
        print("⚠️ [fetchTopLikedSongs] Lỗi: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ [fetchTopLikedSongs] Lỗi: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchSongsByVoice({
    required String? token,
    required String query,
  }) async {
    if (query.isEmpty) {
      throw Exception('⚠️ Nội dung giọng nói không thể để trống');
    }

    final validToken = checkToken(token);
    final url = Uri.parse('$baseUrl/search/voice?q=$query');
    final headers = {
      'Authorization': 'Bearer $validToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      print("🎙️ [searchSongsByVoice] Status: ${response.statusCode}");
      print("🎙️ [searchSongsByVoice] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body != null && body.isNotEmpty) {
          return body.whereType<Map<String, dynamic>>().toList();
        } else {
          throw Exception('❌ Không có bài hát nào được tìm thấy từ giọng nói');
        }
      } else {
        throw Exception('❌ Lỗi khi tìm kiếm giọng nói: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ [searchSongsByVoice] Exception: $e");
      throw Exception("Không thể tìm kiếm bài hát bằng giọng nói");
    }
  }
}
