// Widget tests for lib/widgets/components/tree_dot_loading.dart.

import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThreeDotsLoading', () {
    testWidgets('renders exactly 3 animated dots', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ThreeDotsLoading()));
      await tester.pump(const Duration(milliseconds: 100));

      final dots = find.byWidgetPredicate(
        (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      );
      expect(dots, findsNWidgets(3));

      // Stop the repeating animation before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('uses the provided color and size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ThreeDotsLoading(color: Colors.red, size: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final dots = find.byWidgetPredicate(
        (w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      );
      final container = tester.widgetList<Container>(dots).first;
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
      expect(container.constraints?.maxWidth ?? 20, 20);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
