import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm_app/main.dart';
import 'package:alarm_app/providers/alarm_provider.dart';
import 'package:alarm_app/screens/clock_screen.dart';
import 'package:alarm_app/screens/alarms_screen.dart';
import 'package:alarm_app/screens/timer_screen.dart';
import 'package:alarm_app/screens/stopwatch_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider(
      create: (_) => AlarmProvider(),
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('Pruebas de Usabilidad e Integración - HomeScreen y Navegación (PI-12, PUI-01 a PUI-20)', () {
    testWidgets('HomeScreen inicia en el tab Reloj y muestra sus elementos', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar título e AppBar
      expect(find.text('Reloj'), findsWidgets);

      // Verificar que estamos en ClockScreen
      expect(find.byType(ClockScreen), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Navegación entre tabs funciona correctamente (PI-12, H4)', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Reloj
      expect(find.byType(ClockScreen), findsOneWidget);

      // 2. Navegar a Alarmas
      await tester.tap(find.text('Alarmas'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AlarmsScreen), findsOneWidget);

      // 3. Navegar a Timer
      await tester.tap(find.text('Timer'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TimerScreen), findsOneWidget);

      // 4. Navegar a Cronómetro
      await tester.tap(find.text('Cronómetro'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(StopwatchScreen), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('AlarmsScreen en estado vacío muestra feedback visual (PUI-04)', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      // Navegar a Alarmas
      await tester.tap(find.text('Alarmas'));
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar texto de lista vacía
      expect(find.text('Sin alarmas'), findsOneWidget);
      expect(find.text('Toca + para crear una alarma'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('FAB (+) está visible en la pantalla de alarmas (PUI-08)', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 500));

      // Navegar a Alarmas
      await tester.tap(find.text('Alarmas'));
      await tester.pump(const Duration(milliseconds: 500));

      // Buscar el FloatingActionButton
      expect(find.byIcon(Icons.add_alarm), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
