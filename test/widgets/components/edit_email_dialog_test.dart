// Widget tests for lib/widgets/components/edit_email_dialog.dart.

import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/edit_email_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final saved = <String>[];

  Future<void> pump(
    WidgetTester tester, {
    String? email,
    Future<void> Function(String)? onSave,
  }) {
    saved.clear();
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditEmailDialog(
          email: email,
          onSave: onSave ?? (value) async => saved.add(value),
        ),
      ),
    ));
  }

  testWidgets('starts with the current email', (tester) async {
    await pump(tester, email: 'a@test.com');
    expect(find.text('a@test.com'), findsOneWidget);
  });

  testWidgets('a badly formed email is not sent', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('บันทึก'));
    await tester.pump();

    expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);
    expect(saved, isEmpty);
  });

  testWidgets('blank is saved, which removes the email', (tester) async {
    await pump(tester, email: 'a@test.com');
    await tester.enterText(find.byType(TextField), '  ');
    await tester.tap(find.text('บันทึก'));
    await tester.pump();

    expect(saved, ['']);
  });

  testWidgets('shows the hub\'s message when it refuses', (tester) async {
    await pump(
      tester,
      onSave: (_) async => throw ServerRejection(409, 'อีเมลนี้ถูกใช้งานแล้ว'),
    );
    await tester.enterText(find.byType(TextField), 'a@test.com');
    await tester.tap(find.text('บันทึก'));
    await tester.pump();

    expect(find.text('อีเมลนี้ถูกใช้งานแล้ว'), findsOneWidget);
  });
}
