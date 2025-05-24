import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/song_service.dart';

class AllSongsViewModel extends GetxController {
  var allList = [].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchAllSongs();
  }

  Future<void> fetchAllSongs() async {
    try {
      isLoading(true);
      final token = box.read('token');

      if (token == null || token.isEmpty) {
        errorMessage.value = "❌ Token không tồn tại. Vui lòng đăng nhập lại.";

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar("Lỗi", errorMessage.value,
              snackPosition: SnackPosition.BOTTOM);
        });

        isLoading(false);
        return;
      }

      // Lấy danh sách tất cả bài hát từ API
      final songs = await SongService.fetchSongs(token);
      print("✅ Fetched ${songs.length} bài hát");
      allList.assignAll(songs);

      // Lấy danh sách yêu thích từ backend
      final backendFavorites = await SongService.fetchFavorites(token);

      // Giả sử backend trả về danh sách các bài hát yêu thích và mỗi bài hát có trường 'id'
      final favoriteIds = backendFavorites
          .map<String>((song) => song["id"].toString())
          .toList();

      // Cập nhật vào local storage (tuỳ chọn, để dùng cho UI nhanh)
      box.write('favorites', favoriteIds);

      // Cập nhật trạng thái yêu thích trong danh sách bài hát
      updateFavorites(favoriteIds);
    } catch (e) {
      errorMessage.value = "❌ Lỗi khi tải bài hát: $e";

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar("Lỗi", errorMessage.value,
            snackPosition: SnackPosition.BOTTOM);
      });

      allList.clear();
    } finally {
      isLoading(false);
    }
  }

  List<Map<String, dynamic>> getPlayableSongList() {
    return allList.map((song) {
      return {
        'id': song["id"].toString(),
        'title': song["title"] ?? 'Không tên',
        'artist': song["artist"] ?? 'Không rõ',
        'album': '',
        'genre': song["genre"] ?? '',
        'image': '',
        'url': song["cloudinaryUrl"] ?? '',
        'user_id': '',
        'user_name': song["artist"] ?? '',
      };
    }).toList();
  }

  /// ✅ Cập nhật trạng thái yêu thích theo danh sách ID
  void updateFavorites(List<String> favoriteIds) {
    for (var i = 0; i < allList.length; i++) {
      final id = allList[i]['id'].toString();
      allList[i]['isFavorite'] = favoriteIds.contains(id);
    }
    allList.refresh(); // 🔄 Cập nhật UI
  }

  /// ✅ Toggle yêu thích một bài hát theo ID
  void toggleFavorite(String songId) async {
    final currentFavorites = box.read<List>('favorites')?.cast<String>() ?? [];
    final token = box.read('token');
    final userId = box.read('userId'); // nhớ đảm bảo đã lưu userId khi đăng nhập

    if (token == null || userId == null) {
      print("❌ Token hoặc userId không tồn tại.");
      return;
    }

    bool isNowFavorite;

    if (currentFavorites.contains(songId)) {
      currentFavorites.remove(songId);
      isNowFavorite = false;

      // Gọi API xoá khỏi yêu thích
      final success = await SongService.removeFromFavorites(
        token: token,
        songId: songId,
        userId: userId,
      );

      if (!success) {
        print("❌ Gỡ yêu thích thất bại.");
      }
    } else {
      currentFavorites.add(songId);
      isNowFavorite = true;

      // Gọi API thêm vào yêu thích
      final success = await SongService.addToFavorites(
        token: token,
        songId: songId,
        userId: userId,
      );

      if (!success) {
        print("❌ Thêm yêu thích thất bại.");
      }
    }

    // ✅ Ghi lại danh sách yêu thích mới vào local storage
    box.write('favorites', currentFavorites);

    // ✅ Cập nhật lại trạng thái bài hát
    updateFavorites(currentFavorites);

    // ✅ Feedback người dùng
    Get.snackbar(
      "Yêu thích",
      isNowFavorite ? "Đã thêm vào yêu thích" : "Đã gỡ khỏi yêu thích",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// ✅ Tăng lượt xem bài hát
  Future<void> incrementView(String songId) async {
    final token = box.read('token');
    if (token == null || token.isEmpty) {
      print("❌ Token không tồn tại, không thể tăng lượt xem.");
      return;
    }

    final songIdInt = int.tryParse(songId);
    if (songIdInt == null) {
      print("❌ songId không hợp lệ: $songId");
      return;
    }

    try {
      await SongService.incrementView(songIdInt, token);
      print("✅ Tăng lượt xem bài hát $songId thành công");
    } catch (e) {
      print("❌ Lỗi tăng lượt xem: $e");
    }
  }
}
