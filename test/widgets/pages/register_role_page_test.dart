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
// Redesign (docs-and-plan#320):
//   * pages: about you, address, the roles' own page, then a review page
//   * the phone number from sign-up is already filled in
//   * the review page's "แก้ไข" goes back to that page

import 'package:cocoa_supply/widgets/pages/register_role_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/testing.dart';

import '../../services/test_helpers.dart';
import 'page_test_helpers.dart';

/// Answers the address dropdowns with one province, district and subdistrict.
MockClient _placesClient() => MockClient((request) async {
      final key = request.url.pathSegments.last;
      return jsonResponse(switch (key) {
        'province' => [{'province_id': 'p1', 'province_name_th': 'ชุมพร'}],
        'district' => [{'district_id': 'd1', 'district_name_th': 'เมือง'}],
        'subdistrict' => [{'subdistrict_id': 's1', 'subdistrict_name_th': 'ท่ายาง'}],
        'location' => [{'subdistrict_id': 's1', 'zip_code': '86000'}],
        _ => [],
      }, 200);
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pickAndContinue(WidgetTester tester, List<String> roleTitles) async {
    for (final title in roleTitles) {
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('ถัดไป'));
    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.ensureVisible(find.text('ถัดไป'));
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

  testWidgets('M-ROLE-03/04/05 — the first page asks name, nickname and date of birth, all required', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage(
      prefill: {'birth_date': '1972-03-12', 'phone_number': '0812345678'},
    )));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['เกษตรกร']);

    expect(find.textContaining('ชื่อจริง', findRichText: true), findsOneWidget);
    expect(find.textContaining('นามสกุล', findRichText: true), findsOneWidget);
    expect(find.textContaining('ชื่อเล่น', findRichText: true), findsOneWidget);
    expect(find.textContaining('วัน/เดือน/ปีเกิด', findRichText: true), findsOneWidget);

    // "ถัดไป" is disabled until first/last name and nickname are filled.
    ElevatedButton next() => tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(next().onPressed, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'สมชาย');
    await tester.enterText(fields.at(1), 'โกโก้ดี');
    await tester.enterText(fields.at(2), 'สม');
    await tester.pump();

    expect(next().onPressed, isNotNull);

    await tester.ensureVisible(find.text('ถัดไป'));
    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();

    expect(find.text('ที่อยู่'), findsOneWidget);
  });

  testWidgets('the phone number from sign-up is already filled in', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage(prefill: {'phone_number': '0812345678'})));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['เกษตรกร']);

    expect(find.text('0812345678'), findsOneWidget);
  });

  testWidgets('review shows every answer once, and "แก้ไข" goes back to that page', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrapPage(
      const RegisterRolePage(prefill: {
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
        'nickname': 'สม',
        'birth_date': '1972-03-12',
        'phone_number': '0812345678',
        'province_id': 'p1',
        'district_id': 'd1',
        'subdistrict_id': 's1',
      }),
      client: _placesClient(),
    ));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['ผู้รวบรวม (Hub)']);
    await tapNext(tester); // about you
    await tapNext(tester); // address

    // The hub collector's own page: the ID card, tagged with the role.
    expect(find.text('บัตรประชาชน'), findsOneWidget);
    expect(find.text('ผู้รวบรวม'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '1234567890123');
    await tester.pump();
    await tapNext(tester);

    expect(find.text('ตรวจสอบข้อมูล'), findsOneWidget);
    expect(find.text('หน้า 4 จาก 4'), findsOneWidget);
    expect(find.text('สมชาย โกโก้ดี (สม)'), findsOneWidget);
    expect(find.textContaining('0812345678'), findsOneWidget);
    expect(find.text('เกิด 12 มี.ค. 2515'), findsOneWidget);
    expect(find.text('ต.ท่ายาง อ.เมือง จ.ชุมพร'), findsOneWidget);
    expect(find.text('เลขบัตรประชาชน 1234567890123'), findsOneWidget);
    expect(find.text('ยืนยันการสมัคร'), findsOneWidget);

    // "แก้ไข" on the address card: back on the address page.
    await tester.tap(find.text('แก้ไข').at(2));
    await tester.pumpAndSettle();
    expect(find.text('ที่อยู่'), findsOneWidget);
    expect(find.text('ตรวจสอบข้อมูล'), findsNothing);
  });

  testWidgets('two roles picked: one form, the farmer pages only once', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    await pickAndContinue(tester, ['เกษตรกร', 'ผู้แปรรูป']);

    // About you, address, the roles' own page, review.
    expect(find.text('หน้า 1 จาก 4'), findsOneWidget);
    expect(find.text('ถามครั้งเดียว ใช้กับทุกบทบาทที่เลือก'), findsOneWidget);
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
      prefill: {
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
        'nickname': 'สม',
        'birth_date': '1972-03-12',
        'phone_number': '0812345678',
      },
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
    // About you, address, the ID card page; no review page when editing.
    expect(find.text('หน้า 1 จาก 3'), findsOneWidget);
  });
}
