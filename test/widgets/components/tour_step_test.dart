// The guided tour's base (docs-and-plan#311): TourStep's Thai tooltip with
// ถัดไป / ย้อนกลับ / ข้าม, and TourController carrying the tour across pages.

import 'package:cocoa_supply/services/tour_controller.dart';
import 'package:cocoa_supply/services/tour_service.dart';
import 'package:cocoa_supply/widgets/components/tour_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Page extends StatelessWidget {
  const _Page(this.first, this.second);

  final GlobalKey first;
  final GlobalKey second;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TourStep(
            stepKey: first,
            title: 'ขั้นแรก',
            description: 'คำอธิบายขั้นแรก',
            isFirst: true,
            child: const Text('ปุ่มแรก'),
          ),
          TourStep(
            stepKey: second,
            title: 'ขั้นที่สอง',
            description: 'คำอธิบายขั้นที่สอง',
            isLast: true,
            child: const Text('ปุ่มที่สอง'),
          ),
        ],
      ),
    );
  }
}

void main() {
  late GlobalKey first;
  late GlobalKey second;

  setUp(() {
    TourController.debugReset();
    first = GlobalKey();
    second = GlobalKey();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: _Page(first, second)));
  }

  Future<void> show(WidgetTester tester, TourStage stage) async {
    TourController.instance.show(stage, [first, second]);
    await tester.pumpAndSettle();
  }

  testWidgets('one highlighted widget shows a Thai tooltip with ถัดไป and ข้าม, no ย้อนกลับ on the first step', (tester) async {
    await pumpPage(tester);
    TourController.instance.replay();
    await show(tester, TourStage.home);

    expect(find.text('ขั้นแรก'), findsOneWidget);
    expect(find.text('คำอธิบายขั้นแรก'), findsOneWidget);
    expect(find.text('ถัดไป'), findsOneWidget);
    expect(find.text('ข้าม'), findsOneWidget);
    expect(find.text('ย้อนกลับ'), findsNothing);
  });

  testWidgets('ถัดไป moves on, ย้อนกลับ goes back', (tester) async {
    await pumpPage(tester);
    TourController.instance.replay();
    await show(tester, TourStage.home);

    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();
    expect(find.text('ขั้นที่สอง'), findsOneWidget);
    expect(find.text('เข้าใจแล้ว'), findsOneWidget);

    await tester.tap(find.text('ย้อนกลับ'));
    await tester.pumpAndSettle();
    expect(find.text('ขั้นแรก'), findsOneWidget);
  });

  testWidgets('ข้าม ends the whole tour and sets the seen flag', (tester) async {
    await pumpPage(tester);
    await TourController.instance.startForNewUser();
    await show(tester, TourStage.signUp);

    await tester.tap(find.text('ข้าม'));
    await tester.pumpAndSettle();

    expect(find.text('ขั้นแรก'), findsNothing);
    expect(TourController.instance.isActive, isFalse);
    expect(TourController.instance.wants(TourStage.role), isFalse);
    expect(await TourService().hasSeen(), isTrue);
  });

  testWidgets('finishing an earlier page keeps the tour going for the next page', (tester) async {
    await pumpPage(tester);
    await TourController.instance.startForNewUser();
    await show(tester, TourStage.signUp);

    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เข้าใจแล้ว'));
    await tester.pumpAndSettle();

    expect(TourController.instance.isActive, isTrue);
    expect(TourController.instance.wants(TourStage.signUp), isFalse); // already shown
    expect(TourController.instance.wants(TourStage.role), isTrue);
    expect(await TourService().hasSeen(), isFalse);
  });

  testWidgets('finishing the last page ends the tour and sets the seen flag', (tester) async {
    await pumpPage(tester);
    TourController.instance.replay();
    await show(tester, TourStage.plot);

    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เข้าใจแล้ว'));
    await tester.pumpAndSettle();

    expect(TourController.instance.isActive, isFalse);
    expect(await TourService().hasSeen(), isTrue);
  });

  testWidgets('startForNewUser does nothing once the tour has been seen', (tester) async {
    await TourService().markSeen();
    await TourController.instance.startForNewUser();
    expect(TourController.instance.isActive, isFalse);
    expect(TourController.instance.wants(TourStage.signUp), isFalse);
  });

  testWidgets('a step with onTap has no ถัดไป: tapping the widget does its job and moves on', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TourStep(
              stepKey: first,
              title: 'กดตรงนี้',
              description: 'ลองกดปุ่มนี้',
              isFirst: true,
              onTap: () => tapped++,
              child: const Text('ปุ่มจริง'),
            ),
            TourStep(
              stepKey: second,
              title: 'ขั้นที่สอง',
              description: 'คำอธิบายขั้นที่สอง',
              isLast: true,
              child: const Text('ปุ่มที่สอง'),
            ),
          ],
        ),
      ),
    ));
    TourController.instance.replay();
    await show(tester, TourStage.home);

    expect(find.text('กดตรงนี้'), findsOneWidget);
    expect(find.text('ถัดไป'), findsNothing);
    expect(find.text('ข้าม'), findsOneWidget);

    await tester.tap(find.text('ปุ่มจริง'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
    expect(find.text('ขั้นที่สอง'), findsOneWidget);
    expect(TourController.instance.isActive, isTrue);
  });

  testWidgets('nothing shows when no tour is running', (tester) async {
    await pumpPage(tester);
    await show(tester, TourStage.home);
    expect(find.text('ขั้นแรก'), findsNothing);
  });
}
