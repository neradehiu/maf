// lib/audio_helpers/player_invoke.dart

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

  /// songsList: List<Map> – chính là playlist mà bạn truyền từ MainPlayerView
  /// index: vị trí của bài được chọn
  static Future<void> init({
    required List songsList,
    required int index,
    bool fromMiniPlayer = false,
    bool shuffle = false,
    String? playlistBox,
  }) async {
    final globalIndex = index < 0 ? 0 : index;
    final finalList = List<Map<String, dynamic>>.from(songsList);
    if (shuffle) finalList.shuffle();

    if (!fromMiniPlayer && !kIsWeb) {
      await pageManager.stop(); // Chỉ dừng audio_service trên non-web
    }

    await setValues(finalList, globalIndex);
  }

  static Future<void> setValues(List arr, int index,
      {bool recommend = false}) async {
    // Chuyển List<Map> thành List<MediaItem>
    final queue = arr
        .map((songMap) => MediaItemConverter.mapToMediaItem(
        songMap as Map<String, dynamic>,
        autoplay: recommend))
        .toList();

    await updateNPlay(queue, index);
  }

  static Future<void> updateNPlay(
      List<MediaItem>? queue, int index) async {
    try {
      if (queue == null || index < 0 || index >= queue.length) {
        debugPrint('⚠️ [PlayerInvoke] queue is null or index out of range');
        return;
      }

      // Fix từng MediaItem.id từ http:// → https:// nếu cần
      final fixedQueue = queue.map((item) {
        final rawUrl = item.id;
        final fixedUrl = rawUrl.startsWith('http://')
            ? rawUrl.replaceFirst('http://', 'https://')
            : rawUrl;
        debugPrint("🔧 [PlayerInvoke] rawUrl = $rawUrl → fixedUrl = $fixedUrl");
        return item.copyWith(id: fixedUrl);
      }).toList();

      final mediaItem = fixedQueue[index];
      if (mediaItem.id.isEmpty) {
        debugPrint('⚠️ [PlayerInvoke] mediaItem.id rỗng');
        return;
      }

      // Nếu chạy Web, ta cần truyền playlist + startIndex để Web quản lý đúng webPlaylist/webIndex
      if (kIsWeb) {
        debugPrint("▶️ [PlayerInvoke] Đang chạy Web, gọi playAS(url, playlist, startIndex)");
        await pageManager.playAS(
          mediaItem,
          playlist: fixedQueue,
          startIndex: index,
        );
        playerTapTime = DateTime.now();
        return;
      }

      // ------------------------------
      // Non‑Web (Android/iOS/desktop)
      // ------------------------------
      debugPrint("▶️ [PlayerInvoke] Đang chạy non‑Web, gọi setShuffleMode + adds + play");
      await pageManager.setShuffleMode(AudioServiceShuffleMode.none);
      await pageManager.adds(fixedQueue, index);
      pageManager.play();
      playerTapTime = DateTime.now();
    } catch (e, stack) {
      debugPrint('⚠️ [PlayerInvoke] Error playing audio: ${e.toString()}');
      debugPrint(stack.toString());
    }
  }
}
