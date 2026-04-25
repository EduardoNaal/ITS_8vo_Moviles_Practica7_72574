import 'dart:convert';

/// Modelo que representa una alarma con sus propiedades.
class AlarmModel {
  final String id;
  int hour;
  int minute;
  bool isEnabled;
  String label;
  List<bool> daysOfWeek; // [Lun, Mar, Mié, Jue, Vie, Sáb, Dom]
  String voiceCommand;
  String ringtone;

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.label = '',
    List<bool>? daysOfWeek,
    this.voiceCommand = 'detener',
    this.ringtone = 'default',
  }) : daysOfWeek = daysOfWeek ?? List.filled(7, false);

  /// Formato de hora legible.
  String get timeString {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// Texto descriptivo de los días activos.
  String get daysString {
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final activeDays = <String>[];
    for (int i = 0; i < 7; i++) {
      if (daysOfWeek[i]) activeDays.add(dayNames[i]);
    }
    if (activeDays.isEmpty) return 'Una vez';
    if (activeDays.length == 7) return 'Todos los días';
    if (activeDays.length == 5 && !daysOfWeek[5] && !daysOfWeek[6]) {
      return 'Lun a Vie';
    }
    return activeDays.join(', ');
  }

  /// Convierte a JSON para persistencia.
  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'isEnabled': isEnabled,
        'label': label,
        'daysOfWeek': daysOfWeek,
        'voiceCommand': voiceCommand,
        'ringtone': ringtone,
      };

  /// Crea un AlarmModel desde JSON.
  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        isEnabled: json['isEnabled'] as bool? ?? true,
        label: json['label'] as String? ?? '',
        daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
                ?.map((e) => e as bool)
                .toList() ??
            List.filled(7, false),
        voiceCommand: json['voiceCommand'] as String? ?? 'detener',
        ringtone: json['ringtone'] as String? ?? 'default',
      );

  /// Serializa a String para SharedPreferences.
  String serialize() => jsonEncode(toJson());

  /// Deserializa desde String.
  factory AlarmModel.deserialize(String data) =>
      AlarmModel.fromJson(jsonDecode(data) as Map<String, dynamic>);

  AlarmModel copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? isEnabled,
    String? label,
    List<bool>? daysOfWeek,
    String? voiceCommand,
    String? ringtone,
  }) =>
      AlarmModel(
        id: id ?? this.id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        isEnabled: isEnabled ?? this.isEnabled,
        label: label ?? this.label,
        daysOfWeek: daysOfWeek ?? List.from(this.daysOfWeek),
        voiceCommand: voiceCommand ?? this.voiceCommand,
        ringtone: ringtone ?? this.ringtone,
      );
}
