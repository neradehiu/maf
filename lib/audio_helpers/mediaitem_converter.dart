// lib/audio_helpers/mediaitem_converter.dart

import 'package:audio_service/audio_service.dart';

class MediaItemConverter {
  /// Chuyển Map (song) thành MediaItem, trong đó:
  /// - id: URL MP3 (đã fix https nếu cần)
  /// - extras['songId']: ID số của bài (để gọi API share, view, favorite, v.v.)
  static MediaItem mapToMediaItem(
      Map song, {
        bool addedByAutoplay = false,
        bool autoplay = true,
        String? playlistBox,
      }) {
    final rawUrl = (song['url'] as String?) ?? '';
    final fixedUrl = rawUrl.startsWith('http://')
        ? rawUrl.replaceFirst('http://', 'https://')
        : rawUrl;

    String rawImage = (song['image'] as String?) ?? '';
    final fixedImageUrl = rawImage.startsWith('http://')
        ? rawImage.replaceFirst('http://', 'https://')
        : rawImage;

    // Lấy ID số của bài (string) từ trường 'id' map
    final idNumber = (song['id']?.toString() ?? '');

    return MediaItem(
      // id dùng để play: chính là URL MP3 (đã bảo đảm https)
      id: fixedUrl,

      album: song['album']?.toString() ?? '',
      artist: song['artist']?.toString() ?? '',
      duration: Duration(
        seconds: int.parse(
          (song['duration'] == null ||
              song['duration'] == 'null' ||
              song['duration'] == '')
              ? '180'
              : song['duration'].toString(),
        ),
      ),
      title: song['title']?.toString() ?? '',
      artUri: Uri.tryParse(fixedImageUrl) ?? Uri(),
      genre: song['genre']?.toString() ?? '',

      extras: {
        'songId': idNumber,      // ← ID số để gọi API share, view, favorite, v.v.
        'url': fixedUrl,         // ← URL MP3 để Web play
        'user_id': song['user_id'],
        'album_id': song['album_id'],
        'addedByAutoplay': addedByAutoplay,
        'autoplay': autoplay,
        'playlistBox': playlistBox,
      },
    );
  }
}

String getImageUrl(String? imageUrl, {String quality = 'high'}) {
  if (imageUrl == null) return '';
  switch (quality) {
    case 'high':
      return imageUrl.trim()
          .replaceAll("http:", "https:")
          .replaceAll("50x50", "500x500")
          .replaceAll("150x150", "500x500");
    case 'medium':
      return imageUrl.trim()
          .replaceAll("http:", "https:")
          .replaceAll("50x50", "150x150")
          .replaceAll("500x500", "150x150");
    case 'low':
      return imageUrl.trim()
          .replaceAll("http:", "https:")
          .replaceAll("150x150", "50x50")
          .replaceAll("500x500", "50x50");
    default:
      return imageUrl.trim()
          .replaceAll("http:", "https:")
          .replaceAll("50x50", "500x500")
          .replaceAll("150x150", "500x500");
  }
}
