import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../audio_helpers/player_invoke.dart';
import '../../common_widget/all_song_row.dart';
import '../../view_model/all_songs_view_model.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoritesVM = Get.put(AllSongsViewModel());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ảnh nền
          Positioned.fill(
            child: Image.asset(
              'assets/img/bg_favorite.png',
              fit: BoxFit.cover,
            ),
          ),
          // Lớp phủ làm tối ảnh nền
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // Nội dung danh sách yêu thích
          Obx(() {
            final favoriteSongs = favoritesVM.allList
                .where((song) => song['isFavorite'] == true)
                .toList();

            if (favoritesVM.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (favoriteSongs.isEmpty) {
              return const Center(
                child: Text(
                  "Chưa có bài hát yêu thích",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favoriteSongs.length,
              itemBuilder: (context, index) {
                var sObj = favoriteSongs[index];
                final songId = sObj['id'].toString();
                final isFavorite = sObj['isFavorite'] == true;
                final isLiked = sObj['isLiked'] == true;

                return AllSongRow(
                  sObj: sObj,
                  isWeb: true,
                  isFavorite: isFavorite,
                  isLiked: isLiked,
                  onPressedPlay: () {
                    playerPlayProcessDebounce(
                      favoritesVM.getPlayableSongList(),
                      index,
                    );
                  },
                  onToggleFavorite: () {
                    favoritesVM.toggleFavorite(songId);
                  },
                  onAddToFavorites: () {
                    favoritesVM.toggleFavorite(songId);
                  },
                  onRemoveFromFavorites: () {
                    favoritesVM.toggleFavorite(songId);
                  },
                  onDelete: () {
                    favoritesVM.allList.removeWhere(
                            (song) => song['id'].toString() == songId);
                    favoritesVM.allList.refresh();
                    Get.snackbar(
                      "Xoá bài hát",
                      "Đã xoá bài hát khỏi danh sách",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
