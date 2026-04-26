import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

/// Servicio encargado de la persistencia de datos local.
class StorageService {
  static const String _alarmsKey = 'alarms_list';

  /// Guarda la lista de alarmas en SharedPreferences.
  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = alarms.map((a) => a.serialize()).toList();
    await prefs.setStringList(_alarmsKey, data);
  }

  /// Carga la lista de alarmas guardadas.
  Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = prefs.getStringList(_alarmsKey) ?? [];
    return data.map((s) => AlarmModel.deserialize(s)).toList();
  }

  /// Guarda el comando de voz predeterminado global.
  Future<void> setDefaultVoiceCommand(String command) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_voice_command', command);
  }

  /// Obtiene el comando de voz predeterminado global.
  Future<String> getDefaultVoiceCommand() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('default_voice_command') ?? 'detener';
  }

  /// Elimina todas las alarmas.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alarmsKey);
  }
}
