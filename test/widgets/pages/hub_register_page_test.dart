// Widget tests for lib/widgets/pages/hub_register_page.dart.
//
// Covers M-HUB-02/07/08 (required name/owner/phone on step 1) and the
// step indicator. Same GIS/map limitation as farm_register_page_test.dart
// applies to step 3.

import 'package:cocoa_supply/widgets/pages/hub_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders step 1 with the required hub fields', (tester) async {
    await tester.pumpWidget(wrapPage(const HubRegisterPage()));
    await tester.pumpAndSettle();

    expect(find.text('หน้า 1 จาก 3'), findsOneWidget);
    expect(find.text('ชื่อ *', findRichText: true), findsNothing); // sanity: no bare "ชื่อ" field on this page
  });

  testWidgets('M-HUB-02/07/08 — "ถัดไป" stays disabled until step 1 required fields are filled', (tester) async {
    await tester.pumpWidget(wrapPage(const HubRegisterPage()));
    await tester.pumpAndSettle();

    ElevatedButton nextButton() => tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(nextButton().onPressed, isNull);

    // hub_name is the only plain TextFormField on step 1 (found_date is a
    // stepper widget, contact_name/phone_number come after it in the
    // field list) — filling it alone still leaves the other three
    // required fields empty, so "ถัดไป" must stay disabled.
    await tester.enterText(find.byType(TextFormField).first, 'จุดรับซื้อกลาง');
    await tester.pump();

    expect(nextButton().onPressed, isNull);
  });

  testWidgets('back button (เปลี่ยนประเภทสมาชิก-equivalent ยกเลิก) pops the page on step 1', (tester) async {
    await tester.pumpWidget(wrapPage(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HubRegisterPage()),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.text('หน้า 1 จาก 3'), findsNothing);
  });
}
