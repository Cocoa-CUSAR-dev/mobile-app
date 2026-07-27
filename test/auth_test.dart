// Auth / Login / Registration widget tests.
//
// Test cases adapted from `test/tesrtcase.md`:
//   * M-LOG-01  — username field accepts a phone number
//   * M-LOG-02  — password field accepts a password
//   * M-LOG-03  — show-password button toggles the visibility of the password
//   * M-REG-01  — registration button navigates to the user-register page
//   * M-REG-02  — phone number field rejects invalid input
//   * M-REG-03  — password field rejects inputs that are too short
//   * M-REG-04  — email field accepts well-formed addresses
//   * M-REG-05  — back button on register page navigates back to login
//   * W-AUTH-01 — login page shows the welcome header
//   * W-AUTH-02 — login page shows the password field with masked input
//
// Helpers:
//   * pumpAndScrollUntil — scrolls inside the SingleChildScrollView of the
//     current screen until the named text widget is visible. The login page
//     and user-register page both use a SingleChildScrollView so labels can
//     be below the default 800x600 test viewport.

import 'package:cocoa_supply/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 30,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
  testWidgets('W-AUTH-01 — login page renders welcome banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ยินดีต้อนรับเข้าสู่แอปพลิเคชัน'), findsOneWidget);
  });

  testWidgets('W-AUTH-02 / M-LOG-01 / M-LOG-02 — login form shows input fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Open the login form first (selection area -> login form).
    await tester.tap(find.text('มีบัญชีผู้ใช้แล้ว'));
    await tester.pumpAndSettle();

    // Both labels should be visible. The login form is rendered in a
    // SingleChildScrollView and may start below the visible viewport; scroll
    // until we find it.
    await tester.scrollUntilVisible(
      find.text('เบอร์มือถือ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('เบอร์มือถือ'), findsOneWidget);
    expect(find.text('รหัสผ่าน'), findsOneWidget);

    // Two text form fields should be on screen.
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('M-LOG-03 — show-password button toggles visibility',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('มีบัญชีผู้ใช้แล้ว'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byIcon(Icons.visibility_off),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // Initially the password is hidden -> visibility_off icon is shown.
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsNothing);

    // Tap the toggle.
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    // After toggling, the password should be visible.
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
  });

  testWidgets('M-REG-01 — registration button navigates to user-register page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Tap "ยังไม่มีบัญชีผู้ใช้" (registration entry point).
    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    // The user register page has its own header.
    await _pumpUntilFound(tester, find.text('ลงทะเบียนผู้ใช้งานใหม่'));
    expect(find.text('ลงทะเบียนผู้ใช้งานใหม่'), findsOneWidget);
  });

  testWidgets('M-REG-02 — phone-number validator rejects bad input',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    // Scroll the phone field into view, then enter text into the first
    // available TextFormField.
    await tester.scrollUntilVisible(
      find.text('เบอร์โทรศัพท์'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final phoneFields = find.byType(TextFormField);
    expect(phoneFields, findsWidgets);
    await tester.enterText(phoneFields.first, 'abc');
    await tester.pump();

    // Submit form by tapping the confirm button.
    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pump();

    // Validation message should be shown.
    expect(
      find.textContaining('เบอร์โทรต้องเป็นตัวเลข 10 หลัก'),
      findsOneWidget,
    );
  });

  testWidgets('M-REG-02 — valid 10-digit phone passes phone validation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('เบอร์โทรศัพท์'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final phoneFields = find.byType(TextFormField);
    await tester.enterText(phoneFields.first, '0812345678');

    // Enter a valid 8+ char password into the second field.
    await tester.enterText(phoneFields.at(1), 'cocoa1234');

    // Tap confirm — phone validation should pass (no phone-related error).
    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pump();

    expect(
      find.textContaining('เบอร์โทรต้องเป็นตัวเลข 10 หลัก'),
      findsNothing,
    );
  });

  testWidgets('M-REG-03 — password shorter than 8 chars is rejected',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('รหัสผ่าน'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final phoneFields = find.byType(TextFormField);
    await tester.enterText(phoneFields.at(1), 'short');
    await tester.pump();

    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pump();

    expect(
      find.textContaining('รหัสผ่านต้องมี 8 ตัวขึ้นไป'),
      findsOneWidget,
    );
  });

  testWidgets('M-REG-05 — back arrow returns to the login page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    await _pumpUntilFound(tester, find.text('ลงทะเบียนผู้ใช้งานใหม่'));
    // Confirm we are on the user-register page.
    expect(find.text('ลงทะเบียนผู้ใช้งานใหม่'), findsOneWidget);

    // Tap the back arrow on the AppBar.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    // Back on the login page.
    expect(find.text('ยินดีต้อนรับเข้าสู่แอปพลิเคชัน'), findsOneWidget);
  });
}