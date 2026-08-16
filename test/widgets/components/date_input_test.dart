// Widget tests for lib/widgets/components/date_input.dart.
//
// Covers M-ELEM-02 — the +/- day/month/year buttons adjust the date, and
// the controller is kept in yyyy-MM-dd form while the UI shows the
// Buddhist-era year.

import 'package:cocoa_supply/widgets/components/date_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DateInput (M-ELEM-02)', () {
    testWidgets('shows the Buddhist-era year for a 2026-01-11 initial value', (tester) async {
      final controller = TextEditingController(text: '2026-01-11');
      await tester.pumpWidget(wrap(DateInput(label: 'วันที่', controller: controller)));

      expect(find.text('2569'), findsOneWidget);
      expect(find.text('ม.ค.'), findsOneWidget);
    });

    testWidgets('tapping the day + button advances the controller by one day', (tester) async {
      final controller = TextEditingController(text: '2026-01-11');
      await tester.pumpWidget(wrap(DateInput(label: 'วันที่', controller: controller)));

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();

      expect(controller.text, '2026-01-12');
    });

    testWidgets('day rolls over into the next month correctly', (tester) async {
      final controller = TextEditingController(text: '2026-01-31');
      await tester.pumpWidget(wrap(DateInput(label: 'วันที่', controller: controller)));

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();

      expect(controller.text, '2026-02-01');
    });

    testWidgets('tapping the month - button moves back a month', (tester) async {
      final controller = TextEditingController(text: '2026-02-15');
      await tester.pumpWidget(wrap(DateInput(label: 'วันที่', controller: controller)));

      // month picker is the middle column: add[0], month add, ... remove icons
      // order in the tree is day(+,-), month(+,-), year(+,-)
      await tester.tap(find.byIcon(Icons.remove).at(1));
      await tester.pump();

      expect(controller.text, '2026-01-15');
      expect(find.text('ม.ค.'), findsOneWidget);
    });

    testWidgets('typing directly into the year field updates the controller (พ.ศ. -> ค.ศ.)', (tester) async {
      final controller = TextEditingController(text: '2026-01-11');
      await tester.pumpWidget(wrap(DateInput(label: 'วันที่', controller: controller)));

      final yearField = find.widgetWithText(TextField, '2569');
      await tester.enterText(yearField, '2570');
      await tester.pump();

      expect(controller.text, '2027-01-11');
    });
  });
}
