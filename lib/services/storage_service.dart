import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

/// Servicio de persistencia local para alarmas usando SharedPreferences.
class StorageService {
  static const _alarmsKey = 'alarms_list';

  /// Guarda la lista de alarmas.
  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final data = alarms.map((a) => a.serialize()).toList();
    await prefs.setStringList(_alarmsKey, data);
  }

  /// Carga la lista de alarmas guardadas.
  Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_alarmsKey) ?? [];
    return data.map((s) => AlarmModel.deserialize(s)).toList();
  }

  /// Elimina todas las alarmas.
  Future<void> clearAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alarmsKey);
  }
}
