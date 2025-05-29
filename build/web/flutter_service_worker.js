'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "f0afd7336480c48c21d175ebdf103f72",
"assets/AssetManifest.bin.json": "61d69ecef866d5d13c37759b985065d5",
"assets/AssetManifest.json": "2be298f1a45e73d2a798e0d2b930f0c7",
"assets/assets/audio/noi_nay_co_anh.mp3": "8c1d9db907a93b9c81e7394038dabe7c",
"assets/assets/fonts/CircularStd-Black.otf": "7f42d8488652eb250af2f484d377dbee",
"assets/assets/fonts/CircularStd-Bold.otf": "6baed2bf580964bec9559ad83caee43d",
"assets/assets/fonts/CircularStd-Book.otf": "6365c40aa59d462f1cc52ccce9635cb4",
"assets/assets/fonts/CircularStd-Medium.otf": "4fcdd97fadc3a1d9887f816f2aa67f1d",
"assets/assets/img/add.png": "d151a31bb6386ecc3bb2f94c82881f49",
"assets/assets/img/alb_1.png": "270ee3fb4ee640b9b1b2be753e66fdc6",
"assets/assets/img/alb_2.png": "30c067f49efb7add972e3f7ba8227d81",
"assets/assets/img/alb_3.png": "372a45ba949e4179fb1e513b5a3908fc",
"assets/assets/img/alb_4.png": "cfbfe9fa90eac341df0138fba51b26d9",
"assets/assets/img/alb_5.png": "d948f0de40b286c9b7114d8dc9993692",
"assets/assets/img/alb_6.png": "b5470b41527a49d2f126df4a17dcfe68",
"assets/assets/img/app_logo.png": "485c2e13eea9bf55c2607e855204a46b",
"assets/assets/img/artitst_detail_top.png": "f5d44b296da07f943c9ddcd317b2cfa9",
"assets/assets/img/ar_1.png": "cde9dd1edd9aa4694afd4557506b76ed",
"assets/assets/img/ar_2.png": "db3e615874e95357b8c444e4a4918e10",
"assets/assets/img/ar_3.png": "fb911cb58637df19bbfe6b114d177ed1",
"assets/assets/img/ar_4.png": "27db67aa5642c5bc7becdc02453647d6",
"assets/assets/img/ar_5.png": "696c8d0bf715271902515aa75e8a8ac0",
"assets/assets/img/ar_6.png": "342eca3f9b3a8a42bb471444241535fd",
"assets/assets/img/ar_d_1.png": "a6a2140720dceccb7820b136793a2d5d",
"assets/assets/img/ar_d_2.png": "f896802bfa81b335727918c2fa9760fb",
"assets/assets/img/ar_d_3.png": "6ecb0762ee03823545b0f9f7821d4899",
"assets/assets/img/ar_d_4.png": "f5d44b296da07f943c9ddcd317b2cfa9",
"assets/assets/img/back.png": "8558105c9ba4e82db90d546cd0f47b7d",
"assets/assets/img/b_player_next.png": "46d1d5be86550346d7a93722279cf916",
"assets/assets/img/b_player_previous.png": "2c0a886f7065617491d18abb20493b98",
"assets/assets/img/close.png": "a703aa0f526c74096000b8dbe8055dde",
"assets/assets/img/cover.jpg": "9c2d88d3c3d0bbbe5a4fcb0706c67a33",
"assets/assets/img/eq.png": "2ffd73dc9465eea0475798eab92a47c2",
"assets/assets/img/eq_display.png": "41a410377a8198668f66dfd423662f72",
"assets/assets/img/fav.png": "1d8a9a6f4215201e6c8c988c6eb5e0e5",
"assets/assets/img/gen_1.png": "a0eedbc3bf72e83366a623188d1017bf",
"assets/assets/img/gen_2.png": "f6de282354d1f4212f664bec5e66abc2",
"assets/assets/img/gen_3.png": "cde2a8fc88c8b8b8703885b089f2fdcc",
"assets/assets/img/gen_4.png": "1c15d43a4af57b1293324601029a1033",
"assets/assets/img/gen_5.png": "7ba1a95eaf8504e94c46e6b4af8a394f",
"assets/assets/img/gen_6.png": "14a4bf672145cf162c9ade8b08a5427b",
"assets/assets/img/gen_7.png": "0c6a37186795a0a78cc296ff4e1140fb",
"assets/assets/img/gen_8.png": "3ec8451f54c5276bbb624e35659f9bf9",
"assets/assets/img/home_tab.png": "8a57e18c68315f69219d032ef26e63eb",
"assets/assets/img/home_tab_un.png": "9c16cf5e5304f0cfa084fbb882eafef1",
"assets/assets/img/img_1.png": "f5d44b296da07f943c9ddcd317b2cfa9",
"assets/assets/img/img_2.png": "9e67fa61304e219e29958628387f315d",
"assets/assets/img/img_3.png": "b5480805320c6ddb5a6060551ef05902",
"assets/assets/img/img_4.png": "50a8f58b82f28355f3e473ad65ae9a78",
"assets/assets/img/img_5.png": "161f931e741270e032284833d17940a4",
"assets/assets/img/login.jpg": "fc865a40e4964a94448dd03e2be581f6",
"assets/assets/img/menu.png": "d4fc625c1ef3f3542dea9f821722c741",
"assets/assets/img/minzy.jpeg": "b3a24a7115220acd4e509e22db60bbcc",
"assets/assets/img/more.png": "dc7b1d833e1b764d5ab2b6b2fe241e70",
"assets/assets/img/more_btn.png": "626dabf2abbe4de3c775cfec33fc1a5b",
"assets/assets/img/mp_1.png": "9e2f12ced7b69b568ddb8ff132b964f7",
"assets/assets/img/mp_2.png": "4d9f6ddb48053dee02b64118bbcdb1e3",
"assets/assets/img/mp_3.png": "ae89f5af210b479c65a4c840b739f328",
"assets/assets/img/mp_4.png": "d0dc9e214ade9d16b365844608edf2fe",
"assets/assets/img/m_driver_mode.png": "67a81a1b25bb6c7a5a8aad66dba25fe8",
"assets/assets/img/m_eq.png": "f309d1382d337b4a0829c3d9b63f9f75",
"assets/assets/img/m_hidden_folder.png": "91dd8cd5bf8f315d22bc7bdaaa4c443d",
"assets/assets/img/m_ring_cut.png": "0949ec06410f97831e0329fa6fde076e",
"assets/assets/img/m_scan_media.png": "9c326e126eca8a6c4d1c8c31443d048c",
"assets/assets/img/m_sleep_timer.png": "786e7bd37bc6a0dac9762526010706e0",
"assets/assets/img/m_theme.png": "fc55094b7bd6f5b73e3c8e9af68b2fc2",
"assets/assets/img/next_song.png": "006090113a58aec5501426259dd8c620",
"assets/assets/img/pause.png": "514d56efa86efd24427e3cb82dad284b",
"assets/assets/img/pl1.png": "e0a663c4610154acce82bb1f9b5b6a72",
"assets/assets/img/pl2.png": "50a8f58b82f28355f3e473ad65ae9a78",
"assets/assets/img/pl3.png": "c7bbf3fe034b079d84219206e7c0238e",
"assets/assets/img/pl4.png": "241bb503ff92bb7b7c8cc782fa3edac2",
"assets/assets/img/pl5.png": "161f931e741270e032284833d17940a4",
"assets/assets/img/pl6.png": "b1467720ccd185e914f9a48263b20989",
"assets/assets/img/pl7.png": "44af2fd3ca4d2797ca5b75728cd75117",
"assets/assets/img/pl8.png": "144a87ad3b31a6a8c631b91ecd852aae",
"assets/assets/img/play.png": "13dd818ee7ba1daed81ae4ee241c0cda",
"assets/assets/img/player_image.png": "f73355f6fe10d700d66019d91b8479d9",
"assets/assets/img/playlist.png": "9cba6b8868010ee8ec8c47357d87ac9e",
"assets/assets/img/playlist_1.png": "7fa72cf29ccdbd9f5d80c38b61171fd2",
"assets/assets/img/playlist_2.png": "53be9ce928e38a38ec98997cd70fb363",
"assets/assets/img/playlist_3.png": "9f61fd9d3b20285ce572b72b2a76da3b",
"assets/assets/img/playlist_4.png": "482cbd2d56e69169cb5ee5ba527e760f",
"assets/assets/img/play_btn.png": "94d5d1736b8cf50d142c4c9489b60ca7",
"assets/assets/img/play_eq.png": "37e609fb6ca58d562b4d3b64a0c4a852",
"assets/assets/img/play_n.png": "ba23573641856b05398555ba433008f0",
"assets/assets/img/previous_song.png": "3d6e3e146951d05d69646dba641fddc1",
"assets/assets/img/register.jpg": "f535a4632aa023345064b202dd7f93c3",
"assets/assets/img/repeat.png": "b3736eef0a1688502462830b14acb31a",
"assets/assets/img/s1.png": "a03d70fc0465fa93ea21975098defdbe",
"assets/assets/img/s10.png": "8f4c250f023a78fca069604c875fb343",
"assets/assets/img/s2.png": "530b1ed47ee35a65bb8c1ef7dfa5efaa",
"assets/assets/img/s3.png": "c9fdd5ce056889610c6805dcc27c74b2",
"assets/assets/img/s4.png": "c7fb206af0d2e38eb5114a4c4011b94f",
"assets/assets/img/s5.png": "3a059d9c728addf3c29ff202d91453e8",
"assets/assets/img/s6.png": "56044a78cb626c074652608fea62505b",
"assets/assets/img/s7.png": "514b41fc7fd26e41e3a98b3a51af506a",
"assets/assets/img/s8.png": "514b41fc7fd26e41e3a98b3a51af506a",
"assets/assets/img/s9.png": "44e663c26488f083ecfa4eb51a2e8433",
"assets/assets/img/search.png": "f505b18900102d88af9a45aee162e540",
"assets/assets/img/setting_tab.png": "ed283f979739598cdc264b565d6fb23a",
"assets/assets/img/setting_tab_un.png": "52ebbadf421e0ad9be2612418cfa9613",
"assets/assets/img/share.png": "d56c761dae1a08c210029fa3f8dd1f73",
"assets/assets/img/share1.png": "190db1eb04a87fb665877e9d8e8c5c75",
"assets/assets/img/shuffle.png": "91dfc83066160f9b3f92390bcc3e7d8c",
"assets/assets/img/songs_tab.png": "c9ad6266b286b804e79a47b3d28b6094",
"assets/assets/img/songs_tab_un.png": "bcd3ef203cb47cda3ea459adc84716a9",
"assets/assets/img/sontung1.png": "078c19ec12dbca07fb73ea3f77eb80e3",
"assets/assets/img/s_audio.png": "5fe769ff749bbf214fc51da06ca1fdd5",
"assets/assets/img/s_display.png": "f3b95884bc84c70a3df67f634cdfd2e6",
"assets/assets/img/s_headset.png": "73f1158599ab0301ebfec8b1059ee937",
"assets/assets/img/s_lock_screen.png": "8c3bc80b9bb1e5afc1d61b36b8382983",
"assets/assets/img/s_menu.png": "117d428179124ad2be6a1d29b36f0925",
"assets/assets/img/s_other.png": "21485fceec2688f3147797c255b6fcab",
"assets/FontManifest.json": "013f559bfd7b9ff5c460ae203eb4f4b7",
"assets/fonts/MaterialIcons-Regular.otf": "d8696f664585514733fc97887a9bc624",
"assets/NOTICES": "c0299b628cf388162ca1317b4938030d",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"flutter_bootstrap.js": "36b4729fe654329e69d8e49e9c0bb126",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "eff0dd0980191e2805852ab73b44ee7c",
"/": "eff0dd0980191e2805852ab73b44ee7c",
"main.dart.js": "9e20105155c6834f0ff92ac0d1beb236",
"manifest.json": "a35650fe0d6280cd28f6188d7684da17",
"version.json": "bde3e0589ca843d1f6d994262542c30b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
