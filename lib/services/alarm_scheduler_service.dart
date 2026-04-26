import 'dart:developer' as dev;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/alarm_model.dart';
import 'background_alarm_handler.dart';
import 'notification_service.dart';

class AlarmSchedulerService {
  /// Identificador base para las alarmas.
  static const int _alarmIdOffset = 1000;

  /// Programa una alarma.
  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    final int alarmId = _getAlarmId(alarm.id);
    
    // Cancelar si ya existe
    await AndroidAlarmManager.cancel(alarmId);
    
    if (!alarm.isEnabled) return;

    final DateTime now = DateTime.now();
    DateTime scheduleTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduleTime.isBefore(now)) {
      scheduleTime = scheduleTime.add(const Duration(days: 1));
    }

    // Verificar días de la semana
    // Si no hay días seleccionados, suena en el próximo horario disponible (hoy o mañana)
    // Si hay días, buscamos el próximo día activo
    final bool hasDays = alarm.daysOfWeek.any((d) => d);
    if (hasDays) {
      while (!alarm.daysOfWeek[scheduleTime.weekday - 1]) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }
    }

    dev.log('Programando alarma ${alarm.id} para: $scheduleTime');

    await AndroidAlarmManager.oneShotAt(
      scheduleTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// Cancela una alarma.
  static Future<void> cancelAlarm(String alarmId) async {
    await AndroidAlarmManager.cancel(_getAlarmId(alarmId));
  }

  static int _getAlarmId(String id) {
    // Generar un entero determinista a partir del string ID
    return _alarmIdOffset + (id.hashCode % 10000).abs();
  }
}

/// Función de entrada para el servicio en primer plano.
@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(BackgroundAlarmHandler());
}

/// Callback estático que se ejecuta cuando el AlarmManager dispara la alarma.
@pragma('vm:entry-point')
void alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[AlarmScheduler] ¡Alarma disparada! ID: $id');

  // Inicializar notificaciones para este isolate
  await NotificationService.initialize();
  await NotificationService.showFullScreenNotification(
    id,
    '⏰ ¡ALERTA DE ALARMA!',
    'Toca para abrir la aplicación',
  );

  // Iniciar el servicio en primer plano
  if (!await FlutterForegroundTask.isRunningService) {
    print('[AlarmScheduler] Iniciando servicio en primer plano...');
    await FlutterForegroundTask.startService(
      notificationTitle: '¡Alarma Activa!',
      notificationText: 'La alarma está sonando...',
      notificationButtons: [
        const NotificationButton(id: 'stop_alarm', text: 'DETENER'),
      ],
      callback: startForegroundTaskCallback,
    );
    
    // Pequeño delay para asegurar que el servicio inició antes de lanzar la app
    await Future.delayed(const Duration(milliseconds: 500));
    FlutterForegroundTask.wakeUpScreen();
    FlutterForegroundTask.launchApp();
  } else {
    print('[AlarmScheduler] El servicio ya está corriendo. Actualizando...');
    FlutterForegroundTask.wakeUpScreen();
    FlutterForegroundTask.launchApp();
  }
}
