import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm_model.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';
import '../utils/app_theme.dart';

/// Pantalla fullscreen que aparece cuando suena una alarma.
/// Permite cancelar por voz o por botón manual.
class AlarmRingingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final SpeechService _speechService = SpeechService();

  String _recognizedText = '';
  bool _isListening = false;
  bool _isCancelled = false;
  bool _speechAvailable = false;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startAlarm();
  }

  Future<void> _startAlarm() async {
    // Reproducir sonido
    await _audioService.playAlarm();

    // Vibrar
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500],
        repeat: 0,
      );
    }

    // Iniciar reconocimiento de voz
    _speechAvailable = await _speechService.initialize();
    if (_speechAvailable) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);

    await _speechService.startListening(
      voiceCommand: widget.alarm.voiceCommand,
      onResult: (text) {
        if (mounted) {
          setState(() => _recognizedText = text);
        }
      },
      onMatch: () {
        _cancelAlarm(byVoice: true);
      },
    );
  }

  Future<void> _cancelAlarm({bool byVoice = false}) async {
    if (_isCancelled) return;

    setState(() => _isCancelled = true);

    await _audioService.stopAlarm();
    await _speechService.stopListening();
    Vibration.cancel();

    if (mounted) {
      // Mostrar feedback
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                byVoice ? Icons.mic : Icons.alarm_off,
                color: AppTheme.accent,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                byVoice
                    ? '¡Alarma cancelada por voz!'
                    : 'Alarma cancelada',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (byVoice) ...[
                const SizedBox(height: 8),
                Text(
                  'Comando: "${widget.alarm.voiceCommand}"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _speechService.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Hora de la alarma
            _buildAlarmTime(),
            if (widget.alarm.label.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.alarm.label,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const Spacer(),
            // Indicador de voz
            _buildVoiceIndicator(),
            const Spacer(),
            // Texto reconocido
            if (_recognizedText.isNotEmpty) _buildRecognizedText(),
            const SizedBox(height: 16),
            // Botón manual de cancelar
            _buildCancelButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmTime() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, _) => Transform.scale(
        scale: _pulseAnimation.value,
        child: Text(
          widget.alarm.timeString,
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: AppTheme.textPrimary,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    if (!_speechAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_off, color: AppTheme.danger, size: 20),
            SizedBox(width: 8),
            Text(
              'Micrófono no disponible',
              style: TextStyle(color: AppTheme.danger, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Ondas de audio animadas
        AnimatedBuilder(
          animation: _waveController,
          builder: (_, _) => CustomPaint(
            size: const Size(200, 80),
            painter: _AudioWavePainter(
              progress: _waveController.value,
              isActive: _isListening,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.accent.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withAlpha(40)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: AppTheme.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _isListening
                    ? 'Escuchando... di "${widget.alarm.voiceCommand}"'
                    : 'Iniciando micrófono...',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecognizedText() {
    final matches = _recognizedText
        .toLowerCase()
        .contains(widget.alarm.voiceCommand.toLowerCase());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Texto detectado:',
              style: TextStyle(fontSize: 12, color: AppTheme.textDim),
            ),
            const SizedBox(height: 6),
            Text(
              '"$_recognizedText"',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: matches ? AppTheme.accent : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () => _cancelAlarm(byVoice: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.danger.withAlpha(120), width: 2),
          color: AppTheme.danger.withAlpha(15),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_off, color: AppTheme.danger, size: 24),
            SizedBox(width: 10),
            Text(
              'Cancelar alarma',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter de ondas de audio animadas.
class _AudioWavePainter extends CustomPainter {
  final double progress;
  final bool isActive;

  _AudioWavePainter({required this.progress, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive
          ? AppTheme.accent.withAlpha(120)
          : AppTheme.textDim.withAlpha(60)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;

    for (double x = 0; x < size.width; x += 1) {
      final normalized = x / size.width;
      final amplitude = isActive
          ? sin(normalized * pi) * 25 * (0.5 + 0.5 * sin(progress * 2 * pi))
          : sin(normalized * pi) * 5;
      final y = midY +
          amplitude *
              sin((normalized * 4 * pi) + (progress * 2 * pi));

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Segunda onda con desfase
    if (isActive) {
      final paint2 = Paint()
        ..color = AppTheme.primary.withAlpha(60)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path2 = Path();
      for (double x = 0; x < size.width; x += 1) {
        final normalized = x / size.width;
        final amplitude =
            sin(normalized * pi) * 18 * (0.5 + 0.5 * cos(progress * 2 * pi));
        final y = midY +
            amplitude *
                sin((normalized * 3 * pi) + (progress * 2 * pi) + 1);

        if (x == 0) {
          path2.moveTo(x, y);
        } else {
          path2.lineTo(x, y);
        }
      }
      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWavePainter oldDelegate) => true;
}
