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
// Gọi lại fetchAllSongs nếu cần thiết
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
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
            final isLiked = sObj['isLiked'] == true;

            return AllSongRow(
              sObj: sObj,
              isWeb: true,
              isFavorite: isFavorite,
              isLiked: isLiked,
              onPressedPlay: () async {
                final playlist = allVM.allList.map((song) {
                  final rawUrl = song["cloudinaryUrl"] ?? '';
                  final fixedUrl =
                      rawUrl.toString().replaceFirst("http://", "https://");

                  return {
                    'id': song["id"]?.toString() ?? '',
                    'title': song["title"] ?? '',
                    'artist': song["artist"] ?? '',
                    'album': '',
                    'genre': song["genre"] ?? '',
                    'image': '',
                    'url': fixedUrl,
                    'user_id': song["userId"] ?? '',
                    'user_name': song["artist"] ?? '',
                    'duration': song["duration"] ?? '180',
                    'language': song["genre"] ?? '',
                    'album_id': song["album_id"] ?? '',
                  };
                }).toList();

                await allVM.incrementView(songId);

                songDeleteService.onPressedPlay(playlist, index);
              },

              onToggleFavorite: () async {
                final liked = await allVM.toggleLike(songId);
                if (liked != null) {
                  setState(() {
                    sObj['isLiked'] = liked;
                  });
                }
              },

              onAddToFavorites: () async {
                final isNowFavorite = await allVM.toggleFavorite(songId);
                setState(() {
                  sObj['isFavorite'] = isNowFavorite;
                });
              },

              onRemoveFromFavorites: () async {
                final isNowFavorite = await allVM.toggleFavorite(songId);
                setState(() {
                  sObj['isFavorite'] = isNowFavorite;
                });
              },

              onDelete: () {
                songDeleteService.deleteSong(sObj);
              },
            );
          },
        );
      }),
    );
  }
}
