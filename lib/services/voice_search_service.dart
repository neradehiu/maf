import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;

  Future<void> init() async {
    _available = await _speech.initialize(
      onStatus: (status) => print('🎙️ Trạng thái: $status'),
      onError: (error) => print('❌ Lỗi giọng nói: $error'),
    );
  }

  Future<String> listen({int timeoutSec = 6}) async {
    if (!_available) await init();

    final completer = Completer<String>();
    String result = '';

    await _speech.listen(
      localeId: 'vi_VN',
      onResult: (val) {
        result = val.recognizedWords;
        print('🔊 Đã nhận: $result');
        if (val.hasConfidenceRating && val.confidence > 0) {
          completer.complete(result);
        }
      },
    );

    // Tự dừng sau [timeoutSec] giây
    Future.delayed(Duration(seconds: timeoutSec), () async {
      if (!completer.isCompleted) {
        await _speech.stop();
        completer.complete(result);
      }
    });

    return completer.future;
  }
}