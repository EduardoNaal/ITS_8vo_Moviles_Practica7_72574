import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm_model.dart';
import '../services/storage_service.dart';
import '../services/alarm_scheduler_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../screens/alarm_ringing_screen.dart';
import '../main.dart';

/// Provider principal que gestiona el estado de las alarmas.
class AlarmProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AudioService _audioService = AudioService();
  List<AlarmModel> _alarms = [];
  String _defaultVoiceCommand = 'detener'; // Frase maestra
  Timer? _monitorTimer;

  String? _firedAlarmId;
  int? _firedAtMinute;
  bool _isAlarmActive = false;

  List<AlarmModel> get alarms => _alarms;
  String get defaultVoiceCommand => _defaultVoiceCommand;
  bool get isAlarmActive => _isAlarmActive;

  Future<void>? initialization;

  AlarmProvider() {
    initialization = _init();
  }

  Future<void> _init() async {
    await loadAlarms();
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  void _checkAlarms() {
    if (_isAlarmActive) return;

    final now = DateTime.now();
    if (_firedAlarmId != null && _firedAtMinute == now.minute) return;

    if (_firedAtMinute != null && _firedAtMinute != now.minute) {
      _firedAlarmId = null;
      _firedAtMinute = null;
    }

    for (var alarm in _alarms) {
      if (!alarm.isEnabled) continue;

      if (alarm.hour == now.hour && alarm.minute == now.minute) {
        final hasDays = alarm.daysOfWeek.any((d) => d);
        if (hasDays && !alarm.daysOfWeek[now.weekday - 1]) continue;
        if (_firedAlarmId == alarm.id) continue;

        print('[AlarmProvider] ⏰ ¡ALARMA! Disparando: ${alarm.id}');
        _fireAlarm(alarm);
        return;
      }
    }
  }

  Future<void> _fireAlarm(AlarmModel alarm) async {
    _isAlarmActive = true;
    _firedAlarmId = alarm.id;
    _firedAtMinute = DateTime.now().minute;
    notifyListeners();

    // 1. Iniciar Audio y Vibración (En paralelo para no bloquear)
    print('[AlarmProvider] 🔊 Iniciando audio y vibración...');
    _audioService.playAlarm();
    
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500], repeat: 0);
    }

    // 2. Full Screen Intent (Crítico para Samsung)
    print('[AlarmProvider] 🔔 Lanzando Full Screen Notification...');
    await NotificationService.showFullScreenNotification(
      alarm.id.hashCode,
      '⏰ ¡ALARMA!',
      'Es hora de despertar: ${alarm.hour}:${alarm.minute.toString().padLeft(2, '0')}',
    );

    // 3. Servicio de Fondo y WakeUp (Doble capa de seguridad)
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.startService(
          notificationTitle: '⏰ Alarma Activa',
          notificationText: 'La alarma está sonando...',
          callback: startForegroundTaskCallback,
        );
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      FlutterForegroundTask.wakeUpScreen();
      FlutterForegroundTask.launchApp();
    } catch (e) {
      print('[AlarmProvider] Error en ForegroundTask: $e');
    }

    _navigateToRingingScreen(alarm);
  }

  void _navigateToRingingScreen(AlarmModel alarm, [int retryCount = 0]) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => AlarmRingingScreen(alarm: alarm)),
      );
    } else if (retryCount < 10) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateToRingingScreen(alarm, retryCount + 1);
      });
    }
  }

  Future<void> stopActiveAlarm() async {
    print('[AlarmProvider] 🛑 Deteniendo alarma y limpiando todo...');
    _isAlarmActive = false;
    
    await _audioService.stopAlarm();
    Vibration.cancel();

    // Limpiar todas las notificaciones de alarma
    await NotificationService.cancelAll();

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      print('[AlarmProvider] Error al detener servicio: $e');
    }

    if (_firedAlarmId != null) {
      final index = _alarms.indexWhere((a) => a.id == _firedAlarmId);
      if (index != -1) {
        final alarm = _alarms[index];
        if (!alarm.daysOfWeek.any((d) => d)) {
          alarm.isEnabled = false;
          await _storage.saveAlarms(_alarms);
        }
      }
    }

    notifyListeners();
  }

  Future<void> loadAlarms() async {
    _alarms = await _storage.loadAlarms();
    _defaultVoiceCommand = await _storage.getDefaultVoiceCommand();
    notifyListeners();
  }

  Future<void> updateDefaultVoiceCommand(String command) async {
    _defaultVoiceCommand = command;
    await _storage.setDefaultVoiceCommand(command);
    notifyListeners();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    _alarms.add(alarm);
    await _storage.saveAlarms(_alarms);
    await AlarmSchedulerService.scheduleAlarm(alarm);
    notifyListeners();
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      await _storage.saveAlarms(_alarms);
      await AlarmSchedulerService.scheduleAlarm(alarm);
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _storage.saveAlarms(_alarms);
    await AlarmSchedulerService.cancelAlarm(id);
    notifyListeners();
  }

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

  Future<void> requestPermissions() async {
    await [
      Permission.notification,
      Permission.microphone,
      Permission.systemAlertWindow,
    ].request();

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    
    notifyListeners();
  }
}
