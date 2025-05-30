import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/audio_helpers/audio_handler.dart';
import 'package:music_player/audio_helpers/service_locator.dart';

enum ButtonState { paused, playing, loading }

class PlayButtonNotifier extends ValueNotifier<ButtonState> {
  PlayButtonNotifier() : super(ButtonState.paused);
}

class ProgressBarState {
  final Duration current;
  final Duration buffered;
  final Duration total;

  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
}

class ProgressNotifier extends ValueNotifier<ProgressBarState> {
  ProgressNotifier()
      : super(ProgressBarState(
    current: Duration.zero,
    buffered: Duration.zero,
    total: Duration.zero,
  ));
}

enum RepeatState { off, repeatSong, repeatPlaylist }

class RepeatButtonNotifier extends ValueNotifier<RepeatState> {
  RepeatButtonNotifier() : super(RepeatState.off);
  void nextState() {
    value = RepeatState.values[(value.index + 1) % RepeatState.values.length];
  }
}

class PageManager {
  // Notifiers
  final currentSongNotifier = ValueNotifier<MediaItem?>(null);
  final playbackStatNotifier =
  ValueNotifier<AudioProcessingState>(AudioProcessingState.idle);
  final playlistNotifier = ValueNotifier<List<MediaItem>>([]);
  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final playButtonNotifier = PlayButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  // Underlying player or handler
  AudioPlayer? _player; // just_audio dùng cho Web
  AudioPlayerHandler? audioHandler; // audio_service dùng cho non-Web

  // Đặc thù cho Web: giữ playlist dạng MediaItem và index đang phát
  List<MediaItem> webPlaylist = [];
  int webIndex = 0;

  PageManager() {
    if (kIsWeb) {
      // Web: chỉ khởi tạo just_audio
      _player = AudioPlayer();
      audioHandler = null;
      _initWebListeners();
    } else {
      // Mobile/Desktop: audio_service
      try {
        audioHandler = getIt<AudioHandler>() as AudioPlayerHandler;
        _player = null;
      } catch (e) {
        throw Exception(
          "audioHandler chưa được khởi tạo. Bạn cần gọi setupServiceLocator() trước.\nChi tiết: $e",
        );
      }
    }
  }

  /// Chỉ gọi trên non-web để gắn các listener của audio_service
  void init() {
    if (kIsWeb) return;
    _listenToChangeInPlaylist();
    _listenToPlayBackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalPosition();
    _listenToChangesInSong();
  }

  //===========================================================================
  // Web-specific: just_audio listeners
  //===========================================================================

  void _initWebListeners() {
    // Play/pause state
    _player!.playbackEventStream.listen((_) {
      playButtonNotifier.value =
      _player!.playing ? ButtonState.playing : ButtonState.paused;
    });
    // Dòng vị trí hiện tại
    _player!.positionStream.listen((pos) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: pos,
        buffered: old.buffered,
        total: old.total,
      );
    });
    // Dòng vị trí đã buffer
    _player!.bufferedPositionStream.listen((buffered) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: old.current,
        buffered: buffered,
        total: old.total,
      );
    });
    // Dòng tổng độ dài (duration)
    _player!.durationStream.listen((duration) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: old.current,
        buffered: old.buffered,
        total: duration ?? Duration.zero,
      );
    });
  }

  //===========================================================================
  // Non-web: audio_service listeners
  //===========================================================================

  void _listenToChangeInPlaylist() {
    _checkAudioHandler();
    audioHandler!.queue.listen((playlist) {
      playlistNotifier.value = playlist;
      _updateSkipButton();
    });
  }

  void _updateSkipButton() {
    _checkAudioHandler();
    final mediaItem = audioHandler!.mediaItem.value;
    final playlist = audioHandler!.queue.value;
    if (playlist.isEmpty || mediaItem == null) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = playlist.first == mediaItem;
      isLastSongNotifier.value = playlist.last == mediaItem;
    }
  }

  void _listenToPlayBackState() {
    _checkAudioHandler();
    audioHandler!.playbackState.listen((state) {
      playbackStatNotifier.value = state.processingState;
      if (state.processingState == AudioProcessingState.loading ||
          state.processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!state.playing) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (state.processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        audioHandler!.seek(Duration.zero);
        audioHandler!.pause();
      }
    });
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: old.buffered,
        total: old.total,
      );
    });
  }

  void _listenToBufferedPosition() {
    _checkAudioHandler();
    audioHandler!.playbackState.listen((state) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: old.current,
        buffered: state.bufferedPosition,
        total: old.total,
      );
    });
  }

  void _listenToTotalPosition() {
    _checkAudioHandler();
    audioHandler!.mediaItem.listen((mediaItem) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: old.current,
        buffered: old.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      );
    });
  }

  void _listenToChangesInSong() {
    _checkAudioHandler();
    audioHandler!.mediaItem.listen((mediaItem) {
      currentSongNotifier.value = mediaItem;
      _updateSkipButton();
    });
  }

  //===========================================================================
  // Utility
  //===========================================================================

  void _checkAudioHandler() {
    if (audioHandler == null) {
      throw Exception(
          "audioHandler chưa được khởi tạo. Bạn cần gọi setupServiceLocator() trước.");
    }
  }

  // Cập nhật trạng thái nút Previous/Next trên Web
  void _updateWebSkipButtons() {
    if (webPlaylist.isEmpty) {
      isFirstSongNotifier.value = true;
      isLastSongNotifier.value = true;
    } else {
      isFirstSongNotifier.value = (webIndex == 0);
      isLastSongNotifier.value = (webIndex == webPlaylist.length - 1);
    }
  }

  //===========================================================================
  // Controls (common)
  //===========================================================================

  /// Play (non-web)
  void play() {
    if (kIsWeb) {
      _player!.play();
    } else {
      _checkAudioHandler();
      audioHandler!.play();
    }
  }

  /// Pause
  void pause() {
    if (kIsWeb) {
      _player!.pause();
    } else {
      _checkAudioHandler();
      audioHandler!.pause();
    }
  }

  /// Seek to [position]
  void seek(Duration position) {
    if (kIsWeb) {
      _player!.seek(position);
    } else {
      _checkAudioHandler();
      audioHandler!.seek(position);
    }
  }

  /// Stop playback, clear queue
  Future<void> stop() async {
    if (kIsWeb) {
      await _player!.stop();
      await _player!.seek(Duration.zero);
      currentSongNotifier.value = null;
      return;
    }

    _checkAudioHandler();
    await audioHandler!.stop();
    await audioHandler!.seek(Duration.zero);
    currentSongNotifier.value = null;
    await removeAll();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Previous track
  void previous() {
    if (kIsWeb) {
      if (webPlaylist.isEmpty) return;
      webIndex = (webIndex - 1).clamp(0, webPlaylist.length - 1);
      _playCurrentWebItem();
      _updateWebSkipButtons();
    } else {
      _checkAudioHandler();
      audioHandler!.skipToPrevious();
    }
  }

  /// Next track
  void next() {
    if (kIsWeb) {
      if (webPlaylist.isEmpty) return;
      webIndex = (webIndex + 1).clamp(0, webPlaylist.length - 1);
      _playCurrentWebItem();
      _updateWebSkipButtons();
    } else {
      _checkAudioHandler();
      audioHandler!.skipToNext();
    }
  }

  /// Set shuffle mode (non-web)
  Future<void> setShuffleMode(AudioServiceShuffleMode value) async {
    if (kIsWeb) return;
    isShuffleModeEnabledNotifier.value = value == AudioServiceShuffleMode.all;
    return await audioHandler!.setShuffleMode(value);
  }

  /// Add a single item (non-web)
  Future<void> add(MediaItem item) async {
    if (kIsWeb) return;
    _checkAudioHandler();
    await audioHandler!.addQueueItem(item);
  }

  /// Add multiple, bắt đầu từ [index] (non-web)
  Future<void> adds(List<MediaItem> items, int index) async {
    if (kIsWeb) return;
    _checkAudioHandler();
    if (items.isEmpty) return;
    await (audioHandler as AudioPlayerHandler).setNewPlaylist(items, index);
  }

  /// Update queue wholesale (non-web)
  Future<void> updateQueue(List<MediaItem> queue) async {
    if (kIsWeb) return;
    _checkAudioHandler();
    await audioHandler!.updateQueue(queue);
  }

  Future<void> skipToQueueItem(int index) async {
    if (kIsWeb) return;
    _checkAudioHandler();
    return await audioHandler!.skipToQueueItem(index);
  }

  /// Update single MediaItem (non-web)
  Future<void> updateMediaItem(MediaItem item) async {
    if (kIsWeb) return;
    _checkAudioHandler();
    await audioHandler!.updateMediaItem(item);
  }

  /// Move item in queue (non-web)
  Future<void> moveMediaItem(int oldIndex, int newIndex) async {
    if (kIsWeb) return;
    _checkAudioHandler();
    await (audioHandler as AudioPlayerHandler).moveQueueItem(oldIndex, newIndex);
  }

  /// Remove at [index] (non-web)
  Future<void> removeQueueItemAt(int index) async {
    if (kIsWeb) return;
    _checkAudioHandler();
    await (audioHandler as AudioPlayerHandler).removeQueueItemIndex(index);
  }

  /// Remove last item (non-web)
  void remove() {
    if (kIsWeb) return;
    _checkAudioHandler();
    final last = audioHandler!.queue.value.length - 1;
    if (last < 0) return;
    audioHandler!.removeQueueItemAt(last);
  }

  /// Clear all (non-web)
  Future<void> removeAll() async {
    if (kIsWeb) return;
    _checkAudioHandler();
    final last = audioHandler!.queue.value.length - 1;
    if (last < 0) return;
    audioHandler!.removeQueueItemAt(last);
  }

  //===========================================================================
  // Web playback
  //===========================================================================

  /// Play a MediaItem (Web). Nếu có playlist + startIndex, lưu lại
  Future<void> playAS(
      MediaItem mediaItem, {
        List<MediaItem>? playlist,
        int? startIndex,
      }) async {
    if (!kIsWeb) return;

    // Nếu truyền playlist cùng index, cập nhật webPlaylist/webIndex
    if (playlist != null && startIndex != null) {
      webPlaylist = playlist;
      webIndex = startIndex.clamp(0, playlist.length - 1);
    }

    // Nếu chưa có webPlaylist, chỉ play một item
    if (webPlaylist.isEmpty) {
      webPlaylist = [mediaItem];
      webIndex = 0;
    }

    try {
      final url = webPlaylist[webIndex].id;
      await _player!.setUrl(url);
      currentSongNotifier.value = webPlaylist[webIndex];
      await _player!.play();
      // Cập nhật trạng thái nút Previous/Next
      _updateWebSkipButtons();
    } catch (e) {
      print('Lỗi khi playAS trên Web: $e');
    }
  }

  /// Phát lại item hiện tại (Web, nội bộ)
  void _playCurrentWebItem() {
    final current = webPlaylist[webIndex];
    playAS(
      current,
      playlist: webPlaylist,
      startIndex: webIndex,
    );
  }

  //===========================================================================
  // Cleanup
  //===========================================================================

  void dispose() {
    if (kIsWeb) {
      _player!.dispose();
    } else {
      _checkAudioHandler();
      audioHandler!.customAction('dispose');
    }
  }
}
