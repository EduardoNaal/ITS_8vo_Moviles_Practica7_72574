import 'package:flutter_test/flutter_test.dart';

/// Tests para la lógica de comparación de comandos de voz.
///
/// Estos tests validan que la comparación texto ↔ comando se comporte
/// correctamente en diferentes escenarios del mundo real.
void main() {
  // Replica la lógica de comparación usada en SpeechService.startListening
  bool matchesCommand(String recognizedText, String voiceCommand) {
    return recognizedText
        .toLowerCase()
        .trim()
        .contains(voiceCommand.toLowerCase().trim());
  }

  group('Comparación de comandos de voz - Coincidencias exactas', () {
    test('comando simple coincide exactamente', () {
      expect(matchesCommand('detener', 'detener'), true);
    });

    test('comando con mayúsculas coincide (case insensitive)', () {
      expect(matchesCommand('DETENER', 'detener'), true);
      expect(matchesCommand('Detener', 'DETENER'), true);
    });

    test('comando con espacios extra coincide (trim)', () {
      expect(matchesCommand('  detener  ', 'detener'), true);
      expect(matchesCommand('detener', '  detener  '), true);
    });
  });

  group('Comparación de comandos de voz - Coincidencias parciales', () {
    test('texto más largo que contiene el comando coincide', () {
      expect(matchesCommand('quiero detener la alarma', 'detener'), true);
    });

    test('comando al inicio del texto reconocido', () {
      expect(matchesCommand('detener por favor', 'detener'), true);
    });

    test('comando al final del texto reconocido', () {
      expect(matchesCommand('por favor detener', 'detener'), true);
    });

    test('frase larga con comando embebido', () {
      expect(
        matchesCommand('ok google ya desperté gracias', 'ya desperté'),
        true,
      );
    });
  });

  group('Comparación de comandos de voz - No coincidencias', () {
    test('texto completamente diferente no coincide', () {
      expect(matchesCommand('hola mundo', 'detener'), false);
    });

    test('texto vacío no coincide', () {
      expect(matchesCommand('', 'detener'), false);
    });

    test('texto parcial del comando no coincide', () {
      expect(matchesCommand('deten', 'detener'), false);
    });

    test('comando vacío siempre coincide (contains vacío)', () {
      // Este es un caso edge: "".contains("") == true
      expect(matchesCommand('cualquier texto', ''), true);
    });
  });

  group('Comparación de comandos de voz - Frases personalizadas', () {
    test('"ya desperté" reconocido correctamente', () {
      expect(matchesCommand('ya desperté', 'ya desperté'), true);
    });

    test('"cállate" reconocido correctamente', () {
      expect(matchesCommand('cállate', 'cállate'), true);
    });

    test('"silencio" dentro de frase más larga', () {
      expect(
        matchesCommand('necesito silencio ahora', 'silencio'),
        true,
      );
    });

    test('"alto" como comando corto', () {
      expect(matchesCommand('alto', 'alto'), true);
      // Nota: "altavoz" no contiene exactamente "alto" como palabra separada
      // pero sí como substring — documentamos este comportamiento conocido
      expect(matchesCommand('dijo alto ahí', 'alto'), true);
    });

    test('"apagar alarma" como comando compuesto', () {
      expect(
        matchesCommand('quiero apagar alarma', 'apagar alarma'),
        true,
      );
    });
  });

  group('Comparación de comandos de voz - Reconocimiento de voz ruidoso', () {
    test('texto con variaciones de speech-to-text', () {
      // El STT a veces agrega puntuación
      expect(matchesCommand('detener.', 'detener'), true);
    });

    test('múltiples palabras parcialmente reconocidas', () {
      expect(
        matchesCommand('ya ya desperté creo', 'ya desperté'),
        true,
      );
    });
  });
}
