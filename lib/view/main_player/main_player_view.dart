// lib/view/main_player/main_player_view.dart

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

/// MainPlayerView bao gồm 2 phần chính:
/// - Phần hiển thị Player (artwork, progress, controls)
/// - Phần list bài hát để người dùng chọn
///
/// allSongsList là List<Map> chứa dữ liệu bài hát từ API.
/// Nếu không truyền vào, mặc định nó sẽ là List rỗng.
class MainPlayerView extends StatefulWidget {
  final List<Map<String, dynamic>> allSongsList;

  const MainPlayerView({
    Key? key,
    this.allSongsList = const [],
  }) : super(key: key);

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

  /// Helper: chuyển mọi URL nếu bắt đầu bằng "http://" → "https://"
  String _ensureHttps(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.bg,
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
      ),
      body: Column(
        children: [
          // Nếu currentSongNotifier null → hiển thị hướng dẫn hoặc text
          Expanded(
            child: ValueListenableBuilder<MediaItem?>(
              valueListenable: pageManager.currentSongNotifier,
              builder: (context, mediaItem, _) {
                if (mediaItem == null) {
                  return Center(
                    child: Text("Chưa có bài nào được chọn",
                        style: TextStyle(color: TColor.primaryText)),
                  );
                }
                return _buildPlayerContent(context, size, mediaItem);
              },
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // ListView các bài hát (dùng trực tiếp widget.allSongsList)
          Expanded(
            child: ListView.builder(
              itemCount: widget.allSongsList.length,
              itemBuilder: (context, index) {
                final songMap = widget.allSongsList[index];
                final rawUrl = (songMap["cloudinaryUrl"] as String?) ?? '';
                final fixedUrl = _ensureHttps(rawUrl);

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: songMap["imageUrl"] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(),
                      errorWidget: (_, __, ___) =>
                      const Icon(Icons.music_note),
                    ),
                  ),
                  title: Text(
                    songMap["title"] ?? "",
                    style: TextStyle(color: TColor.primaryText),
                  ),
                  subtitle: Text(
                    songMap["artist"] ?? "",
                    style: TextStyle(color: TColor.primaryText35),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.play_circle_fill,
                      color: TColor.primaryText,
                    ),
                    onPressed: () {
                      // Khi user bấm play 1 bài, dựng playlist từ allSongsList
                      final playlist = widget.allSongsList.map((song) {
                        return {
                          'id': (song["id"]?.toString() ?? ''),
                          'title': song["title"] ?? '',
                          'artist': song["artist"] ?? '',
                          'url': _ensureHttps(song["cloudinaryUrl"] ?? ''),
                          // thêm nếu cần album, genre, v.v.
                        };
                      }).toList();

                      debugPrint("▶️ Đang play bài index = $index");
                      debugPrint("▶️ Playlist = $playlist");

                      songDeleteService.onPressedPlay(playlist, index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // ------- Artwork -------
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: mediaItem.extras?['image'] ?? '',
              width: size.width * 0.8,
              height: size.width * 0.8,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox(),
              errorWidget: (_, __, ___) =>
              const Icon(Icons.music_note, size: 80),
            ),
          ),
          const SizedBox(height: 20),

          // ------- Progress slider -------
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
                  "${formatDuration(progress.current)} / ${formatDuration(progress.total)}",
                  style: TextStyle(color: TColor.primaryText, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ------- Play controls -------
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
                      if (buttonState == ButtonState.playing) {
                        pageManager.pause();
                      } else {
                        if (kIsWeb) {
                          final current =
                              pageManager.currentSongNotifier.value;
                          if (current != null) {
                            pageManager.playAS(current);
                          }
                        } else {
                          pageManager.play();
                        }
                      }
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
                  icon: Image.asset("assets/img/next_song.png",
                      color: isLast
                          ? TColor.primaryText35
                          : TColor.primaryText),
                  onPressed: isLast ? null : pageManager.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ------- Bottom actions: Share, Favorite, Queue -------
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
                onPressed: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, __, ___) => const PlayPlayListView(),
                  ),
                ),
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
