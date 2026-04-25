import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import '../utils/app_theme.dart';

/// Pantalla para crear o editar una alarma con comando de voz.
class AlarmEditScreen extends StatefulWidget {
  final AlarmModel? alarm;

  const AlarmEditScreen({super.key, this.alarm});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late int _hour;
  late int _minute;
  late String _label;
  late List<bool> _daysOfWeek;
  late String _voiceCommand;
  late TextEditingController _labelController;
  late TextEditingController _voiceController;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _hour = widget.alarm?.hour ?? now.hour;
    _minute = widget.alarm?.minute ?? now.minute;
    _label = widget.alarm?.label ?? '';
    _daysOfWeek = widget.alarm?.daysOfWeek != null
        ? List.from(widget.alarm!.daysOfWeek)
        : List.filled(7, false);
    _voiceCommand = widget.alarm?.voiceCommand ?? 'detener';
    _labelController = TextEditingController(text: _label);
    _voiceController = TextEditingController(text: _voiceCommand);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar alarma' : 'Nueva alarma'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de hora
            _buildTimePicker(),
            const SizedBox(height: 28),

            // Días de la semana
            _buildSection('Repetir', _buildDaySelector()),
            const SizedBox(height: 24),

            // Etiqueta
            _buildSection('Etiqueta', _buildLabelField()),
            const SizedBox(height: 24),

            // Comando de voz ⭐
            _buildSection(
              'Comando de voz para cancelar',
              _buildVoiceCommandField(),
              icon: Icons.mic,
              iconColor: AppTheme.accent,
            ),
            const SizedBox(height: 12),
            _buildVoiceHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    final h = _hour % 12 == 0 ? 12 : _hour % 12;
    final period = _hour < 12 ? 'AM' : 'PM';

    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withAlpha(30)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$h:${_minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    color: AppTheme.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 6),
                  child: Text(
                    period,
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca para cambiar la hora',
              style: TextStyle(fontSize: 13, color: AppTheme.textDim),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final isSelected = _daysOfWeek[i];
        return GestureDetector(
          onTap: () => setState(() => _daysOfWeek[i] = !_daysOfWeek[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.divider,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabelField() {
    return TextField(
      controller: _labelController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ej: Despertar, Medicina...',
        hintStyle: TextStyle(color: AppTheme.textDim.withAlpha(150)),
        filled: true,
        fillColor: AppTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onChanged: (v) => _label = v,
    );
  }

  Widget _buildVoiceCommandField() {
    return TextField(
      controller: _voiceController,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ej: detener, ya desperté, cállate...',
        hintStyle: TextStyle(color: AppTheme.textDim.withAlpha(150)),
        filled: true,
        fillColor: AppTheme.surfaceLight,
        prefixIcon: const Icon(Icons.mic_none, color: AppTheme.accent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onChanged: (v) => _voiceCommand = v,
    );
  }

  Widget _buildVoiceHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withAlpha(40)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cuando suene la alarma, di esta frase para cancelarla con tu voz.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.accent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child,
      {IconData? icon, Color? iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor ?? AppTheme.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  void _saveAlarm() {
    final provider = context.read<AlarmProvider>();
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _hour,
      minute: _minute,
      isEnabled: widget.alarm?.isEnabled ?? true,
      label: _label,
      daysOfWeek: _daysOfWeek,
      voiceCommand: _voiceCommand.isEmpty ? 'detener' : _voiceCommand,
    );

    if (_isEditing) {
      provider.updateAlarm(alarm);
    } else {
      provider.addAlarm(alarm);
    }

    Navigator.pop(context);
  }
}
