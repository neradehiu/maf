// file: lib/audio_helpers/page_manager.dart
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
  late final dynamic _player; // AudioPlayer on Web, null otherwise
  late final dynamic audioHandler; // AudioHandler on non-web, null on Web

  PageManager() {
    if (kIsWeb) {
      // Web: just_audio directly
      _player = AudioPlayer();
      audioHandler = null;
      _initWebListeners();
    } else {
      // Mobile/Desktop: audio_service
      try {
        audioHandler = getIt<AudioHandler>();
        _player = null;
      } catch (e) {
        throw Exception(
          "Bạn cần gọi setupServiceLocator() trước khi khởi tạo PageManager.\nChi tiết: $e",
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
    _player.playbackEventStream.listen((_) {
      playButtonNotifier.value =
      _player.playing ? ButtonState.playing : ButtonState.paused;
    });
    // Stream vị trí hiện tại
    _player.positionStream.listen((pos) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: pos,
        buffered: old.buffered,
        total: old.total,
      );
    });
    // Stream vị trí đã buffer
    _player.bufferedPositionStream.listen((buffered) {
      final old = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: old.current,
        buffered: buffered,
        total: old.total,
      );
    });
    // Stream tổng độ dài (duration)
    _player.durationStream.listen((duration) {
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
    audioHandler.queue.listen((playlist) {
      playlistNotifier.value = playlist;
      _updateSkipButton();
    });
  }

  void _updateSkipButton() {
    _checkAudioHandler();
    final mediaItem = audioHandler.mediaItem.value;
    final playlist = audioHandler.queue.value;
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
    audioHandler.playbackState.listen((state) {
      playbackStatNotifier.value = state.processingState;
      if (state.processingState == AudioProcessingState.loading ||
          state.processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!state.playing) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (state.processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        audioHandler.seek(Duration.zero);
        audioHandler.pause();
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
    audioHandler.playbackState.listen((state) {
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
    audioHandler.mediaItem.listen((mediaItem) {
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
    audioHandler.mediaItem.listen((mediaItem) {
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

  //===========================================================================
  // Controls (common)
  //===========================================================================

  /// Play (non-web)
  void play() {
    _checkAudioHandler();
    audioHandler.play();
  }

  /// Pause (non-web)
  void pause() {
    _checkAudioHandler();
    audioHandler.pause();
  }

  /// Seek to [position] (non-web)
  void seek(Duration position) {
    _checkAudioHandler();
    audioHandler.seek(position);
  }

  /// Previous track (non-web)
  void previous() {
    _checkAudioHandler();
    audioHandler.skipToPrevious();
  }

  /// Next track (non-web)
  void next() {
    _checkAudioHandler();
    audioHandler.skipToNext();
  }

  /// Stop playback, clear queue (non-web)
  Future<void> stop() async {
    _checkAudioHandler();
    await audioHandler.stop();
    await audioHandler.seek(Duration.zero);
    currentSongNotifier.value = null;
    await removeAll();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> setShuffleMode(AudioServiceShuffleMode value) async {
    isShuffleModeEnabledNotifier.value = value == AudioServiceShuffleMode.all;
    return await audioHandler.setShuffleMode(value);
  }

  /// Add a single item (non-web)
  Future<void> add(MediaItem item) async {
    _checkAudioHandler();
    await audioHandler.addQueueItem(item);
  }

  /// Add multiple, bắt đầu từ [index] (non-web)
  Future<void> adds(List<MediaItem> items, int index) async {
    _checkAudioHandler();
    if (items.isEmpty) return;
    await (audioHandler as MyAudioHandler).setNewPlaylist(items, index);
  }

  /// Update queue wholesale (non-web)
  Future<void> updateQueue(List<MediaItem> queue) async {
    _checkAudioHandler();
    await audioHandler.updateQueue(queue);
  }
  Future<void> skipToQueueItem(int index) async {
    return await audioHandler.skipToQueueItem(index);
  }
  /// Update single MediaItem (non-web)
  Future<void> updateMediaItem(MediaItem item) async {
    _checkAudioHandler();
    await audioHandler.updateMediaItem(item);
  }

  /// Move item in queue (non-web)
  Future<void> moveMediaItem(int oldIndex, int newIndex) async {
    _checkAudioHandler();
    await (audioHandler as AudioPlayerHandler)
        .moveQueueItem(oldIndex, newIndex);
  }

  /// Remove at [index] (non-web)
  Future<void> removeQueueItemAt(int index) async {
    _checkAudioHandler();
    await (audioHandler as AudioPlayerHandler)
        .removeQueueItemIndex(index);
  }

  /// Remove last item (non-web)
  void remove() {
    _checkAudioHandler();
    final last = audioHandler.queue.value.length - 1;
    if (last < 0) return;
    audioHandler.removeQueueItemAt(last);
  }

  /// Clear all (non-web)
  Future<void> removeAll() async {
    _checkAudioHandler();
    final last = audioHandler.queue.value.length - 1;
    if (last < 0) return;
    audioHandler.removeQueueItemAt(last);
  }

  //===========================================================================
  // Web playback
  //===========================================================================

  /// Play a MediaItem on Web
  Future<void> playAS(MediaItem mediaItem) async {
    if (!kIsWeb) return;
    try {
      await _player.setUrl(mediaItem.id);
      currentSongNotifier.value = mediaItem;
      await _player.play();
    } catch (e) {
      print('Lỗi khi playAS trên Web: $e');
    }
  }

  //===========================================================================
  // Cleanup
  //===========================================================================

  void dispose() {
    if (kIsWeb) {
      _player.dispose();
    } else {
      _checkAudioHandler();
      audioHandler.customAction('dispose');
    }
  }
}
