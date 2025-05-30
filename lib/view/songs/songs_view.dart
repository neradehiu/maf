import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/view/songs/albums_view.dart';
import 'package:music_player/view/songs/all_songs_view.dart';
import 'package:music_player/view/songs/artists_view.dart';
import 'package:music_player/view/songs/genres_view.dart';
import 'package:music_player/view/songs/playlists_view.dart';
import 'package:music_player/view/songs/equalizer_view.dart';
import 'package:music_player/view/songs/search_view.dart';
import 'package:music_player/view/songs/top_view_songs_view.dart';

import '../../common/color_extension.dart';
import '../../view_model/splash_view_model.dart';
import 'favorites_view.dart';

class SongsView extends StatefulWidget {
  const SongsView({super.key});

  @override
  State<SongsView> createState() => _SongsViewState();
}

class _SongsViewState extends State<SongsView> with SingleTickerProviderStateMixin {
  TabController? controller;
  int selectTab = 0;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 8, vsync: this);
    controller?.addListener(() {
      selectTab = controller?.index ?? 0;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Get.find<SplashViewMode>().openDrawer();
          },
          icon: Image.asset(
            "assets/img/menu.png",
            width: 25,
            height: 25,
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          "Songs",
          style: TextStyle(
            color: TColor.primaryText80,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Get.find<SplashViewMode>().openDrawer();
              Get.to(() => const SearchView());
            },
            icon: Image.asset(
              "assets/img/search.png",
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              color: TColor.primaryText35,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: kToolbarHeight - 15,
            child: TabBar(
              controller: controller,
              indicatorColor: TColor.focus,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
              isScrollable: true,
              labelColor: TColor.focus,
              labelStyle: TextStyle(
                color: TColor.focus,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelColor: TColor.primaryText80,
              unselectedLabelStyle: TextStyle(
                color: TColor.primaryText80,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: "PLAYLISTS"),
                Tab(text: "ADDMUSIC"),
                Tab(text: "ALBUMS"),
                Tab(text: "ARTISTS"),
                Tab(text: "GENRES"),
                Tab(text: "EQUALIZER"),
                Tab(text: "FAVORITES"),
                Tab(text: "TOP VIEW"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: const [
                AllSongsView(),
                PlaylistsView(),
                AlbumsView(),
                ArtistsView(),
                GenresView(),
                equalizerView(),
                FavoritesView(),
                TopViewSongsView(), // ✅ View mới
              ],
            ),
          )
        ],
      ),
    );
  }
}
