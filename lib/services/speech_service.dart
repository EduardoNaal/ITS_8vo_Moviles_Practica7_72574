import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Servicio de reconocimiento de voz para cancelar alarmas (con Watchdog).
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false; // Nuestra intención de escucha
  
  Timer? _reconnectTimer;
  Timer? _watchdogTimer; // El "perro guardián"

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Inicializa el motor de reconocimiento de voz.
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('[SpeechService] ERROR: ${error.errorMsg}');
          _restartIfActive();
        },
        onStatus: (status) {
          print('[SpeechService] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _restartIfActive();
          }
        },
      );
    } catch (e) {
      print('[SpeechService] EXCEPCIÓN initialize: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  /// Inicia el proceso de vigilancia
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isListening && !_speech.isListening) {
        print('[SpeechService] 🐕 Watchdog detectó micro apagado. Reiniciando...');
        _startListeningProcess();
      }
    });
  }

  void _restartIfActive() {
    if (_isListening) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(milliseconds: 300), () {
        if (_isListening && !_speech.isListening) {
          _startListeningProcess();
        }
      });
    }
  }

  late String _currentCommand;
  late Function(String) _currentOnResult;
  late Function() _currentOnMatch;

  Future<void> startListening({
    required String voiceCommand,
    required Function(String recognizedText) onResult,
    required Function() onMatch,
  }) async {
    _currentCommand = voiceCommand;
    _currentOnResult = onResult;
    _currentOnMatch = onMatch;
    
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    _isListening = true;
    _startWatchdog(); // Iniciar vigilancia
    _startListeningProcess();
  }

  Future<void> _startListeningProcess() async {
    if (!_isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase().trim();
          _currentOnResult(text);

          if (text.contains(_currentCommand.toLowerCase().trim())) {
            print('[SpeechService] ¡MATCH!');
            stopListening();
            _currentOnMatch();
          }
        },
        localeId: 'es_MX',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation, // Más estable para comandos cortos
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      print('[SpeechService] Error en _startListeningProcess: $e');
    }
  }

  Future<void> stopListening() async {
    print('[SpeechService] Deteniendo vigilancia y escucha.');
    _isListening = false;
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    await _speech.stop();
  }

  void dispose() {
    _isListening = false;
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    _speech.cancel();
  }
}
