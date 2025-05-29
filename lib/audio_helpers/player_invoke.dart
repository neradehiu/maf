import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_player/audio_helpers/mediaitem_converter.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';

DateTime playerTapTime = DateTime.now();
Timer? debounce;

void playerPlayProcessDebounce(List songsList, int index) {
  debounce?.cancel();
  debounce = Timer(const Duration(milliseconds: 600), () {
    PlayerInvoke.init(songsList: songsList, index: index);
  });
}

class PlayerInvoke {
  static final pageManager = getIt<PageManager>();

  static Future<void> init({
    required List songsList,
    required int index,
    bool fromMiniPlayer = false,
    bool shuffle = false,
    String? playlistBox,
  }) async {
    final globalIndex = index < 0 ? 0 : index;
    final finalList = songsList.toList();
    if (shuffle) finalList.shuffle();

    if (!fromMiniPlayer && !kIsWeb) {
      await pageManager.stop();
    }
    await setValues(finalList, globalIndex);
  }

  static Future<void> setValues(List arr, int index, {bool recommend = false}) async {
    final queue = arr
        .map((song) => MediaItemConverter.mapToMediaItem(song as Map, autoplay: recommend))
        .toList();
    await updateNPlay(queue, index);
  }

  static Future<void> updateNPlay(List<MediaItem>? queue, int index) async {
    try {
      if (queue == null || index < 0 || index >= queue.length) {
        debugPrint('⚠️ queue is null or index out of range');
        return;
      }

      final mediaItem = queue[index];
      if (mediaItem == null) {
        debugPrint('⚠️ mediaItem is null');
        return;
      }

      await pageManager.setShuffleMode(AudioServiceShuffleMode.none);
      await pageManager.adds(queue, index);

      if (kIsWeb) {
        await pageManager.playAS(mediaItem);
      } else {
        pageManager.play();
      }

      playerTapTime = DateTime.now();
    } catch (e, stack) {
      debugPrint('⚠️ Error playing audio: ${e.toString()}');
      debugPrint(stack.toString());
    }
  }
}
