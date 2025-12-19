import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../data/services/google_cloud_tts_service.dart';

enum TtsState {
  idle,
  synthesizing,
  playing,
  paused,
  stopped,
  error,
}

/// Provider for managing Text-to-Speech state and playback
class TtsProvider extends ChangeNotifier {
  final GoogleCloudTtsService _ttsService = GoogleCloudTtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  TtsState _state = TtsState.idle;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // TTS Settings
  String _languageCode = 'vi-VN';
  String? _voiceName;
  String _ssmlGender = 'NEUTRAL';
  double _speakingRate = 1.0;
  double _pitch = 0.0;
  double _volumeGainDb = 0.0;

  TtsState get state => _state;
  String? get errorMessage => _errorMessage;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  bool get isSynthesizing => _state == TtsState.synthesizing;
  bool get hasError => _state == TtsState.error;

  String get languageCode => _languageCode;
  String? get voiceName => _voiceName;
  String get ssmlGender => _ssmlGender;
  double get speakingRate => _speakingRate;
  double get pitch => _pitch;
  double get volumeGainDb => _volumeGainDb;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  TtsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _ttsService.initialize();
      _setupAudioPlayerListeners();
      debugPrint('✅ TTS Provider initialized');
    } catch (e) {
      _setError('Failed to initialize TTS: $e');
      debugPrint('❌ TTS Provider initialization error: $e');
    }
  }

  void _setupAudioPlayerListeners() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.playing) {
        _state = TtsState.playing;
      } else if (playerState == PlayerState.paused) {
        _state = TtsState.paused;
      } else if (playerState == PlayerState.stopped ||
          playerState == PlayerState.completed) {
        _state = TtsState.stopped;
        _position = Duration.zero;
      }
      notifyListeners();
    });
  }

  /// Synthesize and play text
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      _setError('Text cannot be empty');
      return;
    }

    // If already playing, stop first
    if (_state == TtsState.playing || _state == TtsState.paused) {
      await stop();
    }

    try {
      _state = TtsState.synthesizing;
      _errorMessage = null;
      notifyListeners();

      // On web, use in-memory audio playback (BytesSource)
      // On mobile/desktop, use file-based playback (DeviceFileSource)
      if (kIsWeb) {
        // Synthesize speech to get audio bytes
        final audioBytes = await _ttsService.synthesizeSpeech(
          text: text,
          languageCode: _languageCode,
          voiceName: _voiceName,
          ssmlGender: _ssmlGender,
          speakingRate: _speakingRate,
          pitch: _pitch,
          volumeGainDb: _volumeGainDb,
        );

        // Play audio from bytes (web-compatible)
        await _audioPlayer.play(BytesSource(audioBytes));
      } else {
        // Synthesize speech and save to file (mobile/desktop)
        final audioPath = await _ttsService.synthesizeSpeechToFile(
          text: text,
          languageCode: _languageCode,
          voiceName: _voiceName,
          ssmlGender: _ssmlGender,
          speakingRate: _speakingRate,
          pitch: _pitch,
          volumeGainDb: _volumeGainDb,
        );

        // Play audio from file
        await _audioPlayer.play(DeviceFileSource(audioPath));
      }

      _state = TtsState.playing;
      notifyListeners();
    } catch (e) {
      _setError('Failed to synthesize speech: $e');
      debugPrint('Error in speak: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (_state == TtsState.playing) {
      await _audioPlayer.pause();
      _state = TtsState.paused;
      notifyListeners();
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (_state == TtsState.paused) {
      await _audioPlayer.resume();
      _state = TtsState.playing;
      notifyListeners();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    _state = TtsState.stopped;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_state == TtsState.playing) {
      await pause();
    } else if (_state == TtsState.paused) {
      await resume();
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _setError(String message) {
    _state = TtsState.error;
    _errorMessage = message;
    notifyListeners();
  }

  // Settings methods
  void setLanguageCode(String languageCode) {
    _languageCode = languageCode;
    notifyListeners();
  }

  void setVoiceName(String? voiceName) {
    _voiceName = voiceName;
    notifyListeners();
  }

  void setSsmlGender(String ssmlGender) {
    _ssmlGender = ssmlGender;
    notifyListeners();
  }

  void setSpeakingRate(double rate) {
    _speakingRate = rate.clamp(0.25, 4.0);
    notifyListeners();
  }

  void setPitch(double pitch) {
    _pitch = pitch.clamp(-20.0, 20.0);
    notifyListeners();
  }

  void setVolumeGainDb(double volumeGainDb) {
    _volumeGainDb = volumeGainDb.clamp(-96.0, 16.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

