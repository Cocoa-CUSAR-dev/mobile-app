// Widget tests for lib/widgets/components/data_record_container.dart.

import 'package:cocoa_supply/widgets/components/data_record_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DataRecordContainer', () {
    testWidgets('shows "ไม่มีข้อมูล" when items is empty', (tester) async {
      await tester.pumpWidget(wrap(DataRecordContainer<String>(
        title: 'แปลง',
        items: const [],
        itemBuilder: (context, item) => Text(item),
      )));

      expect(find.text('ไม่มีข้อมูล'), findsOneWidget);
    });

    testWidgets('shows only 3 items and a อ่านเพิ่มเติม button when there are more than 3', (tester) async {
      await tester.pumpWidget(wrap(DataRecordContainer<String>(
        title: 'แปลง',
        items: const ['A', 'B', 'C', 'D', 'E'],
        itemBuilder: (context, item) => Text(item),
      )));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsNothing);
      expect(find.text('อ่านเพิ่มเติม'), findsOneWidget);
    });

    testWidgets('tapping อ่านเพิ่มเติม expands the list and shows ย่อ instead', (tester) async {
      await tester.pumpWidget(wrap(DataRecordContainer<String>(
        title: 'แปลง',
        items: const ['A', 'B', 'C', 'D', 'E'],
        itemBuilder: (context, item) => Text(item),
      )));

      await tester.tap(find.text('อ่านเพิ่มเติม'));
      await tester.pump();

      expect(find.text('D'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(find.text('ย่อ'), findsOneWidget);
    });

    testWidgets('the edit icon calls onEdit with the tapped item', (tester) async {
      String? edited;
      await tester.pumpWidget(wrap(DataRecordContainer<String>(
        title: 'แปลง',
        items: const ['A'],
        itemBuilder: (context, item) => Text(item),
        onEdit: (item) => edited = item,
      )));

      await tester.tap(find.byIcon(Icons.edit));
      expect(edited, 'A');
    });

    testWidgets('onAddData renders and wires the "ใส่ข้อมูล" footer button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(DataRecordContainer<String>(
        title: 'แปลง',
        items: const [],
        itemBuilder: (context, item) => Text(item),
        onAddData: () => tapped = true,
      )));

      await tester.tap(find.text('ใส่ข้อมูล'));
      expect(tapped, isTrue);
    });
  });
}
