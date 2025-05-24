import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/common_widget/album_song_row.dart';
import '../../common/color_extension.dart';
import '../../view_model/albums_view_model.dart';
import 'search_view.dart';

class AlbumDetailsView extends StatefulWidget {
  final dynamic albumData;

  const AlbumDetailsView({super.key, required this.albumData});

  @override
  State<AlbumDetailsView> createState() => _AlbumDetailsViewState();
}

class _AlbumDetailsViewState extends State<AlbumDetailsView> {
  final albumVM = Get.put(AlbumViewModel());
  String selectedGenre = 'All';

  // Function to filter songs by genre
  List<dynamic> filterSongsByGenre() {
    if (selectedGenre == 'All') {
      return albumVM.playedArr;
    } else {
      return albumVM.playedArr
          .where((song) => song['genre'] == selectedGenre)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: TColor.bg,
      drawerEnableOpenDragGesture: false, // Ngăn vuốt mở drawer
      appBar: AppBar(
        backgroundColor: TColor.bg,
        elevation: 0,
        automaticallyImplyLeading: false, // Không tự động thêm nút menu
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Image.asset(
            "assets/img/back.png",
            width: 25,
            height: 25,
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          "Album Details",
          style: TextStyle(
            color: TColor.primaryText80,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Get.to(() => const SearchView());
            },
            icon: Image.asset(
              "assets/img/search.png",
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              color: TColor.primaryText35,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Image.asset(
                          widget.albumData['image'],
                          width: double.infinity,
                          height: media.width * 0.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black54,
                      width: double.infinity,
                      height: media.width * 0.5,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                widget.albumData['image'],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.albumData['name'],
                                      style: TextStyle(
                                        color: TColor.primaryText.withOpacity(0.9),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "by ${widget.albumData['artist']}",
                                      style: TextStyle(
                                        color: TColor.primaryText.withOpacity(0.74),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${widget.albumData['releaseDate']}  ·  ${widget.albumData['songCount']} Songs  ·  ${widget.albumData['duration']}",
                                      style: TextStyle(
                                        color: TColor.primaryText.withOpacity(0.74),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                // Genre filter dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: DropdownButton<String>(
                    value: selectedGenre,
                    icon: Icon(Icons.filter_list, color: TColor.primaryText35),
                    elevation: 16,
                    style: TextStyle(color: TColor.primaryText),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGenre = newValue!;
                      });
                    },
                    items: <String>['All', 'Rock', 'Pop', 'Jazz', 'Classical']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: filterSongsByGenre().length,
                  itemBuilder: (context, index) {
                    var sObj = filterSongsByGenre()[index];
                    return AlbumSongRow(
                      sObj: sObj,
                      onPressed: () {
                        // Xử lý khi nhấn vào bài hát
                      },
                      onPressedPlay: () {
                        // Xử lý khi nhấn play
                      },
                      isPlay: index == 0,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
