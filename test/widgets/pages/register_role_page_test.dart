// Widget tests for lib/widgets/pages/register_role_page.dart.
//
// Moved here from the old top-level test/form_test.dart (split per page).
//
// Test cases adapted from `test/testcase.md`:
//   * M-ROLE-01 — Role-select shows three role cards
//   * M-ROLE-02 — Back button on step 1 returns to role selection
//   * M-ROLE-03 — Register form requires a name
//   * M-ROLE-04 — Register form requires a nickname
//   * M-ROLE-05 — Register form has a DOB field
// Multi-role (one person, several roles at once; adding one later):
//   * several roles can be picked; the form asks the shared fields once
//   * roles already held are shown as "มีแล้ว" and can't be picked
//   * the form starts with the answers it was given (prefill)
// Editing a role's profile (editRole):
//   * opens straight on the form, filled, with "ยกเลิก" instead of role picking

import 'package:cocoa_supply/widgets/pages/register_role_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pickAndContinue(WidgetTester tester, List<String> roleTitles) async {
    for (final title in roleTitles) {
      await tester.tap(find.text(title));
      await tester.pump();
    }
    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();
  }

  testWidgets('M-ROLE-01 — shows three role cards', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    expect(find.text('เกษตรกร'), findsOneWidget);
    expect(find.text('ผู้รวบรวม (Hub)'), findsOneWidget);
    expect(find.text('ผู้แปรรูป'), findsOneWidget);
  });

  testWidgets('"ถัดไป" stays disabled until a role is picked', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    ElevatedButton next() => tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(next().onPressed, isNull);

    await tester.tap(find.text('เกษตรกร'));
    await tester.pump();
    expect(next().onPressed, isNotNull);

    // Tapping again un-picks it.
    await tester.tap(find.text('เกษตรกร'));
    await tester.pump();
    expect(next().onPressed, isNull);
  });

  testWidgets('M-ROLE-02 — back button on step 1 returns to role selection', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['เกษตรกร']);
    expect(find.text('ข้อมูลส่วนตัว'), findsOneWidget);

    await tester.tap(find.text('เลือกบทบาทใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('คุณทำอะไรบ้าง? เลือกได้มากกว่า 1 บทบาท'), findsOneWidget);
  });

  testWidgets('M-ROLE-03/04/05 — step 1 requires name, nickname, and step 2 has a DOB field', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['เกษตรกร']);

    expect(find.textContaining('ชื่อจริง', findRichText: true), findsOneWidget);
    expect(find.textContaining('นามสกุล', findRichText: true), findsOneWidget);
    expect(find.textContaining('ชื่อเล่น', findRichText: true), findsOneWidget);

    // "ถัดไป" is disabled until first/last name and nickname are filled.
    final nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(nextButton.onPressed, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'สมชาย');
    await tester.enterText(fields.at(1), 'โกโก้ดี');
    await tester.enterText(fields.at(2), 'สม');
    await tester.pump();

    final enabledNextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(enabledNextButton.onPressed, isNotNull);

    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();

    expect(find.textContaining('วัน/เดือน/ปีเกิด', findRichText: true), findsOneWidget);
  });

  testWidgets('two roles picked: one form, the farmer pages only once', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['เกษตรกร', 'ผู้แปรรูป']);

    // 4 shared pages + 2 farmer pages.
    expect(find.text('หน้า 1 จาก 6'), findsOneWidget);
  });

  testWidgets('a role already held shows "มีแล้ว" and cannot be picked', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage(ownedRoles: {'farmer'})));
    await tester.pumpAndSettle();

    expect(find.text('เพิ่มบทบาท'), findsOneWidget);
    expect(find.text('มีแล้ว'), findsOneWidget);

    await tester.tap(find.text('เกษตรกร'));
    await tester.pump();
    final next = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(next.onPressed, isNull);
  });

  testWidgets('adding a role starts with the answers it was given', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage(
      ownedRoles: {'farmer'},
      prefill: {'first_name': 'สมชาย', 'last_name': 'โกโก้ดี', 'nickname': 'สม'},
    )));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['ผู้แปรรูป']);

    expect(find.text('สมชาย'), findsOneWidget);
    final next = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(next.onPressed, isNotNull);
  });

  testWidgets('editing a role opens straight on its filled form', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage(
      editRole: 'hub_collector',
      ownedRoles: {'hub_collector', 'farmer'},
      prefill: {'first_name': 'สมชาย', 'last_name': 'โกโก้ดี', 'nickname': 'สม'},
    )));
    await tester.pumpAndSettle();

    expect(find.text('คุณทำอะไรบ้าง? เลือกได้มากกว่า 1 บทบาท'), findsNothing);
    expect(find.text('แก้ไขข้อมูลผู้รวบรวม'), findsOneWidget);
    expect(find.text('สมชาย'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsOneWidget);
    // Hub collector has no farmer pages: 4 shared pages only.
    expect(find.text('หน้า 1 จาก 4'), findsOneWidget);
  });
}
