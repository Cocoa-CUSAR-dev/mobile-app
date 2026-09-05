// Widget tests for lib/widgets/components/form_modal.dart.

import 'package:cocoa_supply/widgets/components/form_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpModal(
    WidgetTester tester, {
    VoidCallback? onSave,
    VoidCallback? onCancel,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => FormModal(
                title: 'แก้ไขข้อมูล',
                formBody: const Text('form body'),
                onSave: onSave,
                onCancel: onCancel,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('FormModal', () {
    testWidgets('shows the title and form body', (tester) async {
      await pumpModal(tester);

      expect(find.text('แก้ไขข้อมูล'), findsOneWidget);
      expect(find.text('form body'), findsOneWidget);
      expect(find.text('บันทึกข้อมูล'), findsOneWidget);
    });

    testWidgets('tapping save invokes onSave', (tester) async {
      var saved = false;
      await pumpModal(tester, onSave: () => saved = true);

      await tester.tap(find.text('บันทึกข้อมูล'));
      expect(saved, isTrue);
    });

    testWidgets('tapping cancel closes the dialog when no onCancel is provided', (tester) async {
      await pumpModal(tester);

      await tester.tap(find.text('ย้อนกลับ'));
      await tester.pumpAndSettle();

      expect(find.text('แก้ไขข้อมูล'), findsNothing);
    });

    testWidgets('a custom onCancel overrides the default pop behavior', (tester) async {
      var cancelled = false;
      await pumpModal(tester, onCancel: () => cancelled = true);

      await tester.tap(find.text('ย้อนกลับ'));
      await tester.pump();

      expect(cancelled, isTrue);
      // Dialog stays open since the custom callback didn't pop it.
      expect(find.text('แก้ไขข้อมูล'), findsOneWidget);
    });
  });
}
