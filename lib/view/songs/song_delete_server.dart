import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:music_player/services/song_service.dart';
import 'package:music_player/view_model/all_songs_view_model.dart';

import '../../audio_helpers/player_invoke.dart';

class SongDeleteService {
  final allVM = Get.put(AllSongsViewModel());
  final storage = GetStorage();

  Future<void> deleteSong(Map<String, dynamic> sObj) async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text("Xác nhận xoá", style: TextStyle(color: Colors.black)),
      content: const Text("Bạn chắc chắn muốn xoá bài hát này?",
          textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text("Huỷ", style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text("Xoá", style: TextStyle(color: Colors.blue)),
        ),
      ],
    ));

    if (confirm != true) return;

    final token = storage.read('token') ?? '';
    if (token.isEmpty) {
      Get.snackbar("Lỗi", "Token không tồn tại", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      final success = await SongService.deleteSongById(
        id: sObj["id"].toString(),
        token: token,
      );

      if (success) {
        await allVM.fetchAllSongs();
        Get.snackbar("Xoá thành công", "Bài hát đã được xoá", snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar("Lỗi", "Không thể xoá bài hát (có thể không đủ quyền)", snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Lỗi", e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
  void onPressedPlay(List<Map<String, dynamic>> playlist, int index) {
    playerPlayProcessDebounce(playlist, index);
  }
}
