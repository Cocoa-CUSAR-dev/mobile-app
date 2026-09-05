// Widget tests for lib/widgets/pages/processing_station_register_page.dart.
//
// Same one-field-per-step pattern as plot_register_page.dart (13 steps),
// except invalid submission here just silently stays on the step (no
// SnackBar), unlike PlotRegisterPage's "กรุณากรอกข้อมูลให้ครบถ้วน" toast.

import 'package:cocoa_supply/widgets/pages/processing_station_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('M-STAT-02 — step 1 shows the required station-name field', (tester) async {
    await tester.pumpWidget(wrapPage(const ProcessingStationRegisterPage()));
    await tester.pumpAndSettle();

    expect(find.text('ขั้นตอนที่ 1 จาก 13'), findsOneWidget);
    expect(find.text('ชื่อสถานีแปรรูป *', findRichText: true), findsOneWidget);
  });

  testWidgets('leaving the required field empty keeps the page on step 1', (tester) async {
    await tester.pumpWidget(wrapPage(const ProcessingStationRegisterPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ต่อไป'));
    await tester.pump();

    expect(find.text('ขั้นตอนที่ 1 จาก 13'), findsOneWidget);
  });

  testWidgets('filling the required field and tapping ต่อไป advances to step 2', (tester) async {
    await tester.pumpWidget(wrapPage(const ProcessingStationRegisterPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'ศูนย์แปรรูปแม่จัน');
    await tester.tap(find.text('ต่อไป'));
    await tester.pumpAndSettle();

    expect(find.text('ขั้นตอนที่ 2 จาก 13'), findsOneWidget);
  });

  testWidgets('M-STAT-17 — back button (ยกเลิก) on step 1 pops the page', (tester) async {
    await tester.pumpWidget(wrapPage(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProcessingStationRegisterPage()),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.text('ขั้นตอนที่ 1 จาก 13'), findsNothing);
  });
}
