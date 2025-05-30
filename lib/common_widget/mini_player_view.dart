import 'dart:ui' as ui;
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';
import 'package:music_player/common/color_extension.dart';
import 'package:music_player/common_widget/control_buttons.dart';
import 'package:music_player/view/main_player/main_player_view.dart';

/// MiniPlayerView: giao diện nổi hiển thị bài hát đang phát.
/// Đã bỏ Dismissible (vuốt) để đơn giản hoá trên Web.
/// MiniPlayer chỉ phụ thuộc vào currentSongNotifier (có bài thì hiển thị).
class MiniPlayerView extends StatefulWidget {
  static const MiniPlayerView _instance = MiniPlayerView._internal();

  factory MiniPlayerView() {
    return _instance;
  }
  const MiniPlayerView._internal();

  @override
  State<MiniPlayerView> createState() => _MiniPlayerViewState();
}

class _MiniPlayerViewState extends State<MiniPlayerView> {
  @override
  void initState() {
    super.initState();
    // pageManager.addListener nếu cần
  }

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();

    // Chỉ dựa vào currentSongNotifier để hiện mini‑player (bỏ điều kiện processingState)
    return ValueListenableBuilder<MediaItem?>(
      valueListenable: pageManager.currentSongNotifier,
      builder: (context, mediaItem, __) {
        if (mediaItem == null) {
          return const SizedBox();
        }

        // Nếu có bài đang play, hiển thị mini‑player ở dưới
        return Align(
          alignment: Alignment.bottomCenter,
          child: Card(
            margin: const EdgeInsets.all(0),
            color: Colors.black12,
            elevation: 4,
            child: SizedBox(
              height: 80.0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Row(
                    children: [
                      // ► Ảnh đại diện và Title/Artist
                      GestureDetector(
                        onTap: () {
                          // Mở full player khi tap vào phần này
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainPlayerView(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: mediaItem.artUri.toString(),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) => Image.asset(
                                  "assets/img/cover.jpg",
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                ),
                                errorWidget: (ctx, url, error) => Image.asset(
                                  "assets/img/cover.jpg",
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.5,
                                  child: Text(
                                    mediaItem.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TColor.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.5,
                                  child: Text(
                                    mediaItem.artist ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TColor.primaryText35,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ► Play/Pause + Next
                      const Spacer(),
                      ControlButtons(
                        miniPlayer: true,
                        buttons: ['Play/Pause', 'Next'],
                      ),
                      const SizedBox(width: 8),

                      // ► Nút tắt mini‑player
                      IconButton(
                        icon: Icon(Icons.close, color: TColor.primaryText),
                        onPressed: () {
                          pageManager.stop();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
