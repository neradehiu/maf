// file: lib/audio_helpers/player_invoke.dart

import 'dart:async';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:audio_service/audio_service.dart';
import 'package:music_player/audio_helpers/mediaitem_converter.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';

DateTime playerTapTime = DateTime.now();
Timer? debounce;

/// Debounce để tránh bấm play quá nhanh
void playerPlayProcessDebounce(List songsList, int index) {
  debounce?.cancel();
  debounce = Timer(const Duration(milliseconds: 600), () {
    PlayerInvoke.init(songsList: songsList, index: index);
  });
}

class PlayerInvoke {
  static final pageManager = getIt<PageManager>();

  /// Khởi tạo playback với danh sách và index
  static Future<void> init({
    required List songsList,
    required int index,
    bool fromMiniPlayer = false,
    bool shuffle = false,
    String? playlistBox,
  }) async {
    final int globalIndex = index < 0 ? 0 : index;
    final List finalList = songsList.toList();
    if (shuffle) finalList.shuffle();

    if (!fromMiniPlayer && !kIsWeb) {
      // Non-web: stop queue trước khi set mới
      await pageManager.stop();
    }
    await setValues(finalList, globalIndex);
  }

  /// Thiết lập queue và phát bài
  static Future<void> setValues(List arr, int index, {bool recommend = false}) async {
    final List<MediaItem> queue = arr
        .map((song) => MediaItemConverter.mapToMediaItem(song as Map, autoplay: recommend))
        .toList();
    await updateNPlay(queue, index);
  }

  /// Cập nhật queue và gọi play
  static Future<void> updateNPlay(List<MediaItem> queue, int index) async {
    try {
      // Tắt shuffle mode
      await pageManager.setShuffleMode(AudioServiceShuffleMode.none);
      // Set lại toàn bộ queue, bắt đầu từ index
      await pageManager.adds(queue, index);

      final mediaItem = queue[index];
      // Play tuỳ nền tảng
      if (kIsWeb) {
        await pageManager.playAS(mediaItem);
      } else {
        pageManager.play();
      }

      // Cập nhật thời điểm tap để debounce lần kế
      playerTapTime = DateTime.now();
    } catch (e, stack) {
      debugPrint('⚠️ Error playing audio: $e');
      debugPrint(stack.toString());
    }
  }
}
