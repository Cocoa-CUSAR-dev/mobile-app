// Widget tests for lib/widgets/components/tree_dot_loading.dart.
//
// The whole "grind and brew" scene is one CustomPaint(painter:
// BrewingBeanPainter(...)) that redraws every animation tick -- there's
// no separate widget per bean/cup to count, so these tests check the
// painter's constructor args instead of counting child widgets.

import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThreeDotsLoading', () {
    testWidgets('renders a BrewingBeanPainter that advances over time', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ThreeDotsLoading()));
      await tester.pump(const Duration(milliseconds: 100));

      final painters = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is BrewingBeanPainter,
      );
      expect(painters, findsOneWidget);

      final first = (tester.widget<CustomPaint>(painters).painter) as BrewingBeanPainter;
      await tester.pump(const Duration(milliseconds: 300));
      final second = (tester.widget<CustomPaint>(painters).painter) as BrewingBeanPainter;
      expect(second.t, isNot(first.t));

      // Stop the repeating animation before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('uses the provided color and scales with size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ThreeDotsLoading(color: Colors.red, size: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final painters = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is BrewingBeanPainter,
      );
      final painter = (tester.widget<CustomPaint>(painters).painter) as BrewingBeanPainter;
      expect(painter.color, Colors.red);

      // size: 20 is double the default (10), so the SizedBox should be
      // double the default's footprint.
      final box = tester.widget<SizedBox>(
        find.ancestor(of: painters, matching: find.byType(SizedBox)).first,
      );
      expect(box.width, 64 * 2.0);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
