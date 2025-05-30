import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class PlaylistsView extends StatefulWidget {
  const PlaylistsView({super.key});

  @override
  State<PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<PlaylistsView> {
  PlatformFile? _selectedFile;
  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  bool _isUploading = false;

  final storage = GetStorage();

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFile = result.files.single;
      });
    }
  }

  Future<void> _uploadSong() async {
    FocusScope.of(context).unfocus();

    if (_selectedFile == null ||
        _songNameController.text.isEmpty ||
        _artistNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    final token = storage.read('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔒 Token không tồn tại. Vui lòng đăng nhập lại")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse('https://music-app-10.onrender.com/api/songs/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = _songNameController.text
        ..fields['artist'] = _artistNameController.text;

      if (_genreController.text.isNotEmpty) {
        request.fields['genre'] = _genreController.text;
      }

      if (kIsWeb) {

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ));
      } else {

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path!,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎵 Thêm nhạc thành công!")),
        );
        setState(() {
          _selectedFile = null;
          _songNameController.clear();
          _artistNameController.clear();
          _genreController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Upload thất bại: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi khi upload: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2F3C),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "🎶 Tải lên bài hát mới",
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Chọn file nhạc"),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 10),
              Text(
                "Đã chọn: ${_selectedFile!.name}",
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ],
            const SizedBox(height: 20),
            _buildTextField(controller: _songNameController, label: "Tên bài hát"),
            const SizedBox(height: 10),
            _buildTextField(controller: _artistNameController, label: "Tên ca sĩ"),
            const SizedBox(height: 10),
            _buildTextField(controller: _genreController, label: "Thể loại (tuỳ chọn)"),
            const SizedBox(height: 30),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _uploadSong,
              icon: const Icon(Icons.cloud_upload),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              label: const Text(
                "Thêm nhạc",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
