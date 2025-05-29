import 'package:audio_service/audio_service.dart';

class MediaItemConverter {
  /// Chuyển một Map (song) thành MediaItem, trong đó:
  /// - song['url'] phải là đường dẫn MP3 (đã fix thành HTTPS).
  /// - song['image'] (nếu có) là đường dẫn hình (đã đổi HTTP → HTTPS nếu cần).
  static MediaItem mapToMediaItem(Map song, {
    bool addedByAutoplay = false,
    bool autoplay = true,
    String? playlistBox
  }) {
    // Lấy rawUrl từ key 'url'
    final rawUrl = (song['url'] as String?) ?? '';
    // Nếu rawUrl khởi đầu bằng 'http://', đổi thành 'https://'
    final fixedUrl = rawUrl.startsWith('http://')
        ? rawUrl.replaceFirst('http://', 'https://')
        : rawUrl;

    // Lấy imageUri nếu có, convert 'http:' thành 'https:' nếu cần
    String rawImage = (song['image'] as String?) ?? '';
    final fixedImageUrl =
    rawImage.startsWith('http://') ? rawImage.replaceFirst('http://', 'https://') : rawImage;

    return MediaItem(
      // Quan trọng: id phải là URL MP3, không phải map['id'] (là số)
      id: fixedUrl,

      // Thông tin mô tả
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

      // artUri parse từ 'image' (nếu backend trả về), đã replace http→https
      artUri: Uri.tryParse(fixedImageUrl) ?? Uri(),

      genre: song['genre']?.toString() ?? '',

      extras: {
        'user_id': song['user_id'],
        'url': fixedUrl,         // Lưu lại URL trong extras, để audio_service non-web dùng
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
      return imageUrl
          .trim()
          .replaceAll("http:", "https:")
          .replaceAll("50x50", "150x150")
          .replaceAll("500x500", "150x150");
    case 'low':
      return imageUrl
          .trim()
          .replaceAll("http:", "https:")
          .replaceAll("150x150", "50x50")
          .replaceAll("500x500", "50x50");
    default:
      return imageUrl
          .trim()
          .replaceAll("http:", "https:")
          .replaceAll("50x50", "500x500")
          .replaceAll("150x150", "500x500");
  }
}
