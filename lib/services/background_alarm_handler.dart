import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:vibration/vibration.dart';
import 'audio_service.dart';
import 'storage_service.dart';
import '../models/alarm_model.dart';

@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundAlarmHandler());
}

class BackgroundAlarmHandler extends TaskHandler {
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  
  AlarmModel? _activeAlarm;
  Timer? _vibrationTimer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[ForegroundTask] ==========================================');
    print('[ForegroundTask] [${timestamp.toIso8601String()}] onStart: Iniciando servicio de alarma...');
    
    try {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterForegroundTask.initCommunicationPort();
      
      // 1. Cargar las alarmas para encontrar cuál debe sonar ahora
      print('[ForegroundTask] Cargando alarmas desde SharedPreferences...');
      final alarms = await _storageService.loadAlarms();
      final now = DateTime.now();
      print('[ForegroundTask] Total alarmas cargadas: ${alarms.length}. Hora actual: ${now.hour}:${now.minute}');
      
      // Buscamos la alarma más cercana al tiempo actual (tolerancia de 2 minutos)
      for (var alarm in alarms) {
        if (alarm.isEnabled && 
            alarm.hour == now.hour && 
            (alarm.minute - now.minute).abs() <= 1) {
          _activeAlarm = alarm;
          print('[ForegroundTask] Alarma activa encontrada: ${alarm.id} (Comando: ${alarm.voiceCommand})');
          break;
        }
      }

      if (_activeAlarm == null) {
        print('[ForegroundTask] ADVERTENCIA: No se encontró alarma activa coincidente. Usando valores por defecto.');
      }

      // 2. Iniciar audio y vibración
      print('[ForegroundTask] Iniciando audio y vibración...');
      await _audioService.playAlarm();
      
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        Vibration.vibrate(duration: 1000);
      });

      // Intentar abrir la app desde el handler también para mayor seguridad
      FlutterForegroundTask.launchApp();

    } catch (e, stack) {
      print('[ForegroundTask] ERROR en onStart: $e');
      print('[ForegroundTask] STACKTRACE: $stack');
    }
    
    print('[ForegroundTask] onStart completado.');
    print('[ForegroundTask] ==========================================');
  }

  @override
  void onReceiveData(Object data) {
    print('[ForegroundTask] Datos recibidos desde la UI: $data');
    if (data == 'stop_alarm') {
      _stopEverything();
    }
  }



  Future<void> _stopEverything() async {
    print('[ForegroundTask] Deteniendo todo...');
    _vibrationTimer?.cancel();
    await _audioService.stopAlarm();
    Vibration.cancel();
    
    // Si la alarma no es recurrente, desactivarla
    if (_activeAlarm != null && _activeAlarm!.daysOfWeek.every((d) => !d)) {
      final alarms = await _storageService.loadAlarms();
      final index = alarms.indexWhere((a) => a.id == _activeAlarm!.id);
      if (index != -1) {
        alarms[index].isEnabled = false;
        await _storageService.saveAlarms(alarms);
        print('[ForegroundTask] Alarma temporal desactivada.');
      }
    }
    
    // Detener el servicio
    print('[ForegroundTask] Deteniendo servicio en primer plano.');
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // No necesitamos tareas repetitivas aquí
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isDone) async {
    _vibrationTimer?.cancel();
    _audioService.dispose();
  }

  @override
  void onNotificationPressed() {
    // Al presionar la notificación, podemos abrir la app
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('[ForegroundTask] Botón de notificación presionado: $id');
    if (id == 'stop_alarm' || id == 'cancel_button') {
      _stopEverything();
    }
  }
}
