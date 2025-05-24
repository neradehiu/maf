// file: lib/view/main_player/main_player_view.dart
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
    // Initialize PageManager once, with platform-specific handler
    pageManager = getIt<PageManager>();
    if (!kIsWeb) {
      pageManager.init();
      final mediaItem = pageManager.currentSongNotifier.value;
      if (mediaItem != null) {
        _loadShareCount(mediaItem.id);
      }
    } else {
      // On web: use minimal or custom WebAudioHandler logic
      // No audio_service initialization
    }
  }

  void _loadShareCount(String songId) async {
    try {
      final count = await SongService.getShareCount(songId);
      setState(() {
        _shareCount = count;
      });
    } catch (e) {
      debugPrint("❌ Lỗi khi tải số lượt chia sẻ: \$e");
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
                      'Listening to \${pageManager.currentSongNotifier.value?.title}',
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
                const PopupMenuItem(value: 3, child: Text("Add to playlist...", style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 4, child: Text("Lyrics", style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 5, child: Text("Volume", style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 6, child: Text("Details", style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 7, child: Text("Sleep timer", style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 8, child: Text("Equaliser", style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 9, child: Text("Driver mode", style: TextStyle(fontSize: 12))),
              ],
            ),
          ],
        ),
        body: kIsWeb
            ? _buildWebPlaceholder()
            : ValueListenableBuilder<MediaItem?>(
          valueListenable: pageManager.currentSongNotifier,
          builder: (context, mediaItem, _) {
            if (mediaItem == null) return const SizedBox();
            return _buildPlayerContent(context, media, mediaItem);
          },
        ),
      ),
    );
  }

  Widget _buildWebPlaceholder() {
    return Center(
      child: Text(
        'Audio playback is limited on Web.\nPlease use a supported browser or platform.',
        textAlign: TextAlign.center,
        style: TextStyle(color: TColor.secondaryText, fontSize: 14),
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
            Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: "currentArtWork",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(media.width * 0.7),
                    child: CachedNetworkImage(
                      imageUrl: mediaItem.artUri.toString(),
                      width: media.width * 0.6,
                      height: media.width * 0.6,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Image.asset("assets/img/cover.jpg"),
                      placeholder: (_, __) => Image.asset("assets/img/cover.jpg"),
                    ),
                  ),
                ),
                ValueListenableBuilder<ProgressBarState>(
                  valueListenable: pageManager.progressNotifier,
                  builder: (context, progress, child) {
                    final double value = min(
                      progress.current.inMilliseconds.toDouble(),
                      progress.total.inMilliseconds.toDouble(),
                    );

                    return SizedBox(
                      width: media.width * 0.61,
                      height: media.width * 0.61,
                      child: SleekCircularSlider(
                        appearance: CircularSliderAppearance(
                          customWidths: CustomSliderWidths(
                              trackWidth: 4, progressBarWidth: 6, shadowWidth: 8),
                          customColors: CustomSliderColors(
                            dotColor: const Color(0xffFFB1B2),
                            trackColor: Colors.white.withOpacity(0.3),
                            progressBarColors: [Color(0xffFB9967), Color(0xffE9585A)],
                            shadowColor: const Color(0xffFFB1B2),
                            shadowMaxOpacity: 0.05,
                          ),
                          infoProperties: InfoProperties(
                            mainLabelStyle: const TextStyle(color: Colors.transparent),
                          ),
                          startAngle: 270,
                          angleRange: 360,
                          size: 350.0,
                        ),
                        min: 0,
                        max: progress.total.inMilliseconds.toDouble(),
                        initialValue: value,
                        onChange: (val) {
                          pageManager.seek(Duration(milliseconds: val.round()));
                        },
                        onChangeEnd: (val) {
                          pageManager.seek(Duration(milliseconds: val.round()));
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<ProgressBarState>(
              valueListenable: pageManager.progressNotifier,
              builder: (context, progress, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(formatDuration(progress.current),
                        style: TextStyle(color: TColor.secondaryText, fontSize: 12)),
                    const Text(" | "),
                    Text(formatDuration(progress.total),
                        style: TextStyle(color: TColor.secondaryText, fontSize: 12)),
                  ],
                );
              },
            ),
            const SizedBox(height: 25),
            Text(
              mediaItem.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: TColor.primaryText.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              "\${mediaItem.artist} • Album - \${mediaItem.album}",
              textAlign: TextAlign.center,
              style: TextStyle(color: TColor.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Image.asset("assets/img/eq_display.png", height: 60, fit: BoxFit.fitHeight),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white12),
            ),
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
                        buttonState == ButtonState.playing
                            ? pageManager.pause()
                            : pageManager.play();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayerBottomButton(title: "Playlist", icon: "assets/img/playlist.png", onPressed: openPlayPlaylistQueue),
                PlayerBottomButton(title: "Shuffle", icon: "assets/img/shuffle.png", onPressed: () {}),
                PlayerBottomButton(title: "Repeat", icon: "assets/img/repeat.png", onPressed: () {}),
                PlayerBottomButton(title: "EQ", icon: "assets/img/eq.png", onPressed: () {}),
                Column(
                  children: [
                    PlayerBottomButton(
                      title: "Share",
                      icon: "assets/img/share1.png",
                      onPressed: () async {
                        final title = mediaItem.title;
                        final songId = mediaItem.id;

                        debugPrint("📤 Share button clicked for songId: \$songId");

                        try {
                          final token = await SongService.getToken();
                          await SongService.increaseShareCount(songId);

                          // Update share count
                          final updatedCount = await SongService.getShareCount(songId);
                          setState(() {
                            _shareCount = updatedCount;
                          });

                          final shareUrl = await SongService.getShareLink(songId, token);
                          final message = shareUrl != null
                              ? "🎧 Listening to \$title:\n\$shareUrl"
                              : "🎧 Listening to \$title";

                          Share.share(message);
                        } catch (e) {
                          debugPrint("❌ Error sharing song: \$e");
                          Share.share("🎧 Listening to \$title");
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$_shareCount shares',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
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