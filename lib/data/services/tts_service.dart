import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused }

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;

  double _volume = 1.0;
  double _pitch = 1.0;
  double _rate = 0.5;
  String _language = 'vi-VN';

  TtsState get ttsState => _ttsState;
  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isPaused => _ttsState == TtsState.paused;

  Future<void> initialize() async {
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setPitch(_pitch);

    // Set iOS specific configurations
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ]);

    // Setup handlers
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
    });
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
      _ttsState = TtsState.playing;
    }
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TtsState.paused;
  }

  Future<void> resume() async {
    await _flutterTts.speak('');
    _ttsState = TtsState.playing;
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _flutterTts.setVolume(volume);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _flutterTts.setLanguage(language);
  }

  Future<List<String>> getAvailableLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return List<String>.from(languages);
  }

  Future<List<String>> getAvailableVoices() async {
    final voices = await _flutterTts.getVoices;
    return List<String>.from(voices);
  }

  // Đọc từng đoạn văn bản dài
  Future<void> speakLongText(String text, {int chunkSize = 1000}) async {
    final chunks = _splitTextIntoChunks(text, chunkSize);

    for (var chunk in chunks) {
      if (_ttsState == TtsState.stopped) break;
      await speak(chunk);

      // Đợi chunk hiện tại đọc xong
      while (_ttsState == TtsState.playing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (_ttsState == TtsState.paused) {
        // Đợi nếu đang tạm dừng
        while (_ttsState == TtsState.paused) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
  }

  List<String> _splitTextIntoChunks(String text, int chunkSize) {
    List<String> chunks = [];
    List<String> sentences = text.split(RegExp(r'[.!?]\s+'));

    String currentChunk = '';

    for (var sentence in sentences) {
      if ((currentChunk + sentence).length <= chunkSize) {
        currentChunk += sentence + '. ';
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = sentence + '. ';
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  void dispose() {
    _flutterTts.stop();
  }
}
