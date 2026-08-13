// Widget tests for lib/widgets/pages/plot_register_page.dart.
//
// Unlike Farm/Hub's grouped steps, PlotRegisterPage shows exactly one
// field per step (11 steps total) and the "ต่อไป" button is never
// disabled — instead tapping it runs Form.validate() and shows a red
// SnackBar on failure, staying on the same step (M-PLOT-04).

import 'package:cocoa_supply/widgets/pages/plot_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('M-PLOT-01 — step 1 shows the required plot-name field', (tester) async {
    await tester.pumpWidget(wrapPage(const PlotRegisterPage(farmId: 'farm-1')));
    await tester.pumpAndSettle();

    expect(find.text('หน้า 1 จาก 11'), findsOneWidget);
    expect(find.text('ชื่อแปลง *', findRichText: true), findsOneWidget);
  });

  testWidgets('M-PLOT-03 — leaving the required field empty shows a validation SnackBar and stays on step 1', (tester) async {
    await tester.pumpWidget(wrapPage(const PlotRegisterPage(farmId: 'farm-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ต่อไป'));
    await tester.pump();

    expect(find.text('กรุณากรอกข้อมูลให้ครบถ้วน'), findsOneWidget);
    expect(find.text('หน้า 1 จาก 11'), findsOneWidget);
  });

  testWidgets('M-PLOT-20 — back button (ยกเลิก) on step 1 pops the page', (tester) async {
    await tester.pumpWidget(wrapPage(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PlotRegisterPage(farmId: 'farm-1')),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.text('หน้า 1 จาก 11'), findsNothing);
  });

  testWidgets('M-PLOT-21 — filling the field and tapping ต่อไป advances to step 2', (tester) async {
    await tester.pumpWidget(wrapPage(const PlotRegisterPage(farmId: 'farm-1')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'แปลง 1');
    await tester.tap(find.text('ต่อไป'));
    await tester.pumpAndSettle();

    expect(find.text('หน้า 2 จาก 11'), findsOneWidget);
  });
}
