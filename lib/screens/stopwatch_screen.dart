import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Pantalla del cronómetro con laps.
class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<Duration> _laps = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centis =
        (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds.$centis';
    }
    return '$minutes:$seconds.$centis';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildDisplay(),
              const SizedBox(height: 36),
              _buildControls(),
              const SizedBox(height: 24),
              _buildLapsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centis =
        (elapsed.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (elapsed.inHours > 0)
              Text(
                '${elapsed.inHours.toString().padLeft(2, '0')}:',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w200,
                  color: AppTheme.textPrimary,
                ),
              ),
            Text(
              '$minutes:$seconds',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w200,
                color: AppTheme.textPrimary,
                letterSpacing: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '.$centis',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        if (_laps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Vuelta ${_laps.length + 1}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_stopwatch.isRunning || _stopwatch.elapsedMilliseconds > 0) ...[
          // Reset / Lap
          _buildControlButton(
            icon: _stopwatch.isRunning ? Icons.flag_rounded : Icons.refresh_rounded,
            label: _stopwatch.isRunning ? 'Vuelta' : 'Reset',
            color: _stopwatch.isRunning ? AppTheme.warning : AppTheme.danger,
            onTap: _stopwatch.isRunning ? _addLap : _reset,
          ),
          const SizedBox(width: 32),
        ],
        // Start / Stop
        _buildControlButton(
          icon: _stopwatch.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: _stopwatch.isRunning ? 'Detener' : 'Iniciar',
          color: _stopwatch.isRunning ? AppTheme.danger : AppTheme.accent,
          onTap: _stopwatch.isRunning ? _stop : _start,
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

  Widget _buildLapsList() {
    if (_laps.isEmpty) {
      return Center(
        child: Text(
          'Sin vueltas registradas',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textDim.withAlpha(120),
          ),
        ),
      );
    }

    // Encontrar mejor y peor vuelta
    Duration? best, worst;
    if (_laps.length >= 2) {
      final lapDurations = <Duration>[];
      for (int i = 0; i < _laps.length; i++) {
        final prev = i > 0 ? _laps[i - 1] : Duration.zero;
        lapDurations.add(_laps[i] - prev);
      }
      best = lapDurations.reduce((a, b) => a < b ? a : b);
      worst = lapDurations.reduce((a, b) => a > b ? a : b);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _laps.length,
      reverse: true,
      itemBuilder: (context, index) {
        final lapIndex = _laps.length - 1 - index;
        final total = _laps[lapIndex];
        final prev = lapIndex > 0 ? _laps[lapIndex - 1] : Duration.zero;
        final lapDuration = total - prev;

        Color? labelColor;
        if (best != null && lapDuration == best) {
          labelColor = AppTheme.accent;
        } else if (worst != null && lapDuration == worst) {
          labelColor = AppTheme.danger;
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.divider.withAlpha(60)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'V${lapIndex + 1}',
                  style: TextStyle(
                    fontSize: 15,
                    color: labelColor ?? AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _formatDuration(lapDuration),
                  style: TextStyle(
                    fontSize: 17,
                    color: labelColor ?? AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                _formatDuration(total),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDim,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _start() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {});
    });
  }

  void _stop() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _reset() {
    _stopwatch.reset();
    _laps.clear();
    setState(() {});
  }

  void _addLap() {
    _laps.add(_stopwatch.elapsed);
    setState(() {});
  }
}
