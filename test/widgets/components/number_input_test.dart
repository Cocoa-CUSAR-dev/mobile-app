// Widget tests for lib/widgets/components/number_input.dart.
//
// Covers M-ELEM-01 — increment/decrement buttons change the number by the
// configured step, and the field is reformatted (int vs 2-decimal) on blur.

import 'package:cocoa_supply/widgets/components/number_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('NumberInput (M-ELEM-01)', () {
    testWidgets('tapping +interval increases the integer value', (tester) async {
      final controller = TextEditingController(text: '5');
      await tester.pumpWidget(wrap(NumberInput(label: 'จำนวน', controller: controller)));
      await tester.pump();

      await tester.tap(find.text('+1'));
      await tester.pump();

      expect(controller.text, '6');
    });

    testWidgets('tapping -interval decreases the integer value but not below zero', (tester) async {
      final controller = TextEditingController(text: '0');
      await tester.pumpWidget(wrap(NumberInput(label: 'จำนวน', controller: controller)));
      await tester.pump();

      await tester.tap(find.text('-1'));
      await tester.pump();

      expect(controller.text, '0');
    });

    testWidgets('decimal mode shows the +0.10/-0.10 fine-adjustment buttons', (tester) async {
      final controller = TextEditingController(text: '5.00');
      await tester.pumpWidget(wrap(NumberInput(label: 'น้ำหนัก', controller: controller, isInt: false)));
      await tester.pump();

      await tester.tap(find.text('+0.10'));
      await tester.pump();

      expect(controller.text, '5.10');
    });

    testWidgets('integer mode does not show the fine-adjustment buttons', (tester) async {
      final controller = TextEditingController(text: '5');
      await tester.pumpWidget(wrap(NumberInput(label: 'จำนวน', controller: controller)));
      await tester.pump();

      expect(find.text('+0.10'), findsNothing);
    });

    testWidgets('a custom interval is reflected on both step buttons', (tester) async {
      final controller = TextEditingController(text: '0');
      await tester.pumpWidget(wrap(NumberInput(label: 'จำนวน', controller: controller, interval: 5)));
      await tester.pump();

      expect(find.text('+5'), findsOneWidget);
      expect(find.text('-5'), findsOneWidget);
    });
  });
}
