// Basic Flutter widget tests for the Cacao Farmer App.
//
// These tests verify that the root MyApp widget renders the
// LoginPage correctly when launched. They are adapted from the
// smoke test that ships with `flutter create` and from the
// testcases documented in `test/tesrtcase.md`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cocoa_supply/main.dart';

void main() {
  testWidgets('MyApp renders without crashing', (WidgetTester tester) async {
    // Build the root app and trigger an initial frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // The root MaterialApp must be present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('MyApp shows the welcome text on the login page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // The login page displays a welcome banner (W-AUTH-01 smoke check).
    expect(find.text('ยินดีต้อนรับเข้าสู่แอปพลิเคชัน'), findsOneWidget);
  });

  testWidgets('Login selection area shows primary and secondary actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // M-LOG-03 / W-AUTH-02: account selection must be visible.
    expect(find.text('ท่านมีบัญชีผู้ใช้อยู่แล้วหรือไม่'), findsOneWidget);
    expect(find.text('มีบัญชีผู้ใช้แล้ว'), findsOneWidget);
    expect(find.text('ยังไม่มีบัญชีผู้ใช้'), findsOneWidget);
  });
}