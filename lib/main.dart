import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'providers/alarm_provider.dart';
import 'screens/clock_screen.dart';
import 'screens/alarms_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar el puerto de comunicación para el servicio en primer plano
  FlutterForegroundTask.initCommunicationPort();

  // Inicializar el administrador de alarmas nativo
  await AndroidAlarmManager.initialize();
  
  // Inicializar el servicio en primer plano
  _initForegroundTask();
  
  runApp(const AlarmApp());
}

void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'alarm_app_channel',
      channelName: 'Servicio de Alarma',
      channelDescription: 'Se usa para mostrar la alarma cuando suena en segundo plano.',
      channelImportance: NotificationChannelImportance.MAX,
      priority: NotificationPriority.MAX,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlarmProvider()..loadAlarms(),
      child: MaterialApp(
        title: 'Reloj & Alarma',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

/// Pantalla principal con navegación por tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ClockScreen(),
    AlarmsScreen(),
    TimerScreen(),
    StopwatchScreen(),
  ];

  final List<String> _titles = [
    'Reloj',
    'Alarmas',
    'Temporizador',
    'Cronómetro',
  ];

  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Solicitar permisos al inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlarmProvider>().requestPermissions();
    });

    // Refrescar el estado del servicio cada segundo para actualizar el botón de detener
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: FlutterForegroundTask.isRunningService,
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return FloatingActionButton.extended(
              heroTag: null, // Evita conflicto de Hero tags
              onPressed: () => context.read<AlarmProvider>().stopActiveAlarm(),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.alarm_off, color: Colors.white),
              label: const Text('DETENER ALARMA', style: TextStyle(color: Colors.white)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.divider.withAlpha(60),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_rounded),
              activeIcon: Icon(Icons.access_time_filled),
              label: 'Reloj',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm_outlined),
              activeIcon: Icon(Icons.alarm),
              label: 'Alarmas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hourglass_empty_rounded),
              activeIcon: Icon(Icons.hourglass_full_rounded),
              label: 'Timer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Cronómetro',
            ),
          ],
        ),
      ),
    );
  }
}
