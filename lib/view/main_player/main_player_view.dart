import 'dart:math';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';
import 'package:music_player/common_widget/player_bottom_button.dart';
import 'package:music_player/view/main_player/driver_mode_view.dart';
import 'package:music_player/view/main_player/play_playlist_view.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:music_player/services/song_service.dart';
import '../../common/color_extension.dart';

class MainPlayerView extends StatefulWidget {
  const MainPlayerView({super.key});

  @override
  State<MainPlayerView> createState() => _MainPlayerViewState();
}

class _MainPlayerViewState extends State<MainPlayerView> {
  int _shareCount = 0;
  late final PageManager pageManager;

  @override
  void initState() {
    super.initState();
    pageManager = getIt<PageManager>();
    // Always init streams & listeners, even on Web
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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);

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
                      'Listening to ${pageManager.currentSongNotifier.value?.title}',
                    );
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
                const PopupMenuItem(value: 1, child: Text("Social Share", style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 2, child: Text("Playing Queue", style: TextStyle(fontSize: 12))),
                // ...
                const PopupMenuItem(value: 9, child: Text("Driver mode", style: TextStyle(fontSize: 12))),
              ],
            ),
          ],
        ),
        body: ValueListenableBuilder<MediaItem?>(
          valueListenable: pageManager.currentSongNotifier,
          builder: (context, mediaItem, _) {
            if (mediaItem == null) return const SizedBox();
            return _buildPlayerContent(context, media, mediaItem);
          },
        ),
      ),
    );
  }

  Widget _buildPlayerContent(
      BuildContext context,
      Size media,
      MediaItem mediaItem,
      ) {
    String formatDuration(Duration duration) {
      final match = RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
          .firstMatch(duration.toString());
      return match?.group(1) ?? duration.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // ... artwork & progress indicator ...
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: pageManager.isFirstSongNotifier,
                  builder: (_, isFirst, __) => IconButton(
                    icon: Image.asset(
                      "assets/img/previous_song.png",
                      color: isFirst ? TColor.primaryText35 : TColor.primaryText,
                    ),
                    onPressed: isFirst ? null : pageManager.previous,
                  ),
                ),
                const SizedBox(width: 15),
                ValueListenableBuilder<ButtonState>(
                  valueListenable: pageManager.playButtonNotifier,
                  builder: (_, buttonState, __) {
                    if (buttonState == ButtonState.loading) {
                      return const CircularProgressIndicator();
                    }
                    return InkWell(
                      onTap: () {
                        if (buttonState == ButtonState.playing) {
                          pageManager.pause();
                        } else {
                          // On Web call playAS, on non-web call play()
                          if (kIsWeb) {
                            pageManager.playAS(mediaItem);
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
                    icon: Image.asset(
                      "assets/img/next_song.png",
                      color: isLast ? TColor.primaryText35 : TColor.primaryText,
                    ),
                    onPressed: isLast ? null : pageManager.next,
                  ),
                ),
              ],
            ),
            // ... bottom buttons, share count, etc. ...
          ],
        ),
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
