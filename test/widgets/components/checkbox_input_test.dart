// Widget tests for lib/widgets/components/checkbox_input.dart.
//
// Covers the Yes/No toggle pattern reused across M-PLOT-07 (chemical use),
// M-FORM-19 (quality loss), M-FORM-28 (ventilation system), etc.

import 'package:cocoa_supply/widgets/components/checkbox_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CheckboxInput', () {
    testWidgets('starts with neither option selected when initialValue is null', (tester) async {
      await tester.pumpWidget(wrap(const CheckboxInput(label: 'มีการใช้สารเคมีหรือไม่')));

      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    });

    testWidgets('tapping ใช่ selects it and calls onChanged(true)', (tester) async {
      bool? changedTo;
      await tester.pumpWidget(wrap(CheckboxInput(
        label: 'มีการใช้สารเคมีหรือไม่',
        onChanged: (v) => changedTo = v,
      )));

      await tester.tap(find.text('ใช่'));
      await tester.pump();

      expect(changedTo, isTrue);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('tapping ไม่ใช่ selects it and calls onChanged(false)', (tester) async {
      bool? changedTo;
      await tester.pumpWidget(wrap(CheckboxInput(
        label: 'มีการใช้สารเคมีหรือไม่',
        initialValue: true,
        onChanged: (v) => changedTo = v,
      )));

      await tester.tap(find.text('ไม่ใช่'));
      await tester.pump();

      expect(changedTo, isFalse);
    });

    testWidgets('isRequired renders a red asterisk after the label', (tester) async {
      await tester.pumpWidget(wrap(const CheckboxInput(label: 'มีการใช้สารเคมีหรือไม่', isRequired: true)));

      final labelRichText = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && (w.text as TextSpan).text == 'มีการใช้สารเคมีหรือไม่',
        ),
      );
      final span = labelRichText.text as TextSpan;
      expect(span.children!.first, isA<TextSpan>().having((s) => s.text, 'text', ' *'));
    });
  });
}
