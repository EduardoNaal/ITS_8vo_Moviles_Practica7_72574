import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as dev;

/// Servicio para reproducir el sonido de alarma.
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Reproduce el sonido de alarma.
  Future<void> playAlarm() async {
    if (_isPlaying) return;
    try {
      // Configurar el contexto de audio para alarmas (CRITICAL para Android/Samsung)
      final audioContext = AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
      );
      
      await AudioPlayer.global.setAudioContext(audioContext);
      
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/alarm_sound.mp3'));
      _isPlaying = true;
    } catch (e) {
      dev.log('Error al reproducir audio: $e');
    }
  }

  /// Detiene el sonido de alarma.
  Future<void> stopAlarm() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      // Ignorar
    }
  }

  /// Libera recursos.
  void dispose() {
    _player.dispose();
  }
}
