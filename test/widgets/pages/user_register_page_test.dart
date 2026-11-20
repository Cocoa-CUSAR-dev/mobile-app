// Widget tests for lib/widgets/pages/user_register_page.dart.
//
// Moved here from the old top-level test/auth_test.dart and
// test/form_test.dart (split per page to mirror lib/widgets/pages/*.dart).
//
// Test cases adapted from `test/testcase.md`:
//   * M-REG-02 — phone number field rejects invalid input, accepts valid
//   * M-REG-03 — password field rejects inputs shorter than 6 chars
//   * M-PROF-01 — required fields validated on empty submission
// Redesign (docs-and-plan#320):
//   * the password is typed twice, and the two must match
//   * the password rules turn green while typing

import 'package:cocoa_supply/widgets/pages/user_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

const String _submit = 'ถัดไป: เลือกบทบาท';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrapPage(const UserRegisterPage()));
    await tester.pumpAndSettle();
  }

  Finder field(int i) => find.byType(TextFormField).at(i);

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text(_submit));
    await tester.tap(find.text(_submit));
    await tester.pump();
  }

  testWidgets('renders the sign-up header, the next button and a way back to login', (tester) async {
    await pumpPage(tester);

    expect(find.text('สร้างบัญชี'), findsOneWidget);
    expect(find.text(_submit), findsOneWidget);
    expect(find.text('มีบัญชีแล้ว?'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('asks for phone, password twice and an optional email (profiles come next)', (tester) async {
    await pumpPage(tester);

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.textContaining('ยืนยันรหัสผ่าน', findRichText: true), findsOneWidget);
    expect(find.textContaining('อีเมล (ไม่บังคับ)', findRichText: true), findsOneWidget);
  });

  testWidgets('a badly formed email is refused; a blank one is not', (tester) async {
    await pumpPage(tester);

    await tester.enterText(field(3), 'not-an-email');
    await submit(tester);
    expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);

    await tester.enterText(field(3), '');
    await submit(tester);
    expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsNothing);
  });

  testWidgets('M-PROF-01 — submitting an empty form triggers validation', (tester) async {
    await pumpPage(tester);

    await submit(tester);

    expect(find.textContaining('กรุณาระบุ'), findsWidgets);
    expect(find.text('กรุณากรอกรหัสผ่านอีกครั้ง'), findsOneWidget);
  });

  testWidgets('M-REG-02 — phone-number validator rejects non-numeric input', (tester) async {
    await pumpPage(tester);

    await tester.enterText(field(0), 'abc');
    await submit(tester);

    expect(find.textContaining('เบอร์โทรต้องเป็นตัวเลข 10 หลัก'), findsOneWidget);
  });

  testWidgets('M-REG-02 — a valid 10-digit phone passes phone validation', (tester) async {
    await pumpPage(tester);

    await tester.enterText(field(0), '0812345678');
    await tester.enterText(field(1), 'cocoa1');
    await submit(tester);

    expect(find.textContaining('เบอร์โทรต้องเป็นตัวเลข 10 หลัก'), findsNothing);
  });

  testWidgets('M-REG-03 — a password shorter than 6 is refused; 6 is enough', (tester) async {
    await pumpPage(tester);

    await tester.enterText(field(1), 'short');
    await submit(tester);
    expect(find.text('รหัสผ่านต้องมี 6 ตัวขึ้นไป'), findsOneWidget);

    await tester.enterText(field(1), 'cocoa1');
    await submit(tester);
    expect(find.text('รหัสผ่านต้องมี 6 ตัวขึ้นไป'), findsNothing);
  });

  testWidgets('the two passwords must match, and say so while typing', (tester) async {
    await pumpPage(tester);

    await tester.enterText(field(1), 'cocoa1');
    await tester.enterText(field(2), 'cocoa2');
    await tester.pump();
    // Under the confirm field while typing, and again from the validator.
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    await submit(tester);
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsNWidgets(2));

    // Fixed: the green line, and the earlier message is gone too.
    await tester.enterText(field(2), 'cocoa1');
    await tester.pump();
    expect(find.text('รหัสผ่านตรงกัน'), findsOneWidget);
    expect(find.text('รหัสผ่านไม่ตรงกัน'), findsNothing);
  });

  testWidgets('the length rule turns green once the password is long enough', (tester) async {
    await pumpPage(tester);

    final rule = find.widgetWithText(Row, 'อย่างน้อย 6 ตัว');
    expect(find.descendant(of: rule, matching: find.byIcon(Icons.radio_button_unchecked)), findsOneWidget);

    await tester.enterText(field(1), 'cocoa1');
    await tester.pump();
    expect(find.descendant(of: rule, matching: find.byIcon(Icons.check_circle)), findsOneWidget);
  });
}
