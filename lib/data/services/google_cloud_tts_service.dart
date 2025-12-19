import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/config/api_config_service.dart';

/// Service for Google Cloud Text-to-Speech API
/// 
/// This service uses API key authentication (simpler than service account)
class GoogleCloudTtsService {
  static final GoogleCloudTtsService _instance =
      GoogleCloudTtsService._internal();
  factory GoogleCloudTtsService() => _instance;
  GoogleCloudTtsService._internal();

  String? _apiKey;
  bool _isInitialized = false;

  /// Initialize the service with API key
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to read API key from .env
      _apiKey = ApiConfig.get('CLOUD_TEXT_TO_SPEECH');
      
      // Alternative name
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = ApiConfig.get('GOOGLE_CLOUD_TTS_API_KEY');
      }

      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception(
          'Google Cloud TTS API key not configured. '
          'Please set CLOUD_TEXT_TO_SPEECH or GOOGLE_CLOUD_TTS_API_KEY in your .env file.',
        );
      }

      _isInitialized = true;
      debugPrint('✅ Google Cloud TTS service initialized with API key');
    } catch (e) {
      debugPrint('❌ Error initializing Google Cloud TTS: $e');
      rethrow;
    }
  }

  /// Synthesize speech from text using Google Cloud TTS
  /// 
  /// [text] - The text to convert to speech
  /// [languageCode] - Language code (e.g., 'vi-VN', 'en-US')
  /// [voiceName] - Optional voice name (e.g., 'vi-VN-Wavenet-A')
  /// [ssmlGender] - Gender of the voice ('NEUTRAL', 'FEMALE', 'MALE')
  /// [audioEncoding] - Audio encoding format ('MP3', 'LINEAR16', 'OGG_OPUS')
  /// 
  /// Returns the audio data as Uint8List
  Future<Uint8List> synthesizeSpeech({
    required String text,
    String languageCode = 'vi-VN',
    String? voiceName,
    String ssmlGender = 'NEUTRAL',
    String audioEncoding = 'MP3',
    double speakingRate = 1.0,
    double pitch = 0.0,
    double volumeGainDb = 0.0,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Google Cloud TTS API key not configured');
    }

    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    try {
      // 1. Cấu hình URL API với API key
      final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_apiKey',
      );

      // 2. Cấu hình Body (Dữ liệu gửi đi)
      final requestBody = {
        'input': {'text': text},
        'voice': {
          'languageCode': languageCode,
          if (voiceName != null) 'name': voiceName,
          'ssmlGender': ssmlGender,
        },
        'audioConfig': {
          'audioEncoding': audioEncoding,
          'speakingRate': speakingRate,
          'pitch': pitch,
          'volumeGainDb': volumeGainDb,
        },
      };

      // 3. Gửi Request POST
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // 4. Xử lý kết quả thành công
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final audioContent = responseData['audioContent'] as String?;

        if (audioContent == null) {
          throw Exception('No audio content in response');
        }

        // 5. Decode base64 audio content
        return base64Decode(audioContent);
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = errorBody['error']?['message'] ?? 
            'HTTP ${response.statusCode}';
        throw Exception('Google Cloud TTS API error: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error synthesizing speech: $e');
      rethrow;
    }
  }

  /// Synthesize speech and save to temporary file
  /// 
  /// Returns the path to the temporary audio file (or throws exception on web)
  /// On web, use synthesizeSpeech() directly and play with BytesSource
  Future<String> synthesizeSpeechToFile({
    required String text,
    String languageCode = 'vi-VN',
    String? voiceName,
    String ssmlGender = 'NEUTRAL',
    String audioEncoding = 'MP3',
    double speakingRate = 1.0,
    double pitch = 0.0,
    double volumeGainDb = 0.0,
  }) async {
    final audioData = await synthesizeSpeech(
      text: text,
      languageCode: languageCode,
      voiceName: voiceName,
      ssmlGender: ssmlGender,
      audioEncoding: audioEncoding,
      speakingRate: speakingRate,
      pitch: pitch,
      volumeGainDb: volumeGainDb,
    );

    // On web, path_provider is not available, so we throw an exception
    // The caller should use synthesizeSpeech() directly and play with BytesSource
    if (kIsWeb) {
      throw UnsupportedError(
        'synthesizeSpeechToFile is not supported on web. '
        'Use synthesizeSpeech() and play with BytesSource instead.',
      );
    }

    // Save to temporary file (mobile/desktop only)
    final tempDir = await getTemporaryDirectory();
    final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(audioData);

    return file.path;
  }

  /// Get available voices for a language
  Future<List<Map<String, dynamic>>> getVoices({
    String languageCode = 'vi-VN',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Google Cloud TTS API key not configured');
    }

    try {
      final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/voices?languageCode=$languageCode&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to get voices: ${response.statusCode}');
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final voices = responseData['voices'] as List<dynamic>?;

      return (voices ?? [])
          .map((v) => v as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting voices: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _apiKey = null;
    _isInitialized = false;
  }
}

