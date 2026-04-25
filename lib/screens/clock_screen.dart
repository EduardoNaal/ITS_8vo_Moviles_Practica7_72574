import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_theme.dart';

/// Pantalla del reloj digital y analógico con hora en tiempo real.
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late DateTime _now;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Reloj analógico
                _buildAnalogClock(),
                const SizedBox(height: 48),
                // Hora digital
                _buildDigitalClock(),
                const SizedBox(height: 12),
                // Fecha
                _buildDate(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalogClock() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(
          painter: _AnalogClockPainter(dateTime: _now),
        ),
      ),
    );
  }

  Widget _buildDigitalClock() {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final period = _now.hour < 12 ? 'AM' : 'PM';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$hour:$minute',
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: AppTheme.textPrimary,
            letterSpacing: 2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, _) => Opacity(
              opacity: 0.4 + (_pulseController.value * 0.6),
              child: Text(
                ':$second',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 6),
          child: Text(
            period,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDate() {
    const days = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo',
    ];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final dayName = days[_now.weekday - 1];
    final monthName = months[_now.month - 1];

    return Text(
      '$dayName, ${_now.day} de $monthName de ${_now.year}',
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

/// Painter del reloj analógico.
class _AnalogClockPainter extends CustomPainter {
  final DateTime dateTime;

  _AnalogClockPainter({required this.dateTime});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Fondo del reloj
    final bgPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Borde exterior
    final borderPaint = Paint()
      ..color = AppTheme.primary.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // Marcas de las horas
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final isMain = i % 3 == 0;
      final inner = radius - (isMain ? 24 : 16);
      final outer = radius - 8;

      final p1 = Offset(
        center.dx + inner * cos(angle),
        center.dy + inner * sin(angle),
      );
      final p2 = Offset(
        center.dx + outer * cos(angle),
        center.dy + outer * sin(angle),
      );

      final tickPaint = Paint()
        ..color = isMain ? AppTheme.textPrimary : AppTheme.textDim
        ..strokeWidth = isMain ? 3 : 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Marcas de los minutos
    for (int i = 0; i < 60; i++) {
      if (i % 5 != 0) {
        final angle = (i * 6 - 90) * pi / 180;
        final dotPos = Offset(
          center.dx + (radius - 10) * cos(angle),
          center.dy + (radius - 10) * sin(angle),
        );
        final dotPaint = Paint()..color = AppTheme.textDim.withAlpha(100);
        canvas.drawCircle(dotPos, 1, dotPaint);
      }
    }

    // Manecilla de horas
    _drawHand(
      canvas, center,
      angle: ((dateTime.hour % 12) + dateTime.minute / 60) * 30 - 90,
      length: radius * 0.5,
      width: 4,
      color: AppTheme.textPrimary,
    );

    // Manecilla de minutos
    _drawHand(
      canvas, center,
      angle: (dateTime.minute + dateTime.second / 60) * 6 - 90,
      length: radius * 0.7,
      width: 2.5,
      color: AppTheme.textPrimary,
    );

    // Manecilla de segundos
    _drawHand(
      canvas, center,
      angle: dateTime.second * 6.0 - 90,
      length: radius * 0.78,
      width: 1.2,
      color: AppTheme.primary,
    );

    // Centro del reloj
    final centerDotPaint = Paint()..color = AppTheme.primary;
    canvas.drawCircle(center, 5, centerDotPaint);
    final innerDot = Paint()..color = AppTheme.background;
    canvas.drawCircle(center, 2, innerDot);
  }

  void _drawHand(
    Canvas canvas, Offset center, {
    required double angle,
    required double length,
    required double width,
    required Color color,
  }) {
    final rad = angle * pi / 180;
    final end = Offset(
      center.dx + length * cos(rad),
      center.dy + length * sin(rad),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, end, paint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) =>
      oldDelegate.dateTime.second != dateTime.second;
}
