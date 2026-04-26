import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_app/screens/timer_screen.dart';

void main() {
  testWidgets('TimerScreen test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TimerScreen()));

    // Verify initial state
    expect(find.text('Iniciar'), findsOneWidget);
    
    // The button is always enabled, but shows a SnackBar if time is 0.
    final startButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(startButton.onPressed, isNotNull);

    // Scroll the minutes wheel by dragging it up
    // In our UI, there are three ListWheelScrollViews
    final scrollViews = find.byType(ListWheelScrollView);
    expect(scrollViews, findsNWidgets(3));

    // Scroll the minutes wheel (index 1)
    await tester.drag(scrollViews.at(1), const Offset(0, -50));
    await tester.pumpAndSettle();

    // Now the button should be enabled
    final startButtonEnabled = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(startButtonEnabled.onPressed, isNotNull);

    // Tap start
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    
    // Verify it changed to countdown and 'Pausar' / 'Cancelar' buttons show
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    
    await tester.pumpWidget(Container());
  });
}
