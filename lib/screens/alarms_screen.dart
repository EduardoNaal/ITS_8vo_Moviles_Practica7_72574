import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import '../utils/app_theme.dart';
import 'alarm_edit_screen.dart';

/// Pantalla que muestra la lista de alarmas con opciones CRUD.
class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AlarmProvider>(
        builder: (context, provider, _) {
          if (provider.alarms.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildAlarmList(context, provider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // Evita conflicto de Hero tags
        onPressed: () => _openAlarmEditor(context),
        child: const Icon(Icons.add_alarm, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off_rounded,
            size: 80,
            color: AppTheme.textDim.withAlpha(100),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin alarmas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para crear una alarma',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textDim.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(BuildContext context, AlarmProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: provider.alarms.length,
      itemBuilder: (context, index) {
        final alarm = provider.alarms[index];
        return _AlarmTile(
          alarm: alarm,
          onToggle: () => provider.toggleAlarm(alarm.id),
          onTap: () => _openAlarmEditor(context, alarm: alarm),
          onDismissed: () => provider.deleteAlarm(alarm.id),
        );
      },
    );
  }

  void _openAlarmEditor(BuildContext context, {AlarmModel? alarm}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlarmEditScreen(alarm: alarm),
      ),
    );
  }
}

/// Tile individual de una alarma en la lista.
class _AlarmTile extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 28),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: alarm.isEnabled
                ? AppTheme.surface
                : AppTheme.surface.withAlpha(120),
            borderRadius: BorderRadius.circular(16),
            border: alarm.isEnabled
                ? Border.all(color: AppTheme.primary.withAlpha(30))
                : null,
          ),
          child: Row(
            children: [
              // Hora
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.timeString,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: alarm.isEnabled
                            ? AppTheme.textPrimary
                            : AppTheme.textDim,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          alarm.label.isNotEmpty ? alarm.label : alarm.daysString,
                          style: TextStyle(
                            fontSize: 13,
                            color: alarm.isEnabled
                                ? AppTheme.textSecondary
                                : AppTheme.textDim,
                          ),
                        ),
                        if (alarm.voiceCommand.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.mic,
                            size: 14,
                            color: alarm.isEnabled
                                ? AppTheme.accent
                                : AppTheme.textDim,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '"${alarm.voiceCommand}"',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: alarm.isEnabled
                                  ? AppTheme.accent.withAlpha(180)
                                  : AppTheme.textDim,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Switch
              Switch(
                value: alarm.isEnabled,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
