import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_app/models/alarm_model.dart';

void main() {
  group('AlarmModel - Constructor y valores por defecto', () {
    test('crea alarma con valores obligatorios y defaults correctos', () {
      final alarm = AlarmModel(id: '1', hour: 7, minute: 30);

      expect(alarm.id, '1');
      expect(alarm.hour, 7);
      expect(alarm.minute, 30);
      expect(alarm.isEnabled, true);
      expect(alarm.label, '');
      expect(alarm.daysOfWeek, List.filled(7, false));
      expect(alarm.voiceCommand, 'detener');
      expect(alarm.ringtone, 'default');
    });

    test('crea alarma con todos los parámetros personalizados', () {
      final days = [true, true, true, true, true, false, false];
      final alarm = AlarmModel(
        id: '42',
        hour: 14,
        minute: 0,
        isEnabled: false,
        label: 'Medicina',
        daysOfWeek: days,
        voiceCommand: 'ya desperté',
        ringtone: 'campana',
      );

      expect(alarm.id, '42');
      expect(alarm.hour, 14);
      expect(alarm.minute, 0);
      expect(alarm.isEnabled, false);
      expect(alarm.label, 'Medicina');
      expect(alarm.daysOfWeek, days);
      expect(alarm.voiceCommand, 'ya desperté');
      expect(alarm.ringtone, 'campana');
    });
  });

  group('AlarmModel - timeString (formato de hora legible)', () {
    test('formatea hora AM correctamente', () {
      final alarm = AlarmModel(id: '1', hour: 7, minute: 5);
      expect(alarm.timeString, '7:05 AM');
    });

    test('formatea hora PM correctamente', () {
      final alarm = AlarmModel(id: '1', hour: 14, minute: 30);
      expect(alarm.timeString, '2:30 PM');
    });

    test('12:00 muestra como 12:00 PM', () {
      final alarm = AlarmModel(id: '1', hour: 12, minute: 0);
      expect(alarm.timeString, '12:00 PM');
    });

    test('0:00 (medianoche) muestra como 12:00 AM', () {
      final alarm = AlarmModel(id: '1', hour: 0, minute: 0);
      expect(alarm.timeString, '12:00 AM');
    });

    test('23:59 muestra como 11:59 PM', () {
      final alarm = AlarmModel(id: '1', hour: 23, minute: 59);
      expect(alarm.timeString, '11:59 PM');
    });

    test('minuto con un solo dígito se rellena con cero', () {
      final alarm = AlarmModel(id: '1', hour: 9, minute: 3);
      expect(alarm.timeString, '9:03 AM');
    });
  });

  group('AlarmModel - daysString (descripción de días)', () {
    test('sin días seleccionados retorna "Una vez"', () {
      final alarm = AlarmModel(id: '1', hour: 7, minute: 0);
      expect(alarm.daysString, 'Una vez');
    });

    test('todos los días retorna "Todos los días"', () {
      final alarm = AlarmModel(
        id: '1',
        hour: 7,
        minute: 0,
        daysOfWeek: List.filled(7, true),
      );
      expect(alarm.daysString, 'Todos los días');
    });

    test('Lun a Vie retorna "Lun a Vie"', () {
      final alarm = AlarmModel(
        id: '1',
        hour: 7,
        minute: 0,
        daysOfWeek: [true, true, true, true, true, false, false],
      );
      expect(alarm.daysString, 'Lun a Vie');
    });

    test('solo fin de semana retorna "Sáb, Dom"', () {
      final alarm = AlarmModel(
        id: '1',
        hour: 9,
        minute: 0,
        daysOfWeek: [false, false, false, false, false, true, true],
      );
      expect(alarm.daysString, 'Sáb, Dom');
    });

    test('días dispersos se muestran separados por coma', () {
      final alarm = AlarmModel(
        id: '1',
        hour: 7,
        minute: 0,
        daysOfWeek: [true, false, true, false, true, false, false],
      );
      expect(alarm.daysString, 'Lun, Mié, Vie');
    });

    test('un solo día seleccionado muestra el nombre', () {
      final alarm = AlarmModel(
        id: '1',
        hour: 7,
        minute: 0,
        daysOfWeek: [false, false, false, false, false, false, true],
      );
      expect(alarm.daysString, 'Dom');
    });
  });

  group('AlarmModel - Serialización JSON', () {
    test('toJson contiene todas las propiedades', () {
      final alarm = AlarmModel(
        id: '123',
        hour: 8,
        minute: 15,
        isEnabled: true,
        label: 'Despertar',
        voiceCommand: 'cállate',
      );
      final json = alarm.toJson();

      expect(json['id'], '123');
      expect(json['hour'], 8);
      expect(json['minute'], 15);
      expect(json['isEnabled'], true);
      expect(json['label'], 'Despertar');
      expect(json['voiceCommand'], 'cállate');
      expect(json['ringtone'], 'default');
      expect(json['daysOfWeek'], List.filled(7, false));
    });

    test('fromJson reconstruye correctamente la alarma', () {
      final json = {
        'id': '456',
        'hour': 22,
        'minute': 45,
        'isEnabled': false,
        'label': 'Dormir',
        'daysOfWeek': [true, false, true, false, true, false, true],
        'voiceCommand': 'ya voy',
        'ringtone': 'suave',
      };
      final alarm = AlarmModel.fromJson(json);

      expect(alarm.id, '456');
      expect(alarm.hour, 22);
      expect(alarm.minute, 45);
      expect(alarm.isEnabled, false);
      expect(alarm.label, 'Dormir');
      expect(alarm.daysOfWeek, [true, false, true, false, true, false, true]);
      expect(alarm.voiceCommand, 'ya voy');
      expect(alarm.ringtone, 'suave');
    });

    test('fromJson maneja campos faltantes con valores por defecto', () {
      final json = {
        'id': '789',
        'hour': 6,
        'minute': 0,
      };
      final alarm = AlarmModel.fromJson(json);

      expect(alarm.isEnabled, true);
      expect(alarm.label, '');
      expect(alarm.daysOfWeek, List.filled(7, false));
      expect(alarm.voiceCommand, 'detener');
      expect(alarm.ringtone, 'default');
    });

    test('ciclo completo toJson → fromJson preserva todos los datos', () {
      final original = AlarmModel(
        id: 'round-trip',
        hour: 16,
        minute: 30,
        isEnabled: false,
        label: 'Reunión',
        daysOfWeek: [false, true, false, true, false, false, false],
        voiceCommand: 'listo',
        ringtone: 'tono2',
      );

      final json = original.toJson();
      final restored = AlarmModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.hour, original.hour);
      expect(restored.minute, original.minute);
      expect(restored.isEnabled, original.isEnabled);
      expect(restored.label, original.label);
      expect(restored.daysOfWeek, original.daysOfWeek);
      expect(restored.voiceCommand, original.voiceCommand);
      expect(restored.ringtone, original.ringtone);
    });
  });

  group('AlarmModel - serialize / deserialize (String)', () {
    test('serialize produce JSON válido', () {
      final alarm = AlarmModel(id: '1', hour: 10, minute: 0);
      final serialized = alarm.serialize();
      // Verificar que es JSON parseable
      expect(() => jsonDecode(serialized), returnsNormally);
    });

    test('ciclo serialize → deserialize preserva datos', () {
      final original = AlarmModel(
        id: 'ser-test',
        hour: 5,
        minute: 45,
        label: 'Gym',
        voiceCommand: 'alto',
      );

      final serialized = original.serialize();
      final restored = AlarmModel.deserialize(serialized);

      expect(restored.id, original.id);
      expect(restored.hour, original.hour);
      expect(restored.minute, original.minute);
      expect(restored.label, original.label);
      expect(restored.voiceCommand, original.voiceCommand);
    });

    test('deserialize lanza error con JSON malformado', () {
      expect(
        () => AlarmModel.deserialize('esto no es json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AlarmModel - copyWith', () {
    test('copyWith sin cambios produce copia idéntica', () {
      final original = AlarmModel(
        id: 'copy1',
        hour: 8,
        minute: 0,
        label: 'Original',
      );
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.hour, original.hour);
      expect(copy.minute, original.minute);
      expect(copy.label, original.label);
    });

    test('copyWith modifica solo los campos especificados', () {
      final original = AlarmModel(
        id: 'copy2',
        hour: 8,
        minute: 0,
        label: 'Original',
        voiceCommand: 'detener',
      );
      final modified = original.copyWith(
        hour: 10,
        label: 'Modificado',
      );

      expect(modified.hour, 10);
      expect(modified.label, 'Modificado');
      // No modificados
      expect(modified.id, 'copy2');
      expect(modified.minute, 0);
      expect(modified.voiceCommand, 'detener');
    });

    test('copyWith crea una copia independiente de daysOfWeek', () {
      final original = AlarmModel(
        id: 'copy3',
        hour: 7,
        minute: 0,
        daysOfWeek: [true, false, true, false, true, false, false],
      );
      final copy = original.copyWith();

      // Modificar la copia no debe afectar el original
      copy.daysOfWeek[0] = false;
      expect(original.daysOfWeek[0], true);
    });
  });
}
