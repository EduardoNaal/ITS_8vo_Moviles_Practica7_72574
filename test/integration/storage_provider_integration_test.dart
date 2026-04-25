import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm_app/providers/alarm_provider.dart';
import 'package:alarm_app/models/alarm_model.dart';
import 'package:alarm_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Integración - Almacenamiento y Provider (PI-01 a PI-04)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Guardar alarma y verificar recarga desde StorageService (PI-01)', () async {
      // 1. Instanciamos el provider y agregamos una alarma
      final provider = AlarmProvider();
      await provider.addAlarm(AlarmModel(id: '101', hour: 8, minute: 0, label: 'Trabajo'));

      expect(provider.alarms.length, 1);

      // 2. Simulamos el cierre de la app instanciando un nuevo provider
      final tempStorage = StorageService();
      final alarmsFromDisk = await tempStorage.loadAlarms();

      expect(alarmsFromDisk.length, 1);
      expect(alarmsFromDisk.first.label, 'Trabajo');

      // Y creando otro provider
      final providerRecargado = AlarmProvider();
      await providerRecargado.loadAlarms();

      expect(providerRecargado.alarms.length, 1);
      expect(providerRecargado.alarms.first.id, '101');
      expect(providerRecargado.alarms.first.hour, 8);
    });

    test('Persistencia después de toggle (PI-02)', () async {
      final provider = AlarmProvider();
      await provider.addAlarm(AlarmModel(id: '102', hour: 8, minute: 0, isEnabled: true));
      
      // Hacemos toggle (lo apagamos)
      await provider.toggleAlarm('102');

      // Recargamos en una nueva instancia
      final providerRecargado = AlarmProvider();
      await providerRecargado.loadAlarms();

      expect(providerRecargado.alarms.first.isEnabled, false);
    });

    test('Persistencia después de delete (PI-03)', () async {
      final provider = AlarmProvider();
      await provider.addAlarm(AlarmModel(id: '103', hour: 9, minute: 0));
      
      // Eliminamos
      await provider.deleteAlarm('103');

      // Recargamos en una nueva instancia
      final providerRecargado = AlarmProvider();
      await providerRecargado.loadAlarms();

      expect(providerRecargado.alarms, isEmpty);
    });

    test('Persistencia con datos complejos: días, voz y label (PI-04)', () async {
      final provider = AlarmProvider();
      final days = [false, true, false, true, false, false, false]; // Martes, Jueves
      
      await provider.addAlarm(AlarmModel(
        id: '104', 
        hour: 15, 
        minute: 30, 
        label: 'Gimnasio',
        voiceCommand: 'ya terminé',
        daysOfWeek: days
      ));
      
      // Recargamos en una nueva instancia
      final providerRecargado = AlarmProvider();
      await providerRecargado.loadAlarms();

      final a = providerRecargado.alarms.first;
      expect(a.label, 'Gimnasio');
      expect(a.voiceCommand, 'ya terminé');
      expect(a.daysOfWeek, days);
    });
  });
}
