import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configura todos los mocks de canales de plataforma necesarios para que los tests pasen.
void setupTestMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // Mock para AudioPlayers
  _setMock('xyz.luan/audioplayers.global', (method, args) => null);
  _setMock('xyz.luan/audioplayers', (method, args) => null);

  // Mock para Android Alarm Manager - ¡IMPORTANTE! Usa JSONMethodCodec
  // Usamos setMockMessageHandler directamente para tener control total
  messenger.setMockMessageHandler('dev.fluttercommunity.plus/android_alarm_manager', (ByteData? message) async {
    try {
      // Intentar decodificar como JSON para ver si es el correcto
      // final call = const JSONMethodCodec().decodeMethodCall(message);
      // dev.log('AlarmManager call: ${call.method}');
      return const JSONMethodCodec().encodeSuccessEnvelope(true);
    } catch (e) {
      // Si falla JSON, intentar Standard como fallback
      try {
        return const StandardMethodCodec().encodeSuccessEnvelope(true);
      } catch (e2) {
        return null;
      }
    }
  });

  // Mock para Flutter Local Notifications
  _setMock('dexterous.com/flutter_local_notifications', (method, args) {
    if (method == 'initialize') return true;
    if (method == 'getNotificationAppLaunchDetails') return null;
    return null;
  });

  // Mock para Speech to Text
  _setMock('plugin.csdcorp.com/speech_to_text', (method, args) {
    if (method == 'initialize') return true;
    if (method == 'hasPermission') return true;
    return null;
  });

  // Mock para Flutter Foreground Task
  _setMock('com.pravera.flutter_foreground_task/methods', (method, args) {
    if (method == 'startService') return true;
    if (method == 'stopService') return true;
    if (method == 'isRunningService') return false;
    return true;
  });

  // Mock para SharedPreferences
  _setMock('plugins.flutter.io/shared_preferences', (method, args) {
    if (method == 'getAll') {
      return <String, dynamic>{};
    }
    return null;
  });
}

void _setMock(String channelName, dynamic Function(String method, dynamic args) handler, {MethodCodec codec = const StandardMethodCodec()}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    MethodChannel(channelName, codec),
    (MethodCall methodCall) async {
      return handler(methodCall.method, methodCall.arguments);
    },
  );
}
