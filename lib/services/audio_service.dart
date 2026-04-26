import 'package:audioplayers/audioplayers.dart';

/// Servicio encargado de la reproducción de sonidos de alarma (Singleton).
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _initAudio();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  void _initAudio() {
    AudioLogger.logLevel = AudioLogLevel.error;
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// Reproduce el sonido de la alarma.
  Future<void> playAlarm() async {
    if (_isPlaying) return;

    try {
      // Configuramos el audio para que "conviva" con otros sonidos (como el micro)
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media, // Usar media para evitar bloqueos del sistema de alarma
          audioFocus: AndroidAudioFocus.none, // MUY IMPORTANTE: No solicitar foco exclusivo
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord, // Permitir ambos
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      ));

      print('[AudioService] 🔊 Reproduciendo en modo convivencia...');
      await _audioPlayer.play(AssetSource('sounds/alarm_sound.mp3'));
      _isPlaying = true;
    } catch (e) {
      print('[AudioService] Error al reproducir: $e');
    }
  }

  /// Detiene el sonido de la alarma.
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      print('[AudioService] 🛑 Deteniendo audio...');
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('[AudioService] Error al detener: $e');
    }
  }

  void dispose() {}
}
