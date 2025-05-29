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

  /// Nếu từ mini‐player, ta không reset queue; nếu không phải Web thì dừng audioService
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

  static Future<void> setValues(List arr, int index,
      {bool recommend = false}) async {
    final queue = arr
        .map((song) =>
        MediaItemConverter.mapToMediaItem(song as Map, autoplay: recommend))
        .toList();
    await updateNPlay(queue, index);
  }

  static Future<void> updateNPlay(
      List<MediaItem>? queue, int index) async {
    try {
      if (queue == null || index < 0 || index >= queue.length) {
        debugPrint('⚠️ queue is null or index out of range');
        return;
      }

      // Trước khi làm gì, hãy "fix" mỗi MediaItem.id (nếu bắt đầu bằng http://) → https://
      final fixedQueue = queue.map((item) {
        final rawUrl = item.id;
        final fixedUrl = rawUrl.startsWith('http://')
            ? rawUrl.replaceFirst('http://', 'https://')
            : rawUrl;
        return item.copyWith(id: fixedUrl);
      }).toList();

      final mediaItem = fixedQueue[index];
      if (mediaItem == null) {
        debugPrint('⚠️ mediaItem is null');
        return;
      }

      // Nếu chạy trên Web, chỉ cần playAS với fixedQueue
      if (kIsWeb) {
        await pageManager.playAS(mediaItem);
        playerTapTime = DateTime.now();
        return;
      }

      // Non‐web (mobile/desktop) vẫn dùng audio_service:
      await pageManager.setShuffleMode(AudioServiceShuffleMode.none);
      await pageManager.adds(fixedQueue, index);
      pageManager.play();
      playerTapTime = DateTime.now();
    } catch (e, stack) {
      debugPrint('⚠️ Error playing audio: ${e.toString()}');
      debugPrint(stack.toString());
    }
  }
}
