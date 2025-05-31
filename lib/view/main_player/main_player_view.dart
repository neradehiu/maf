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
/// - Hiển thị Player (artwork, progress, controls)
/// - List bài hát để người dùng chọn
///
/// allSongsList: List<Map> dữ liệu bài hát từ API. Mỗi map gồm
///   id (số, string), title, artist, cloudinaryUrl (url MP3), imageUrl, album, genre, duration, user_id, album_id, v.v.
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
      // Lấy ID số từ extras để load shareCount
      final idNumber = mediaItem.extras?['songId']?.toString() ?? '';
      if (idNumber.isNotEmpty) {
        _loadShareCount(idNumber);
      }
    }

    // Lắng nghe mỗi khi bài hát thay đổi => cập nhật shareCount cho bài mới
    pageManager.currentSongNotifier.addListener(() {
      final cur = pageManager.currentSongNotifier.value;
      if (cur != null) {
        final idNumber = cur.extras?['songId']?.toString() ?? '';
        if (idNumber.isNotEmpty) {
          _loadShareCount(idNumber);
        }
      }
    });
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
    final media = MediaQuery.of(context).size;
    final pageManager = getIt<PageManager>();

    return Dismissible(
      key: const Key("playScreen"),
      direction: DismissDirection.down,
      background: const ColoredBox(color: Colors.transparent),
      onDismissed: (direction) {
        Get.back();
      },
      child: Stack(
        children: [
          // Ảnh nền
          Positioned.fill(
            child: Image.asset(
              "assets/img/bg_music.png", // Thay ảnh nền tại đây
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4), // Tối overlay
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent, // Rất quan trọng
            appBar: AppBar(
              backgroundColor: Colors.transparent,
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
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 1,
                      child: Text("Social Share", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 2,
                      child: Text("Playing Queue", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 3,
                      child: Text("Add to playlist...", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 4,
                      child: Text("Lyrics", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 5,
                      child: Text("Volume", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 6,
                      child: Text("Details", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 7,
                      child: Text("Sleep timer", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 8,
                      child: Text("Equaliser", style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 9,
                      child: Text("Driver mode", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            body: ValueListenableBuilder<MediaItem?>(
              valueListenable: pageManager.currentSongNotifier,
              builder: (context, mediaItem, _) {
                if (mediaItem == null) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Artwork + Circular Slider
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
                                  errorWidget: (_, __, ___) =>
                                      Image.asset("assets/img/cover.jpg"),
                                  placeholder: (_, __) =>
                                      Image.asset("assets/img/cover.jpg"),
                                ),
                              ),
                            ),
                            ValueListenableBuilder<ProgressBarState>(
                              valueListenable: pageManager.progressNotifier,
                              builder: (context, progress, _) {
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
                                          trackWidth: 4,
                                          progressBarWidth: 6,
                                          shadowWidth: 8),
                                      customColors: CustomSliderColors(
                                        dotColor: const Color(0xffFFB1B2),
                                        trackColor: Colors.white.withOpacity(0.3),
                                        progressBarColors: [
                                          const Color(0xffFB9967),
                                          const Color(0xffE9585A)
                                        ],
                                        shadowColor: const Color(0xffFFB1B2),
                                        shadowMaxOpacity: 0.05,
                                      ),
                                      infoProperties: InfoProperties(
                                        mainLabelStyle:
                                        const TextStyle(color: Colors.transparent),
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
                        // Hiển thị thời gian hiện tại và tổng
                        ValueListenableBuilder<ProgressBarState>(
                          valueListenable: pageManager.progressNotifier,
                          builder: (context, progress, _) {
                            String formatDuration(Duration duration) {
                              final match = RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                                  .firstMatch(duration.toString());
                              return match?.group(1) ?? duration.toString();
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formatDuration(progress.current),
                                  style: TextStyle(
                                      color: TColor.secondaryText, fontSize: 12),
                                ),
                                const Text(" | "),
                                Text(
                                  formatDuration(progress.total),
                                  style: TextStyle(
                                      color: TColor.secondaryText, fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 25),
                        // Tiêu đề & ca sĩ
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
                          "${mediaItem.artist} • Album - ${mediaItem.album}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        Image.asset("assets/img/eq_display.png",
                            height: 60, fit: BoxFit.fitHeight),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Colors.white12),
                        ),
                        // Các nút điều khiển (previous / play‑pause / next)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: pageManager.isFirstSongNotifier,
                              builder: (_, isFirst, __) => IconButton(
                                icon: Image.asset(
                                  "assets/img/previous_song.png",
                                  color:
                                  isFirst ? TColor.primaryText35 : TColor.primaryText,
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
                                      // Chỉ gọi play() vì webPlaylist đã set khi nhấn Play bên dưới
                                      pageManager.play();
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
                                  color:
                                  isLast ? TColor.primaryText35 : TColor.primaryText,
                                ),
                                onPressed: isLast ? null : pageManager.next,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Các nút phụ trợ: Playlist, Shuffle, Repeat, EQ, Share
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Playlist
                            IconButton(
                              icon: Image.asset("assets/img/playlist.png"),
                              onPressed: () {
                                openPlayPlaylistQueue();
                              },
                            ),
                            const SizedBox(width: 20),
                            // Shuffle
                            IconButton(
                              icon: Image.asset("assets/img/shuffle.png"),
                              onPressed: () {
                                // TODO: implement shuffle
                              },
                            ),
                            const SizedBox(width: 20),
                            // Repeat
                            IconButton(
                              icon: Image.asset("assets/img/repeat.png"),
                              onPressed: () {
                                // TODO: implement repeat
                              },
                            ),
                            const SizedBox(width: 20),
                            // EQ
                            IconButton(
                              icon: Image.asset("assets/img/eq.png"),
                              onPressed: () {
                                // TODO: implement EQ
                              },
                            ),
                            const SizedBox(width: 20),
                            // Share
                            Column(
                              children: [
                                PlayerBottomButton(
                                  title: "Share",
                                  icon: "assets/img/share1.png",
                                  onPressed: () async {
                                    final title = mediaItem.title;
                                    // Lấy ID số thực từ extras
                                    final songId =
                                        mediaItem.extras?['songId']?.toString() ?? '';

                                    print("📤 Share button clicked for songId: $songId");

                                    try {
                                      // Lấy token (nếu cần)
                                      final token = await SongService.getToken();

                                      // Gửi tăng share count
                                      await SongService.increaseShareCount(songId);

                                      // Lấy lại shareCount mới
                                      final updatedCount =
                                      await SongService.getShareCount(songId);

                                      // Cập nhật UI
                                      setState(() {
                                        _shareCount = updatedCount;
                                      });

                                      // Lấy share link (nếu có)
                                      final shareUrl =
                                      await SongService.getShareLink(songId, token);

                                      final message = (shareUrl != null &&
                                          shareUrl.isNotEmpty)
                                          ? "🎧 Listening to $title:\n$shareUrl"
                                          : "🎧 Listening to $title";

                                      // Gọi dialog share
                                      Share.share(message);
                                    } catch (e) {
                                      debugPrint("❌ Error sharing song: $e");
                                      // Fallback: chỉ share text
                                      Share.share("🎧 Listening to $title");
                                    }
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_shareCount shares',
                                  style:
                                  const TextStyle(fontSize: 12, color: Colors.grey),
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
              },
            ),
          ),
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
