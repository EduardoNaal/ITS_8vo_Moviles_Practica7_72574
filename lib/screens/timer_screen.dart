import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Pantalla del temporizador (cuenta regresiva).
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  late AnimationController _progressController;
  
  late FixedExtentScrollController _hoursCtrl;
  late FixedExtentScrollController _minutesCtrl;
  late FixedExtentScrollController _secondsCtrl;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _hoursCtrl = FixedExtentScrollController(initialItem: _hours);
    _minutesCtrl = FixedExtentScrollController(initialItem: _minutes);
    _secondsCtrl = FixedExtentScrollController(initialItem: _seconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning && !_isPaused) _buildTimeInput(),
                  if (_isRunning || _isPaused) _buildCountdown(),
                  const SizedBox(height: 40),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScrollWheel('h', _hours, 23, _hoursCtrl, (v) => setState(() => _hours = v)),
        const Text(' : ', style: TextStyle(fontSize: 40, color: AppTheme.textDim)),
        _buildScrollWheel('m', _minutes, 59, _minutesCtrl, (v) => setState(() => _minutes = v)),
        const Text(' : ', style: TextStyle(fontSize: 40, color: AppTheme.textDim)),
        _buildScrollWheel('s', _seconds, 59, _secondsCtrl, (v) => setState(() => _seconds = v)),
      ],
    );
  }

  Widget _buildScrollWheel(
      String label, int value, int max, FixedExtentScrollController controller, ValueChanged<int> onChanged) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 140,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index > max) return null;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: index == value ? 40 : 28,
                      fontWeight: FontWeight.w300,
                      color: index == value
                          ? AppTheme.textPrimary
                          : AppTheme.textDim,
                    ),
                  ),
                );
              },
              childCount: max + 1,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;

    final progress = _totalSeconds > 0
        ? _remainingSeconds / _totalSeconds
        : 0.0;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progreso circular
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingSeconds <= 10 ? AppTheme.danger : AppTheme.primary,
              ),
            ),
          ),
          // Tiempo restante
          Text(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w200,
              color: _remainingSeconds <= 10
                  ? AppTheme.danger
                  : AppTheme.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (!_isRunning && !_isPaused) {
      // Estado inicial: solo botón Iniciar
      return ElevatedButton(
        onPressed: () {
          if (_canStart) {
            _startTimer();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Por favor, desliza los números arriba/abajo para seleccionar un tiempo válido.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text('Iniciar', style: TextStyle(fontSize: 18)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancelar
        _buildControlButton(
          icon: Icons.stop_rounded,
          label: 'Cancelar',
          color: AppTheme.danger,
          onTap: _resetTimer,
        ),
        const SizedBox(width: 24),
        // Pausar / Reanudar
        _buildControlButton(
          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: _isRunning ? 'Pausar' : 'Reanudar',
          color: AppTheme.primary,
          onTap: _isRunning ? _pauseTimer : _resumeTimer,
          large: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool large = false,
  }) {
    final size = large ? 72.0 : 60.0;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(25),
              border: Border.all(color: color.withAlpha(100), width: 2),
            ),
            child: Icon(icon, color: color, size: large ? 36 : 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  bool get _canStart => _hours > 0 || _minutes > 0 || _seconds > 0;

  void _startTimer() {
    _totalSeconds = _hours * 3600 + _minutes * 60 + _seconds;
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _isPaused = false;
    setState(() {});
    _tick();
  }

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isPaused = false;
        });
        _showTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _tick();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = 0;
      _totalSeconds = 0;
    });
  }

  void _showTimerComplete() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: AppTheme.accent),
            SizedBox(width: 10),
            Text('¡Tiempo!', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: const Text(
          'El temporizador ha terminado.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
