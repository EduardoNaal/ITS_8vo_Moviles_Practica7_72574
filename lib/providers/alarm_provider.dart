import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm_model.dart';
import '../services/storage_service.dart';
import '../services/alarm_scheduler_service.dart';
import '../services/speech_service.dart';

/// Provider principal que gestiona el estado de las alarmas.
class AlarmProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SpeechService _speechService = SpeechService();
  List<AlarmModel> _alarms = [];
  bool _isListening = false;
  Timer? _monitorTimer;

  List<AlarmModel> get alarms => _alarms;
  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  AlarmProvider() {
    // Escuchar mensajes del servicio en primer plano
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is String) {
        _recognizedText = data;
        notifyListeners();
      }
    });

    // Monitorear el estado del servicio para activar voz en el hilo principal
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkVoiceRecognition();
    });
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _checkVoiceRecognition() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    
    if (isRunning && !_isListening) {
      print('[AlarmProvider] Alarma activa detectada, iniciando voz en hilo principal...');
      _startVoiceInMain();
    } else if (!isRunning && _isListening) {
      print('[AlarmProvider] Alarma detenida, parando voz...');
      _stopVoiceInMain();
    }
  }

  Future<void> _startVoiceInMain() async {
    _isListening = true;
    
    // Buscar la alarma que debería estar sonando ahora
    final now = DateTime.now();
    AlarmModel? activeAlarm;
    for (var alarm in _alarms) {
      if (alarm.isEnabled && alarm.hour == now.hour && (alarm.minute - now.minute).abs() <= 1) {
        activeAlarm = alarm;
        break;
      }
    }

    final command = activeAlarm?.voiceCommand ?? 'detener';
    print('[AlarmProvider] Escuchando comando: "$command"');
    
    await _speechService.startListening(
      voiceCommand: command,
      onResult: (text) {
        _recognizedText = text;
        notifyListeners();
      },
      onMatch: () {
        print('[AlarmProvider] ¡Comando de voz detectado en hilo principal!');
        stopActiveAlarm();
      },
    );
  }

  Future<void> _stopVoiceInMain() async {
    _isListening = false;
    _recognizedText = '';
    await _speechService.stopListening();
    notifyListeners();
  }

  /// Carga las alarmas guardadas al iniciar.
  Future<void> loadAlarms() async {
    _alarms = await _storage.loadAlarms();
    notifyListeners();
  }

  /// Agrega una nueva alarma y la programa en el sistema.
  Future<void> addAlarm(AlarmModel alarm) async {
    _alarms.add(alarm);
    await _storage.saveAlarms(_alarms);
    await AlarmSchedulerService.scheduleAlarm(alarm);
    notifyListeners();
  }

  /// Actualiza una alarma existente y su programación.
  Future<void> updateAlarm(AlarmModel alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      await _storage.saveAlarms(_alarms);
      await AlarmSchedulerService.scheduleAlarm(alarm);
      notifyListeners();
    }
  }

  /// Elimina una alarma y la cancela en el sistema.
  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _storage.saveAlarms(_alarms);
    await AlarmSchedulerService.cancelAlarm(id);
    notifyListeners();
  }

  /// Activa o desactiva una alarma.
  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      alarm.isEnabled = !alarm.isEnabled;
      await _storage.saveAlarms(_alarms);
      
      if (alarm.isEnabled) {
        await AlarmSchedulerService.scheduleAlarm(alarm);
      } else {
        await AlarmSchedulerService.cancelAlarm(id);
      }
      
      notifyListeners();
    }
  }

  /// Solicita los permisos necesarios para el funcionamiento en segundo plano.
  Future<void> requestPermissions() async {
    // 1. Permisos básicos
    await [
      Permission.notification,
      Permission.microphone,
      Permission.systemAlertWindow,
    ].request();

    // 2. Permiso de Alarma Exacta (Crítico para Android 13+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // 3. Ignorar optimizaciones de batería (Vital para Samsung)
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    
    notifyListeners();
  }

  /// Detiene cualquier alarma que esté sonando actualmente.
  Future<void> stopActiveAlarm() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('stop_alarm');
      // También detenemos el servicio directamente por si acaso el handler no responde
      await Future.delayed(const Duration(milliseconds: 500));
      await FlutterForegroundTask.stopService();
    }
  }
}
