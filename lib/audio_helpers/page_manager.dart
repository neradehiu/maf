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

  ProgressBarState({required this.current, required this.buffered, required this.total});
}

class ProgressNotifier extends ValueNotifier<ProgressBarState> {
  ProgressNotifier()
      : super(ProgressBarState(current: Duration.zero, buffered: Duration.zero, total: Duration.zero));
}

enum RepeatState { off, repeatSong, repeatPlaylist }

class RepeatButtonNotifier extends ValueNotifier<RepeatState> {
  RepeatButtonNotifier() : super(RepeatState.off);
  void nextState() {
    value = RepeatState.values[(value.index + 1) % RepeatState.values.length];
  }
}

class PageManager {
  final currentSongNotifier = ValueNotifier<MediaItem?>(null);
  final playbackStatNotifier = ValueNotifier<AudioProcessingState>(AudioProcessingState.idle);
  final playlistNotifier = ValueNotifier<List<MediaItem>>([]);
  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final playButtonNotifier = PlayButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);

  late final dynamic _player; // just_audio.AudioPlayer or AudioHandler
  late final dynamic audioHandler;

  PageManager() {
    if (kIsWeb) {
      _player = AudioPlayer();
      audioHandler = null;
      _initWebListeners();
    } else {
      try {
        audioHandler = getIt<AudioHandler>();
        _player = null;
      } catch (e) {
        throw Exception(
            "Bạn cần gọi setupServiceLocator() trước khi khởi tạo PageManager.\nChi tiết lỗi: $e");
      }
    }
  }

  void init() {
    if (kIsWeb) return;
    _listenToChangeInPlaylist();
    _listenToPlayBackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalPosition();
    _listenToChangesInSong();
  }

  // JUST_AUDIO listeners for Web
  void _initWebListeners() {
    _player.playbackEventStream.listen((event) {
      playButtonNotifier.value = _player.playing ? ButtonState.playing : ButtonState.paused;
      progressNotifier.value = ProgressBarState(
        current: event.position,
        buffered: event.bufferedPosition,
        total: event.duration ?? Duration.zero,
      );
    });
  }

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

  void _checkAudioHandler() {
    if (audioHandler == null) {
      throw Exception("audioHandler chưa được khởi tạo. Bạn cần gọi setupServiceLocator() trước.");
    }
  }

  // Controls (common for non-web)
  void play() {
    _checkAudioHandler();
    audioHandler.play();
  }

  void pause() {
    _checkAudioHandler();
    audioHandler.pause();
  }

  void seek(Duration position) {
    _checkAudioHandler();
    audioHandler.seek(position);
  }

  void previous() {
    _checkAudioHandler();
    audioHandler.skipToPrevious();
  }

  void next() {
    _checkAudioHandler();
    audioHandler.skipToNext();
  }

  Future<void> updateQueue(List<MediaItem> queue) async {
    _checkAudioHandler();
    return await audioHandler.updateQueue(queue);
  }

  Future<void> updateMediaItem(MediaItem item) async {
    _checkAudioHandler();
    return await audioHandler.updateMediaItem(item);
  }

  Future<void> moveMediaItem(int oldIndex, int newIndex) async {
    _checkAudioHandler();
    return await (audioHandler as AudioPlayerHandler).moveQueueItem(oldIndex, newIndex);
  }

  Future<void> removeQueueItemAt(int index) async {
    _checkAudioHandler();
    return await (audioHandler as AudioPlayerHandler).removeQueueItemIndex(index);
  }

  Future<void> customAction(String name) async {
    _checkAudioHandler();
    return await audioHandler.customAction(name);
  }

  Future<void> skipToQueueItem(int index) async {
    _checkAudioHandler();
    return await audioHandler.skipToQueueItem(index);
  }

  void repeat() {
    _checkAudioHandler();
    repeatButtonNotifier.nextState();
    switch (repeatButtonNotifier.value) {
      case RepeatState.off:
        audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatState.repeatSong:
        audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatState.repeatPlaylist:
        audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }

  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _checkAudioHandler();
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        repeatButtonNotifier.value = RepeatState.off;
        break;
      case AudioServiceRepeatMode.one:
        repeatButtonNotifier.value = RepeatState.repeatSong;
        break;
      case AudioServiceRepeatMode.all:
        repeatButtonNotifier.value = RepeatState.repeatPlaylist;
        break;
      case AudioServiceRepeatMode.group:
        break;
    }
    await audioHandler.setRepeatMode(repeatMode);
  }

  void shuffle() async {
    _checkAudioHandler();
    final enabled = !isShuffleModeEnabledNotifier.value;
    isShuffleModeEnabledNotifier.value = enabled;
    audioHandler.setShuffleMode(
        enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
  }

  Future<void> setShuffleMode(AudioServiceShuffleMode value) async {
    _checkAudioHandler();
    isShuffleModeEnabledNotifier.value = value == AudioServiceShuffleMode.all;
    return await audioHandler.setShuffleMode(value);
  }

  Future<void> add(MediaItem item) async {
    _checkAudioHandler();
    return await audioHandler.addQueueItem(item);
  }

  Future<void> adds(List<MediaItem> items, int index) async {
    _checkAudioHandler();
    if (items.isEmpty) return;
    await (audioHandler as MyAudioHandler).setNewPlaylist(items, index);
  }

  void remove() {
    _checkAudioHandler();
    final last = audioHandler.queue.value.length - 1;
    if (last < 0) return;
    audioHandler.removeQueueItemAt(last);
  }

  Future<void> removeAll() async {
    _checkAudioHandler();
    final last = audioHandler.queue.value.length - 1;
    if (last < 0) return;
    audioHandler.removeQueueItemAt(last);
  }

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

  void dispose() {
    if (!kIsWeb) {
      _checkAudioHandler();
      audioHandler.customAction('dispose');
    } else {
      _player.dispose();
    }
  }

  Future<void> stop() async {
    _checkAudioHandler();
    await audioHandler.stop();
    await audioHandler.seek(Duration.zero);
    currentSongNotifier.value = null;
    await removeAll();
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
