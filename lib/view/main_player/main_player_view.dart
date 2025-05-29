import 'dart:math';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';
import 'package:music_player/services/song_service.dart';
import 'package:music_player/view/songs/song_delete_server.dart';
import 'package:music_player/common/color_extension.dart';
import 'package:music_player/common_widget/player_bottom_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:music_player/view/main_player/play_playlist_view.dart';
import 'package:music_player/view/main_player/driver_mode_view.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class MainPlayerView extends StatefulWidget {
  const MainPlayerView({super.key});

  @override
  State<MainPlayerView> createState() => _MainPlayerViewState();
}

class _MainPlayerViewState extends State<MainPlayerView> {
  int _shareCount = 0;
  late final PageManager pageManager;
  final songDeleteService = SongDeleteService();

  @override
  void initState() {
    super.initState();
    pageManager = getIt<PageManager>();
    pageManager.init();
    final mediaItem = pageManager.currentSongNotifier.value;
    if (mediaItem != null) {
      _loadShareCount(mediaItem.id);
    }
  }

  void _loadShareCount(String songId) async {
    try {
      final count = await SongService.getShareCount(songId);
      setState(() {
        _shareCount = count;
      });
    } catch (e) {
      debugPrint("❌ Lỗi khi tải số lượt chia sẻ: $e");
    }
  }

  /// Helper: convert mọi URL bắt đầu bằng "http://" sang "https://"
  String _ensureHttps(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dismissible(
      key: const Key("playScreen"),
      direction: DismissDirection.down,
      background: const ColoredBox(color: Colors.transparent),
      onDismissed: (_) => Get.back(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: TColor.bg,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: Image.asset("assets/img/back.png", width: 25, height: 25),
          ),
          title: Text(
            "Now Playing",
            style: TextStyle(
              color: TColor.primaryText80,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            PopupMenuButton<int>(
              color: const Color(0xff383B49),
              offset: const Offset(-10, 15),
              elevation: 1,
              icon: Image.asset(
                "assets/img/more_btn.png",
                width: 20,
                height: 20,
                color: Colors.white,
              ),
              onSelected: (selectIndex) {
                switch (selectIndex) {
                  case 1:
                    Share.share(
                        'Listening to ${pageManager.currentSongNotifier.value?.title}');
                    break;
                  case 2:
                    openPlayPlaylistQueue();
                    break;
                  case 9:
                    openDriverModel();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 1,
                    child: Text("Social Share",
                        style: TextStyle(fontSize: 12))),
                const PopupMenuItem(
                    value: 2,
                    child: Text("Playing Queue",
                        style: TextStyle(fontSize: 12))),
                const PopupMenuItem(
                    value: 9,
                    child: Text("Driver mode",
                        style: TextStyle(fontSize: 12))),
              ],
            ),
          ],
        ),
        body: ValueListenableBuilder<MediaItem?>(
          valueListenable: pageManager.currentSongNotifier,
          builder: (context, mediaItem, _) {
            if (mediaItem == null) return const SizedBox();
            return _buildPlayerContent(context, size, mediaItem);
          },
        ),
      ),
    );
  }

  Widget _buildPlayerContent(
      BuildContext context, Size size, MediaItem mediaItem) {
    String formatDuration(Duration duration) {
      final match = RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
          .firstMatch(duration.toString());
      return match?.group(1) ?? duration.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: mediaItem.extras?['image'] ?? '',
              width: size.width * 0.8,
              height: size.width * 0.8,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox(),
              errorWidget: (_, __, ___) => const Icon(Icons.music_note,
                  size: 80),
            ),
          ),
          const SizedBox(height: 20),
          // Progress slider
          ValueListenableBuilder<ProgressBarState>(
            valueListenable: pageManager.progressNotifier,
            builder: (_, progress, __) => SleekCircularSlider(
              min: 0,
              max: progress.total.inMilliseconds.toDouble(),
              initialValue: progress.current.inMilliseconds.toDouble(),
              onChangeEnd: (value) {
                pageManager.seek(Duration(milliseconds: value.toInt()));
              },
              innerWidget: (_) => Center(
                child: Text(
                  formatDuration(progress.current) +
                      " / " +
                      formatDuration(progress.total),
                  style:
                  TextStyle(color: TColor.primaryText, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Play controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: pageManager.isFirstSongNotifier,
                builder: (_, isFirst, __) => IconButton(
                  icon: Image.asset(
                    "assets/img/previous_song.png",
                    color: isFirst
                        ? TColor.primaryText35
                        : TColor.primaryText,
                  ),
                  onPressed: isFirst ? null : pageManager.previous,
                ),
              ),
              const SizedBox(width: 15),
              ValueListenableBuilder<ButtonState>(
                valueListenable: pageManager.playButtonNotifier,
                builder: (_, buttonState, __) {
                  if (buttonState == ButtonState.loading)
                    return const CircularProgressIndicator();
                  return InkWell(
                    onTap: () {
                      // Build playlist List<Map> trực tiếp từ dữ liệu ViewModel (allVM.allList)
                      final playlist = pageManager.playlistNotifier.value
                          .map((m) => {
                        'id': m.id,
                        'title': m.title,
                        'artist': m.artist,
                        'url': m.id, // id chính là URL đã được fix HTTPS
                      })
                          .toList();

                      // Nhưng nếu bạn muốn build playlist từ allVM.allList (nguyên bản),
                      // bạn có thể dùng đoạn “tham khảo” bên dưới (thay thế pageManager.playlistNotifier):
                      //
                      // final playlist = allVM.allList.map((song) {
                      //   return {
                      //     'id': song["id"]?.toString() ?? '',
                      //     'title': song["title"] ?? '',
                      //     'artist': song["artist"] ?? '',
                      //     'url': _ensureHttps(song["cloudinaryUrl"] ?? ''),
                      //   };
                      // }).toList();

                      final currentIndex =
                      pageManager.playlistNotifier.value.indexOf(mediaItem);
                      songDeleteService.onPressedPlay(
                          playlist, currentIndex);
                    },
                    child: Image.asset(
                      buttonState == ButtonState.playing
                          ? "assets/img/pause.png"
                          : "assets/img/play.png",
                      width: 60,
                      height: 60,
                    ),
                  );
                },
              ),
              const SizedBox(width: 15),
              ValueListenableBuilder<bool>(
                valueListenable: pageManager.isLastSongNotifier,
                builder: (_, isLast, __) => IconButton(
                  icon: Image.asset(
                    "assets/img/next_song.png",
                    color:
                    isLast ? TColor.primaryText35 : TColor.primaryText,
                  ),
                  onPressed: isLast ? null : pageManager.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bottom actions: Share count, favorites, queue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlayerBottomButton(
                title: 'Favorite',
                icon: 'assets/img/favorite.png',
                onPressed: () {}, // TODO: toggle favorite
              ),
              Row(
                children: [
                  PlayerBottomButton(
                    title: 'Share',
                    icon: 'assets/img/share.png',
                    onPressed: () =>
                        Share.share('Listening to ${mediaItem.title}'),
                  ),
                  const SizedBox(width: 4),
                  Text('$_shareCount',
                      style: TextStyle(color: TColor.primaryText)),
                ],
              ),
              PlayerBottomButton(
                title: 'Queue',
                icon: 'assets/img/playlist.png',
                onPressed: openPlayPlaylistQueue,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void openPlayPlaylistQueue() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const PlayPlayListView(),
      ),
    );
  }

  void openDriverModel() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const DriverModeView(),
      ),
    );
  }
}
