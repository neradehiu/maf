import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class AllSongRow extends StatelessWidget {
  final Map sObj;
  final bool isWeb;
  final bool isFavorite;
  final VoidCallback onPressedPlay;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToFavorites;
  final VoidCallback onRemoveFromFavorites;

  const AllSongRow({
    Key? key,
    required this.sObj,
    this.isWeb = false,
    required this.isFavorite,
    required this.onPressedPlay,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onAddToFavorites,
    required this.onRemoveFromFavorites,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = sObj["title"] ?? 'Không tên';
    final String artist = sObj["artist"] ?? 'Không rõ nghệ sĩ';
    final String imageUrl = sObj["image"] ?? '';
    final int views = sObj["viewCount"] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Ảnh bài hát
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(
                          "assets/img/cover.jpg",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                  )
                      : Image.asset(
                    "assets/img/cover.jpg",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: TColor.primaryText28),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: TColor.bg,
                    borderRadius: BorderRadius.circular(7.5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),

            // Tiêu đề & nghệ sĩ & lượt xem
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Circular Std',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Circular Std',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.remove_red_eye, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        '$views',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nút phát nhạc
            IconButton(
              onPressed: onPressedPlay,
              icon: Image.asset(
                "assets/img/play_btn.png",
                width: 25,
                height: 25,
              ),
              tooltip: "Phát nhạc",
            ),
            // Nút Like / Unlike
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite ? Icons.thumb_up : Icons.thumb_up_off_alt,
                color: isFavorite ? Colors.blueAccent : Colors.grey,
                size: 24,
              ),
              tooltip: isFavorite ? "Bỏ Like" : "Like",
            ),

            // Menu
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: Colors.white.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.pinkAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(isFavorite ? "Bỏ yêu thích" : "Thêm vào yêu thích"),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text("Xoá bài hát"),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'favorite') {
                    isFavorite ? onRemoveFromFavorites() : onAddToFavorites();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.white.withOpacity(0.07),
          indent: 50,
        ),
      ],
    );
  }
}
