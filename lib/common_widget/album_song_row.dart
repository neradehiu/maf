import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class AlbumSongRow extends StatelessWidget {
  final Map<String, dynamic> sObj;
  final VoidCallback onPressedPlay;
  final VoidCallback onPressed;
  final bool isPlay;

  const AlbumSongRow({
    super.key,
    required this.sObj,
    required this.onPressed,
    this.isPlay = false,
    required this.onPressedPlay,
  });

  @override
  Widget build(BuildContext context) {
    String songName = sObj["title"]?.toString() ?? 'Không có tên';
    String artist = sObj["artist"]?.toString() ?? 'Không rõ nghệ sĩ';
    String genre = sObj["genre"]?.toString() ?? 'Không rõ thể loại';

    return InkWell(
      onTap: onPressed, // Click vào toàn bộ hàng
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPressedPlay,
                icon: Image.asset(
                  "assets/img/play_btn.png",
                  width: 25,
                  height: 25,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songName,
                      maxLines: 1,
                      style: TextStyle(
                        color: TColor.primaryText60,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      artist,
                      maxLines: 1,
                      style: TextStyle(
                        color: TColor.primaryText28,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      genre,
                      maxLines: 1,
                      style: TextStyle(
                        color: TColor.primaryText28,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                alignment: Alignment.centerRight,
                child: isPlay
                    ? Image.asset(
                  "assets/img/play_eq.png",
                  width: 60,
                  height: 25,
                )
                    : Image.asset(
                  "assets/img/more.png",
                  width: 25,
                  height: 25,
                ),
              ),
            ],
          ),
          Divider(
            color: Colors.white.withOpacity(0.07),
            indent: 50,
          ),
        ],
      ),
    );
  }
}
