import 'dart:math';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';
import 'package:music_player/view/main_player/play_playlist_view.dart';
import '../../common/color_extension.dart';

class DriverModeView extends StatefulWidget {
  const DriverModeView({super.key});

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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);

    return Dismissible(
      key: const Key("driverModelScreen"),
      direction: DismissDirection.down,
      background: const ColoredBox(color: Colors.transparent),
      onDismissed: (_) => Get.back(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: TColor.bg,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: Image.asset("assets/img/close.png", width: 20, height: 20),
          ),
          title: Text(
            "Driver Mode",
            style: TextStyle(color: TColor.primaryText80, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, __, ___) => const PlayPlayListView(),
                  )),
              icon: Image.asset("assets/img/playlist.png", width: 25, height: 25),
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
                    // ... artwork & slider code ...
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                        ValueListenableBuilder<ButtonState>(
                          valueListenable: pageManager.playButtonNotifier,
                          builder: (_, btnState, __) => IconButton(
                            icon: btnState == ButtonState.playing
                                ? Image.asset("assets/img/pause.png")
                                : Image.asset("assets/img/play.png"),
                            onPressed: () {
                              if (btnState == ButtonState.playing) {
                                pageManager.pause();
                              } else {
                                if (kIsWeb) {
                                  pageManager.playAS(mediaItem);
                                } else {
                                  pageManager.play();
                                }
                              }
                            },
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: pageManager.isLastSongNotifier,
                          builder: (_, isLast, __) => IconButton(
                            icon: Image.asset("assets/img/next_song.png",
                                color: isLast ? TColor.primaryText35 : TColor.primaryText),
                            onPressed: isLast ? null : pageManager.next,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
