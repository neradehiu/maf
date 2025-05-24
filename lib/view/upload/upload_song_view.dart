import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class UploadSongView extends StatefulWidget {
  const UploadSongView({Key? key}) : super(key: key);

  @override
  State<UploadSongView> createState() => _UploadSongViewState();
}

class _UploadSongViewState extends State<UploadSongView> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _genreController = TextEditingController();

  PlatformFile? _audioFile;
  bool _isUploading = false;

  final storage = GetStorage();

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _audioFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty ||
        _artistController.text.isEmpty ||
        _genreController.text.isEmpty ||
        _audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Vui lòng điền đầy đủ thông tin và chọn file nhạc")),
      );
      return;
    }

    final token = storage.read('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔒 Không tìm thấy token. Vui lòng đăng nhập lại")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse('https://music-app-10.onrender.com/api/songs/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['songName'] = _titleController.text
        ..fields['artistName'] = _artistController.text
        ..fields['genre'] = _genreController.text;

      if (_audioFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'song',
          _audioFile!.bytes!,
          filename: _audioFile!.name,
        ));
      } else if (_audioFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'song',
          _audioFile!.path!,
          filename: _audioFile!.name,
        ));
      } else {
        throw Exception("Không thể đọc file nhạc");
      }

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      if (body.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Tải lên thành công và đã lưu vào MySQL")),
        );
        _titleController.clear();
        _artistController.clear();
        _genreController.clear();
        setState(() => _audioFile = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Upload thất bại: ${body.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎵 Thêm bài hát")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tên bài hát'),
            ),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Nghệ sĩ'),
            ),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Thể loại (genre)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.upload_file),
              label: Text(_audioFile != null
                  ? "Đã chọn: ${_audioFile!.name}"
                  : "Chọn file nhạc"),
            ),
            const SizedBox(height: 24),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submit,
              child: const Text("🚀 Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
