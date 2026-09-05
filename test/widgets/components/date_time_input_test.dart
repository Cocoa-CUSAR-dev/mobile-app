// Widget tests for lib/widgets/components/date_time_input.dart.
//
// Covers M-ELEM-03 — the +/- buttons for day/month/year/hour/minute adjust
// the datetime, formatted as yyyy-MM-dd HH:mm:ss in the controller.

import 'package:cocoa_supply/widgets/components/date_time_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DateTimeInput (M-ELEM-03)', () {
    testWidgets('shows the Buddhist-era year and zero-padded hour/minute', (tester) async {
      final controller = TextEditingController(text: '2026-01-11 13:05:00');
      await tester.pumpWidget(wrap(DateTimeInput(label: 'เวลาเริ่ม', controller: controller)));

      expect(find.text('2569'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
    });

    testWidgets('tapping the hour + button advances the controller by one hour', (tester) async {
      final controller = TextEditingController(text: '2026-01-11 13:05:00');
      await tester.pumpWidget(wrap(DateTimeInput(label: 'เวลาเริ่ม', controller: controller)));

      // Column order: day, month, year, hour, minute. Each has an add icon.
      await tester.tap(find.byIcon(Icons.add).at(3));
      await tester.pump();

      expect(controller.text, '2026-01-11 14:05:00');
    });

    testWidgets('minute rolling past 59 carries into the hour', (tester) async {
      final controller = TextEditingController(text: '2026-01-11 13:59:00');
      await tester.pumpWidget(wrap(DateTimeInput(label: 'เวลาเริ่ม', controller: controller)));

      await tester.tap(find.byIcon(Icons.add).at(4));
      await tester.pump();

      expect(controller.text, '2026-01-11 14:00:00');
    });
  });
}
