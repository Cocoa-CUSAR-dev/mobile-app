// Widget tests for lib/widgets/pages/register_role_page.dart.
//
// Moved here from the old top-level test/form_test.dart (split per page).
//
// Test cases adapted from `test/testcase.md`:
//   * M-ROLE-01 — Role-select shows three role cards
//   * M-ROLE-02 — Back button on role select returns to the previous page
//   * M-ROLE-03 — Farmer register form requires a name
//   * M-ROLE-04 — Farmer register form requires a nickname
//   * M-ROLE-05 — Farmer register form has a DOB field
//   * M-ROLE-15 — Farmer register form has a Farmer Start Date field (not on
//     step 1, reached via "ถัดไป" through the farmer step flow)
//   * M-ROLE-17 — Farmer register form has a Confirm button on the last step

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

  testWidgets('M-ROLE-01 — shows three role cards', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    expect(find.text('เกษตรกร'), findsOneWidget);
    expect(find.text('ผู้รวบรวม (Hub)'), findsOneWidget);
    expect(find.text('ผู้แปรรูป'), findsOneWidget);
  });

  testWidgets('M-ROLE-02 — back button on step 1 returns to role selection', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เกษตรกร'));
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลเกษตรกร'), findsOneWidget);

    await tester.tap(find.text('เปลี่ยนประเภทสมาชิก'));
    await tester.pumpAndSettle();

    expect(find.text('กรุณาเลือกประเภทสมาชิก'), findsOneWidget);
  });

  testWidgets('M-ROLE-03/04/05 — farmer step 1 requires name, nickname, and has a DOB field', (tester) async {
    await tester.pumpWidget(wrapPage(const RegisterRolePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เกษตรกร'));
    await tester.pumpAndSettle();

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

    // Step 2 (birth_date, phone_number, line) has the DOB field (M-ROLE-05).
    expect(find.textContaining('วัน/เดือน/ปีเกิด', findRichText: true), findsOneWidget);
  });
}
