import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/common/color_extension.dart';
import 'package:music_player/common_widget/recommended_cell.dart';
import 'package:music_player/common_widget/title_section.dart';
import 'package:music_player/view_model/splash_view_model.dart';
import 'package:music_player/view_model/home_view_model.dart';

import '../../common_widget/playlist_cell.dart';
import '../../common_widget/songs_row.dart';
import '../../common_widget/view_all_section.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final homeVM = Get.put(HomeViewModel());

  // Logout function
  void _logout() async {
    // You can add your logout logic here, like clearing user data or token.
    // For example, clearing shared preferences or FirebaseAuth sign-out:
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    // Or FirebaseAuth.instance.signOut();

    // Then navigate to the login page
    Get.offNamed('/login'); // Navigate to login page after logout
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xff292E4B),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: TextField(
                  controller: homeVM.txtSearch.value,
                  decoration: InputDecoration(
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 20),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 20),
                      alignment: Alignment.centerLeft,
                      width: 30,
                      child: Image.asset(
                        "assets/img/search.png",
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        color: TColor.primaryText28,
                      ),
                    ),
                    hintText: "Search album song",
                    hintStyle: TextStyle(
                      color: TColor.primaryText28,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: TColor.primaryText28),
            onPressed: _logout, // Call logout function when pressed
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TitleSection(title: "Hot Recommended"),
            SizedBox(
              height: screenHeight * 0.28, // Tăng chiều cao lên 28% màn hình
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                scrollDirection: Axis.horizontal,
                itemCount: homeVM.hostRecommendedArr.length,
                itemBuilder: (context, index) {
                  var mObj = homeVM.hostRecommendedArr[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: screenWidth * 0.4, // Đặt chiều rộng cố định
                      child: RecommendedCell(mObj: mObj),
                    ),
                  );
                },
              ),
            ),
            Divider(
              color: Colors.white.withOpacity(0.07),
              indent: 20,
              endIndent: 20,
            ),
            ViewAllSection(
              title: "Playlist",
              onPressed: () {},
            ),
            SizedBox(
              height: screenHeight * 0.25, // Chiều cao động, 25% màn hình
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                scrollDirection: Axis.horizontal,
                itemCount: homeVM.playListArr.length,
                itemBuilder: (context, index) {
                  var mObj = homeVM.playListArr[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: screenWidth * 0.4, // Đặt chiều rộng cố định
                      child: PlaylistCell(mObj: mObj),
                    ),
                  );
                },
              ),
            ),
            Divider(
              color: Colors.white.withOpacity(0.07),
              indent: 20,
              endIndent: 20,
            ),
            ViewAllSection(
              title: "Recently Played",
              onPressed: () {},
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true, // Đảm bảo danh sách không chiếm quá nhiều không gian
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: homeVM.recentlyPlayedArr.length,
              itemBuilder: (context, index) {
                var sObj = homeVM.recentlyPlayedArr[index];
                return SongsRow(
                  sObj: sObj,
                  onPressed: () {},
                  onPressedPlay: () {},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
