// lib/main.dart

import 'package:flutter/foundation.dart'; // để kiểm tra kIsWeb
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_player/audio_helpers/audio_handler.dart';
import 'package:music_player/audio_helpers/page_manager.dart';
import 'package:music_player/audio_helpers/service_locator.dart';
import 'package:music_player/common/color_extension.dart';
import 'package:music_player/view/auth/login_view.dart';
import 'package:music_player/view/auth/register_view.dart';
import 'package:music_player/view/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo GetStorage
  await GetStorage.init();

  // 2. Khởi tạo service locator (đăng ký PageManager, AudioHandler, ...)
  await setupServiceLocator();

  // 3. Nếu không phải Web, khởi tạo AudioService để dùng AudioHandler
  if (!kIsWeb) {
    await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: "com.music_player.channel.audio",
        androidNotificationChannelName: "Music Playback",
        androidNotificationIcon: "drawable/ic_stat_music_note",
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  // 4. Chạy ứng dụng
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Khởi động PageManager (lắng nghe audio_service hoặc just_audio)
    getIt<PageManager>().init();
  }

  @override
  void dispose() {
    // Dọn dẹp tài nguyên của PageManager khi app đóng
    getIt<PageManager>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Circular Std",
        scaffoldBackgroundColor: TColor.bg,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: TColor.primaryText,
          displayColor: TColor.primaryText,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: TColor.primary,
        ),
        useMaterial3: false,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/register', page: () => const RegisterView()),
        GetPage(name: '/splash', page: () => const SplashView()),
      ],
    );
  }
}
