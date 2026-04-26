import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm_app/providers/alarm_provider.dart';
import 'package:alarm_app/models/alarm_model.dart';
import '../test_utils.dart';

void main() {
  // Inicializar el binding de Flutter para usar SharedPreferences en tests
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    setupTestMocks();
    SharedPreferences.setMockInitialValues({});
  });

  group('AlarmProvider - Estado inicial', () {
    test('inicia con lista de alarmas vacía', () async {
      final provider = AlarmProvider();
      await provider.initialization;
      expect(provider.alarms, isEmpty);
    });
  });

  group('AlarmProvider - Operaciones CRUD', () {
    late AlarmProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = AlarmProvider();
      await provider.initialization;
    });

    test('addAlarm agrega una alarma a la lista', () async {
      final alarm = AlarmModel(id: '1', hour: 7, minute: 30);
      await provider.addAlarm(alarm);

      expect(provider.alarms.length, 1);
      expect(provider.alarms.first.id, '1');
      expect(provider.alarms.first.hour, 7);
    });

    test('addAlarm puede agregar múltiples alarmas', () async {
      await provider.addAlarm(AlarmModel(id: '1', hour: 6, minute: 0));
      await provider.addAlarm(AlarmModel(id: '2', hour: 7, minute: 30));
      await provider.addAlarm(AlarmModel(id: '3', hour: 8, minute: 0));

      expect(provider.alarms.length, 3);
    });

    test('updateAlarm modifica una alarma existente', () async {
      final alarm = AlarmModel(id: '1', hour: 7, minute: 30, label: 'Original');
      await provider.addAlarm(alarm);

      final updated = alarm.copyWith(hour: 8, label: 'Actualizada');
      await provider.updateAlarm(updated);

      expect(provider.alarms.first.hour, 8);
      expect(provider.alarms.first.label, 'Actualizada');
      expect(provider.alarms.length, 1);
    });

    test('updateAlarm no hace nada si el ID no existe', () async {
      await provider.addAlarm(AlarmModel(id: '1', hour: 7, minute: 0));

      final phantom = AlarmModel(id: 'no-existe', hour: 12, minute: 0);
      await provider.updateAlarm(phantom);

      expect(provider.alarms.length, 1);
      expect(provider.alarms.first.hour, 7);
    });

    test('deleteAlarm elimina la alarma con el ID dado', () async {
      await provider.addAlarm(AlarmModel(id: '1', hour: 7, minute: 0));
      await provider.addAlarm(AlarmModel(id: '2', hour: 8, minute: 0));
      await provider.addAlarm(AlarmModel(id: '3', hour: 9, minute: 0));

      await provider.deleteAlarm('2');

      expect(provider.alarms.length, 2);
      expect(provider.alarms.any((a) => a.id == '2'), false);
    });

    test('deleteAlarm no hace nada si el ID no existe', () async {
      await provider.addAlarm(AlarmModel(id: '1', hour: 7, minute: 0));

      await provider.deleteAlarm('no-existe');

      expect(provider.alarms.length, 1);
    });

    test('toggleAlarm alterna el estado isEnabled', () async {
      final alarm = AlarmModel(id: '1', hour: 7, minute: 0, isEnabled: true);
      await provider.addAlarm(alarm);

      expect(provider.alarms.first.isEnabled, true);

      await provider.toggleAlarm('1');
      expect(provider.alarms.first.isEnabled, false);

      await provider.toggleAlarm('1');
      expect(provider.alarms.first.isEnabled, true);
    });

    test('toggleAlarm no hace nada si el ID no existe', () async {
      await provider.addAlarm(
        AlarmModel(id: '1', hour: 7, minute: 0, isEnabled: true),
      );

      await provider.toggleAlarm('no-existe');
      expect(provider.alarms.first.isEnabled, true);
    });
  });

  group('AlarmProvider - Notificación de cambios', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('addAlarm notifica a los listeners', () async {
      final provider = AlarmProvider();
      await provider.initialization;
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.addAlarm(AlarmModel(id: '1', hour: 7, minute: 0));
      expect(notifyCount, 1);
    });

    test('deleteAlarm notifica a los listeners', () async {
      final provider = AlarmProvider();
      await provider.initialization;
      await provider.addAlarm(AlarmModel(id: '1', hour: 7, minute: 0));

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.deleteAlarm('1');
      expect(notifyCount, 1);
    });

    test('toggleAlarm notifica a los listeners', () async {
      final provider = AlarmProvider();
      await provider.initialization;
      await provider.addAlarm(AlarmModel(id: '1', hour: 7, minute: 0));

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleAlarm('1');
      expect(notifyCount, 1);
    });

    test('updateAlarm notifica a los listeners', () async {
      final provider = AlarmProvider();
      await provider.initialization;
      final alarm = AlarmModel(id: '1', hour: 7, minute: 0);
      await provider.addAlarm(alarm);

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.updateAlarm(alarm.copyWith(hour: 10));
      expect(notifyCount, 1);
    });
  });

  group('AlarmProvider - Escenarios combinados', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('CRUD completo: add → update → toggle → delete', () async {
      final provider = AlarmProvider();
      await provider.initialization;

      // Add
      await provider.addAlarm(
        AlarmModel(id: '1', hour: 7, minute: 0, label: 'Test'),
      );
      expect(provider.alarms.length, 1);

      // Update
      await provider.updateAlarm(
        provider.alarms.first.copyWith(label: 'Actualizado'),
      );
      expect(provider.alarms.first.label, 'Actualizado');

      // Toggle off
      await provider.toggleAlarm('1');
      expect(provider.alarms.first.isEnabled, false);

      // Delete
      await provider.deleteAlarm('1');
      expect(provider.alarms, isEmpty);
    });

    test('múltiples alarmas se mantienen independientes', () async {
      final provider = AlarmProvider();
      await provider.initialization;
      await provider.addAlarm(
        AlarmModel(id: 'a', hour: 6, minute: 0, label: 'Primera'),
      );
      await provider.addAlarm(
        AlarmModel(id: 'b', hour: 7, minute: 0, label: 'Segunda'),
      );

      await provider.toggleAlarm('a');

      expect(provider.alarms[0].isEnabled, false); // 'a' desactivada
      expect(provider.alarms[1].isEnabled, true);  // 'b' sin cambios
    });
  });
}
