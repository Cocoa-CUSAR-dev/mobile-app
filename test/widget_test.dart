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

  testWidgets('the app opens on the login form, with sign-up one tap away',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // M-LOG-03 / W-AUTH-02: the login form, then a link to sign up
    // (docs-and-plan#320 dropped the "do you have an account" step).
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(find.text('ลงชื่อเข้าใช้งาน'), findsOneWidget);
    expect(find.text('สมัครใช้งาน'), findsOneWidget);
  });
}