import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:music_player/services/song_service.dart';

class TopViewSongsView extends StatefulWidget {
  const TopViewSongsView({super.key});

  @override
  State<TopViewSongsView> createState() => _TopViewSongsViewState();
}

class _TopViewSongsViewState extends State<TopViewSongsView> {
  List<Map<String, dynamic>> topSongs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTopSongs();
  }

  Future<void> loadTopSongs() async {
    try {
      final box = GetStorage();
      final token = box.read('token') ?? '';
      final songs = await SongService.fetchTopViewSongs(token, limit: 10);
      setState(() {
        topSongs = songs;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Lỗi khi load top view songs: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handlePlaySong(Map<String, dynamic> song) async {
    final box = GetStorage();
    final token = box.read('token') ?? '';
    await SongService.incrementView(song['id'], token);
    await loadTopSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Ảnh nền
          Positioned.fill(
            child: Image.asset(
              'assets/img/topview.png', // Đường dẫn ảnh nền
              fit: BoxFit.cover,
            ),
          ),

          // Overlay tối nhẹ để chữ dễ đọc hơn
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Nội dung chính
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                elevation: 0,
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: topSongs.length,
                  itemBuilder: (context, index) {
                    final song = topSongs[index];
                    return InkWell(
                      onTap: () => _handlePlaySong(song),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song['image'] != null &&
                                  song['image']
                                      .toString()
                                      .isNotEmpty
                                  ? Image.network(
                                song['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song['title'] ?? 'No Title',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song['artist'] ?? 'Unknown Artist',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${song['viewCount'] ?? 0} views',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
