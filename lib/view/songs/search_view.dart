import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // Add this line
import 'package:music_player/view/songs/song_delete_server.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../common/color_extension.dart';
import '../../common_widget/album_song_row.dart';
import '../../services/song_service.dart';
import '../../services/voice_search_service.dart'; // thêm dòng này

final VoiceSearchService _voiceService = VoiceSearchService(); // thêm dòng này

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final songDeleteService = SongDeleteService();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  final storage = GetStorage(); // Initialize storage to get token

  void _performSearch() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;

    final token = storage.read('token');
    if (token == null || token.isEmpty) {
      print('⚠️ Token không tồn tại!');
      return;
    }

    setState(() => _loading = true);
    try {
      final results = await SongService.searchSongs(
        token: token,
        query: keyword,
      );
      setState(() {
        _results = results;
      });
    } catch (e) {
      print('❌ Lỗi tìm kiếm: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onVoiceSearch() async {
    // 1. Yêu cầu quyền micro
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    // 2. Nếu có quyền thì lắng nghe tiếng Việt
    if (await Permission.microphone.isGranted) {
      try {
        setState(() => _loading = true);

        String query = await _voiceService.listen(timeoutSec: 8); // ✅ Gọi với thời gian chờ rõ ràng
        _controller.text = query;
        print('🎤 Kết quả sau giọng nói: $query');

        _performSearch(); // Tìm kiếm luôn
      } catch (e) {
        print('❌ Lỗi khi nghe giọng nói: $e');
      } finally {
        setState(() => _loading = false);
      }
    } else {
      print("⚠️ Không có quyền micro!");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.bg,
      appBar: AppBar(
        backgroundColor: TColor.bg,
        title: TextField(
          controller: _controller,
          onSubmitted: (_) => _performSearch(),
          style: TextStyle(color: TColor.primaryText),
          decoration: InputDecoration(
            hintText: "Nhập tên bài hát...",
            hintStyle: TextStyle(color: TColor.primaryText35),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _performSearch,
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            onPressed: _onVoiceSearch,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? const Center(child: Text("Không tìm thấy bài hát"))
          : ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          var sObj = _results[index];
          return AlbumSongRow(
            sObj: sObj,
            onPressed: () {
              // Bấm vào dòng bài hát cũng phát luôn
              final playlist = _results.map((song) {
                return {
                  'id': song["id"]?.toString() ?? '',
                  'title': song["title"] ?? '',
                  'artist': song["artist"] ?? '',
                  'album': '',
                  'genre': song["genre"] ?? '',
                  'image': '',
                  'url': song["cloudinaryUrl"] ?? '',
                  'user_id': '',
                  'user_name': song["artist"] ?? '',
                };
              }).toList();

              songDeleteService.onPressedPlay(playlist, index);
            },
            onPressedPlay: () {
              final playlist = _results.map((song) {
                return {
                  'id': song["id"]?.toString() ?? '',
                  'title': song["title"] ?? '',
                  'artist': song["artist"] ?? '',
                  'album': '',
                  'genre': song["genre"] ?? '',
                  'image': '',
                  'url': song["cloudinaryUrl"] ?? '',
                  'user_id': '',
                  'user_name': song["artist"] ?? '',
                };
              }).toList();

              songDeleteService.onPressedPlay(playlist, index);
            },
            isPlay: false,
          );
        },
      ),
    );
  }
}
