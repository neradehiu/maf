// lib/view/main_player/driver_mode_view.dart

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';
import 'package:music_player/common/color_extension.dart';
import 'package:music_player/common_widget/control_buttons.dart';
import 'package:music_player/view/main_player/main_player_view.dart';
import 'package:music_player/view/main_player/play_playlist_view.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

/// DriverModeView: giao diện đơn giản cho Driver Mode.
/// Loại bỏ Dismissible (vuốt) và PageRouteBuilder(opaque:false) để hỗ trợ Web.
class DriverModeView extends StatefulWidget {
  const DriverModeView({Key? key}) : super(key: key);

  @override
  State<DriverModeView> createState() => _DriverModeViewState();
}

class _DriverModeViewState extends State<DriverModeView> {
  late final PageManager pageManager;

  @override
  void initState() {
    super.initState();
    pageManager = getIt<PageManager>();
    pageManager.init(); // đảm bảo cả Web cũng có listener
  }

  /// Helper: chuyển "http://" → "https://"
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
          onPressed: () => Navigator.of(context).pop(),
          icon: Image.asset("assets/img/close.png", width: 20, height: 20),
        ),
        title: Text(
          "Driver Mode",
          style: TextStyle(
            color: TColor.primaryText80,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayPlayListView()),
              );
            },
            icon: Image.asset("assets/img/playlist.png", width: 25, height: 25),
          ),
        ],
      ),
      body: ValueListenableBuilder<MediaItem?>(
        valueListenable: pageManager.currentSongNotifier,
        builder: (context, mediaItem, _) {
          if (mediaItem == null) {
            return Center(
              child: Text(
                "Chưa có bài nào đang phát",
                style: TextStyle(color: TColor.primaryText),
              ),
            );
          }

          // Nếu có mediaItem, hiển thị artwork, slider, controls
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // ------- Artwork với Circular Slider -------
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(size.width * 0.5),
                        child: CachedNetworkImage(
                          imageUrl:
                          _ensureHttps(mediaItem.artUri.toString()),
                          width: size.width * 0.6,
                          height: size.width * 0.6,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Image.asset("assets/img/cover.jpg",
                                  width: size.width * 0.6,
                                  height: size.width * 0.6,
                                  fit: BoxFit.cover),
                          errorWidget: (_, __, ___) =>
                              Image.asset("assets/img/cover.jpg",
                                  width: size.width * 0.6,
                                  height: size.width * 0.6,
                                  fit: BoxFit.cover),
                        ),
                      ),
                      Positioned.fill(
                        child: ValueListenableBuilder<ProgressBarState>(
                          valueListenable: pageManager.progressNotifier,
                          builder: (_, progress, __) {
                            final double currentMs =
                            progress.current.inMilliseconds
                                .toDouble()
                                .clamp(0.0,
                                progress.total.inMilliseconds.toDouble());
                            return SleekCircularSlider(
                              min: 0,
                              max: progress.total.inMilliseconds.toDouble(),
                              initialValue: currentMs,
                              appearance: CircularSliderAppearance(
                                customWidths: CustomSliderWidths(
                                  trackWidth: 4,
                                  progressBarWidth: 6,
                                  shadowWidth: 8,
                                ),
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
                                size: size.width * 0.7,
                              ),
                              onChange: (val) {
                                pageManager
                                    .seek(Duration(milliseconds: val.toInt()));
                              },
                              onChangeEnd: (val) {
                                pageManager
                                    .seek(Duration(milliseconds: val.toInt()));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ------- Hiển thị thời gian hiện tại và tổng -------
                  ValueListenableBuilder<ProgressBarState>(
                    valueListenable: pageManager.progressNotifier,
                    builder: (context, progress, __) {
                      String format(Duration d) {
                        final match = RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                            .firstMatch(d.toString());
                        return match?.group(1) ?? d.toString();
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            format(progress.current),
                            style: TextStyle(
                                color: TColor.secondaryText, fontSize: 12),
                          ),
                          const Text(" | "),
                          Text(
                            format(progress.total),
                            style: TextStyle(
                                color: TColor.secondaryText, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  // ------- Tiêu đề & Ca sĩ -------
                  Text(
                    mediaItem.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TColor.primaryText.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${mediaItem.artist} • Album: ${mediaItem.album}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: TColor.secondaryText, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  // ------- Thanh điều khiển chính: previous / play‑pause / next -------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: pageManager.isFirstSongNotifier,
                        builder: (_, isFirst, __) => IconButton(
                          icon: Image.asset(
                            "assets/img/b_player_previous.png",
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
                          if (buttonState == ButtonState.loading) {
                            return const CircularProgressIndicator();
                          }
                          return InkWell(
                            onTap: () {
                              if (buttonState == ButtonState.playing) {
                                pageManager.pause();
                              } else {
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
                            "assets/img/b_player_next.png",
                            color: isLast
                                ? TColor.primaryText35
                                : TColor.primaryText,
                          ),
                          onPressed: isLast ? null : pageManager.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ------- Các nút phụ trợ: Playlist, Shuffle, Repeat, EQ, Share -------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Playlist
                      IconButton(
                        icon: Image.asset("assets/img/playlist.png"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PlayPlayListView()),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      // Shuffle (chưa implement)
                      IconButton(
                        icon: Image.asset("assets/img/shuffle.png"),
                        onPressed: () {
                          // TODO: thêm chức năng shuffle
                        },
                      ),
                      const SizedBox(width: 20),
                      // Repeat (chưa implement)
                      IconButton(
                        icon: Image.asset("assets/img/repeat.png"),
                        onPressed: () {
                          // TODO: thêm chức năng repeat
                        },
                      ),
                      const SizedBox(width: 20),
                      // EQ (chưa implement)
                      IconButton(
                        icon: Image.asset("assets/img/eq.png"),
                        onPressed: () {
                          // TODO: thêm chức năng EQ
                        },
                      ),
                      const SizedBox(width: 20),
                      // Share (chưa implement chi tiết)
                      IconButton(
                        icon: Image.asset("assets/img/share1.png"),
                        onPressed: () {
                          // TODO: thêm chức năng chia sẻ
                        },
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
    );
  }
}
