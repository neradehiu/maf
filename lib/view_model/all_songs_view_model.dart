import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/song_service.dart';
import '../services/api_service.dart';

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

      // ✅ Lấy tất cả bài hát
      final songs = await SongService.fetchSongs(token);
      allList.assignAll(songs);
      print("✅ Fetched ${songs.length} bài hát");

      // ✅ Lấy danh sách yêu thích
      final favoriteSongs = await SongService.fetchFavorites(token);
      final favoriteIds =
          favoriteSongs.map<String>((song) => song["id"].toString()).toList();
      box.write('favorites', favoriteIds);
      updateFavorites(favoriteIds);

      // ✅ Lấy danh sách đã like (nếu backend có API này)
      final likedSongs = await SongService.fetchFavorites(token);
      final likedIds =
          likedSongs.map<String>((song) => song["id"].toString()).toList();
      updateLiked(likedIds);
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

  /// ✅ Cập nhật trạng thái yêu thích
  void updateFavorites(List<String> favoriteIds) {
    for (var i = 0; i < allList.length; i++) {
      final id = allList[i]['id'].toString();
      allList[i]['isFavorite'] = favoriteIds.contains(id);
    }
    allList.refresh();
  }

  /// ✅ Cập nhật trạng thái đã like
  void updateLiked(List<String> likedIds) {
    for (var i = 0; i < allList.length; i++) {
      final id = allList[i]['id'].toString();
      allList[i]['isLiked'] = likedIds.contains(id);
    }
    allList.refresh();
  }

  /// ✅ Toggle trạng thái like
  Future<bool?> toggleLike(String songId) async {
    final token = box.read('token');
    if (token == null) return null;

    final songIdInt = int.tryParse(songId);
    if (songIdInt == null) return null;

    try {
      final liked = await ApiService.toggleLike(songIdInt, token);
      if (liked != null) {
        final index = allList.indexWhere((e) => e['id'].toString() == songId);
        if (index != -1) {
          allList[index]['isLiked'] = liked;
          allList.refresh();
        }
      }
      return liked;
    } catch (e) {
      print("❌ Lỗi khi toggle like: $e");
      return null;
    }
  }

  /// ✅ Toggle trạng thái yêu thích
  Future<bool> toggleFavorite(String songId) async {
    final currentFavorites = box.read<List>('favorites')?.cast<String>() ?? [];
    final token = box.read('token');
    final userId = box.read('userId');

    if (token == null || userId == null) return false;

    bool isNowFavorite;

    if (currentFavorites.contains(songId)) {
      currentFavorites.remove(songId);
      isNowFavorite = false;

      final success = await SongService.removeFromFavorites(
        token: token,
        songId: songId,
        userId: userId,
      );

      if (!success) {
        print("❌ Gỡ yêu thích thất bại.");
        // Nếu thất bại thì giữ lại như cũ
        currentFavorites.add(songId);
        isNowFavorite = true;
      }
    } else {
      currentFavorites.add(songId);
      isNowFavorite = true;

      final success = await SongService.addToFavorites(
        token: token,
        songId: songId,
        userId: userId,
      );

      if (!success) {
        print("❌ Thêm yêu thích thất bại.");
        // Nếu thất bại thì xoá lại
        currentFavorites.remove(songId);
        isNowFavorite = false;
      }
    }

    box.write('favorites', currentFavorites);
    updateFavorites(currentFavorites);

    Get.snackbar(
      "Yêu thích",
      isNowFavorite ? "Đã thêm vào yêu thích" : "Đã gỡ khỏi yêu thích",
      snackPosition: SnackPosition.BOTTOM,
    );

    return isNowFavorite;
  }

  /// ✅ Lấy danh sách phát nhạc
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

  /// ✅ Tăng lượt xem
  Future<void> incrementView(String songId) async {
    final token = box.read('token');
    if (token == null || token.isEmpty) return;

    final songIdInt = int.tryParse(songId);
    if (songIdInt == null) return;

    try {
      await SongService.incrementView(songIdInt, token);
      print("✅ Tăng lượt xem bài hát $songId thành công");
    } catch (e) {
      print("❌ Lỗi tăng lượt xem: $e");
    }
  }
}
