// Widget tests for lib/widgets/pages/user_register_page.dart.
//
// Moved here from the old top-level test/auth_test.dart and
// test/form_test.dart (split per page to mirror lib/widgets/pages/*.dart).
//
// Test cases adapted from `test/testcase.md`:
//   * M-REG-02 — phone number field rejects invalid input, accepts valid
//   * M-REG-03 — password field rejects inputs shorter than 8 chars
//   * M-PROF-01 — required fields validated on empty submission

import 'package:cocoa_supply/widgets/pages/user_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the registration header and confirm button', (tester) async {
    await tester.pumpWidget(wrapPage(const UserRegisterPage()));
    await tester.pumpAndSettle();

    expect(find.text('ลงทะเบียนผู้ใช้งานใหม่'), findsOneWidget);
    expect(find.text('ยืนยันการลงทะเบียน'), findsOneWidget);
  });

  testWidgets('M-PROF-01 — submitting an empty form triggers validation', (tester) async {
    await tester.pumpWidget(wrapPage(const UserRegisterPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pump();

    expect(find.textContaining('กรุณาระบุ'), findsWidgets);
  });

  testWidgets('M-REG-02 — phone-number validator rejects non-numeric input', (tester) async {
    await tester.pumpWidget(wrapPage(const UserRegisterPage()));
    await tester.pumpAndSettle();

    final phoneField = find.byType(TextFormField).first;
    await tester.enterText(phoneField, 'abc');
    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pump();

    expect(find.textContaining('เบอร์โทรต้องเป็นตัวเลข 10 หลัก'), findsOneWidget);
  });

  testWidgets('M-REG-02 — a valid 10-digit phone passes phone validation', (tester) async {
    await tester.pumpWidget(wrapPage(const UserRegisterPage()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0812345678');
    await tester.enterText(fields.at(1), 'cocoa1234');
    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pump();

    expect(find.textContaining('เบอร์โทรต้องเป็นตัวเลข 10 หลัก'), findsNothing);
  });

  testWidgets('M-REG-03 — password shorter than 8 chars is rejected', (tester) async {
    await tester.pumpWidget(wrapPage(const UserRegisterPage()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'short');
    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pump();

    expect(find.textContaining('รหัสผ่านต้องมี 8 ตัวขึ้นไป'), findsOneWidget);
  });
}
