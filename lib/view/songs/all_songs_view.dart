import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/audio_helpers/player_invoke.dart';
import 'package:music_player/common_widget/all_song_row.dart';
import 'package:music_player/services/song_service.dart';
import 'package:music_player/view/songs/song_delete_server.dart';
import 'package:music_player/view_model/all_songs_view_model.dart';

class AllSongsView extends StatefulWidget {
  const AllSongsView({super.key});

  @override
  State<AllSongsView> createState() => _AllSongsViewState();
}

class _AllSongsViewState extends State<AllSongsView> {
  final allVM = Get.put(AllSongsViewModel());
  final songDeleteService = SongDeleteService();

  @override
  void initState() {
    super.initState();
    // Nếu muốn, có thể gọi allVM.fetchAllSongs() lại nếu cần refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(
            () {
          if (allVM.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allVM.allList.isEmpty) {
            return const Center(
              child: Text(
                "Không có bài hát nào.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: allVM.allList.length,
            itemBuilder: (context, index) {
              final sObj = allVM.allList[index];
              final songId = sObj['id']?.toString() ?? '';
              final isFavorite = sObj['isFavorite'] == true;

              return AllSongRow(
                sObj: sObj,
                isWeb: true,
                isFavorite: isFavorite,

                /// 👉 Phát nhạc + tăng view qua ViewModel
                onPressedPlay: () async {
                  // Lấy playlist dạng List<Map>
                  final playlist = allVM.allList.map((song) {
                    return {
                      'id': song["id"]?.toString() ?? '',
                      'title': song["title"] ?? '',
                      'artist': song["artist"] ?? '',
                      'album': '',
                      'genre': song["genre"] ?? '',
                      'image': '',
                      'url': song["cloudinaryUrl"] ?? '',
                      'user_id': '',
                      'user_name': song["artist"] ?? '',
                    };
                  }).toList();

                  // Tăng lượt xem bài hát
                  await allVM.incrementView(songId);

                  // Phát nhạc
                  songDeleteService.onPressedPlay(playlist, index);
                },

                /// 👉 Toggle trạng thái yêu thích
                onToggleFavorite: () {
                  allVM.toggleFavorite(songId);
                },

                /// 👉 Thêm yêu thích (nếu muốn dùng riêng)
                onAddToFavorites: () {
                  allVM.toggleFavorite(songId);
                },

                /// 👉 Xóa khỏi yêu thích (nếu muốn dùng riêng)
                onRemoveFromFavorites: () {
                  allVM.toggleFavorite(songId);
                },

                /// 👉 Xóa bài hát
                onDelete: () {
                  songDeleteService.deleteSong(sObj);
                },
              );
            },
          );
        },
      ),
    );
  }
}
