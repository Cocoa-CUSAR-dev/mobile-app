// Widget tests for lib/widgets/components/autofill_offer_sheet.dart (US2-5).
//
// The sheet is the farmer's whole decision: what last time's answers were,
// and a yes/no. These pin the wording (it must match the chatbot's) and the
// rule that anything other than "ใช้ข้อมูลเดิม" -- including just dismissing
// it -- means a blank form.

import 'package:cocoa_supply/bloc/dynamic/autofill_offer.dart';
import 'package:cocoa_supply/widgets/components/autofill_offer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _offer = AutofillOffer(
  submittedAt: DateTime(2026, 9, 30, 15, 12),
  answer: const {'plot_id': 'plot-a', 'description': 'ฉีดพ่นรอบโคน'},
  preview: const [
    AutofillPreviewLine('แปลงที่ดำเนินการ', 'แปลง A'),
    AutofillPreviewLine('รายละเอียด', 'ฉีดพ่นรอบโคน'),
  ],
);

/// Hosts a button that opens the sheet and records what it resolved to.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool? result;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () async {
          final accepted = await AutofillOfferSheet.show(context, _offer);
          setState(() => result = accepted);
        },
        child: Text('open: $result'),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: _Host()));
  await tester.tap(find.text('open: null'));
  await tester.pumpAndSettle();
}

void main() {
  group('AutofillOfferSheet', () {
    testWidgets('shows the question, the date and last time\'s answers by name', (tester) async {
      await _open(tester);

      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsOneWidget);
      expect(find.text('บันทึกเมื่อ 30 ก.ย. 2569'), findsOneWidget);
      expect(find.text('แปลงที่ดำเนินการ: แปลง A'), findsOneWidget);
      expect(find.text('รายละเอียด: ฉีดพ่นรอบโคน'), findsOneWidget);
      // The chatbot's own button wording.
      expect(find.text('ใช้ข้อมูลเดิม'), findsOneWidget);
      expect(find.text('เริ่มใหม่'), findsOneWidget);
    });

    testWidgets('"ใช้ข้อมูลเดิม" resolves to true', (tester) async {
      await _open(tester);

      await tester.tap(find.text('ใช้ข้อมูลเดิม'));
      await tester.pumpAndSettle();

      expect(find.text('open: true'), findsOneWidget);
    });

    testWidgets('"เริ่มใหม่" resolves to false', (tester) async {
      await _open(tester);

      await tester.tap(find.text('เริ่มใหม่'));
      await tester.pumpAndSettle();

      expect(find.text('open: false'), findsOneWidget);
    });

    testWidgets('dismissing it (tap outside) also counts as เริ่มใหม่', (tester) async {
      await _open(tester);

      await tester.tapAt(const Offset(10, 10)); // the barrier above the sheet
      await tester.pumpAndSettle();

      expect(find.text('open: false'), findsOneWidget);
    });

    testWidgets('no date line when the server sent none', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AutofillOfferSheet(
            offer: AutofillOffer(submittedAt: null, answer: const {'a': 'b'}, preview: const [
              AutofillPreviewLine('ข้อ', 'ค่า'),
            ]),
          ),
        ),
      ));

      expect(find.textContaining('บันทึกเมื่อ'), findsNothing);
      expect(find.text('ข้อ: ค่า'), findsOneWidget);
    });
  });
}
