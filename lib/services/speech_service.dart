import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Servicio de reconocimiento de voz para cancelar alarmas.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Inicializa el motor de reconocimiento de voz.
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('[SpeechService] ERROR de inicialización/ejecución: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          print('[SpeechService] Estado cambiado: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
    } catch (e) {
      print('[SpeechService] EXCEPCIÓN en initialize: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  /// Inicia la escucha y llama [onResult] con cada texto reconocido.
  /// Llama [onMatch] si el texto contiene el [voiceCommand].
  Future<void> startListening({
    required String voiceCommand,
    required Function(String recognizedText) onResult,
    required Function() onMatch,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    _isListening = true;

    // Lógica para reiniciar la escucha automáticamente si se detiene
    void listen() async {
      if (!_isListening) return;

      try {
        await _speech.listen(
          onResult: (result) {
            final text = result.recognizedWords.toLowerCase().trim();
            onResult(text);

            // Comparar con el comando de voz configurado
            if (text.contains(voiceCommand.toLowerCase().trim())) {
              print('[SpeechService] ¡Comando detectado!');
              _isListening = false;
              _speech.stop();
              onMatch();
            }
          },
          localeId: 'es_MX', // Forzar español México
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation, // Modo confirmación es más agresivo
            cancelOnError: false,
            partialResults: true,
          ),
        );
      } catch (e) {
        print('[SpeechService] Error al iniciar listen: $e');
      }
    }

    // Monitorear el estado para reiniciar si es necesario
    _speech.statusListener = (status) {
      if (status == 'done' || status == 'notListening') {
        if (_isListening) {
          // Pequeño delay antes de reiniciar para evitar bucles infinitos en errores
          Future.delayed(const Duration(milliseconds: 500), listen);
        }
      }
    };

    listen();
  }

  /// Detiene la escucha activa.
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  /// Libera recursos.
  void dispose() {
    _speech.cancel();
  }
}
