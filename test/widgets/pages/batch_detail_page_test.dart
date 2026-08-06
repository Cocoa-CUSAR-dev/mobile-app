// Widget tests for lib/widgets/pages/batch_detail_page.dart.
//
// BatchBloc returns hard-coded mock data regardless of the batchNo/
// processingStationNo passed in (see lib/bloc/batch/batch.dart), so this
// just pins that the three DataRecordContainer sections render it.
//
// KNOWN BUG (second test below currently FAILS): same route-argument bug
// as registration_station_page_test.dart — _navigateToRegister here
// passes {'tableName': ..., 'compositeKeyData': ...} but route.dart's
// dynamicRegister case only looks for a `handler` key, so every "ใส่
// ข้อมูล"/edit action currently lands on that case's own error page
// instead of the dynamic form.

import 'package:cocoa_supply/widgets/pages/batch_detail_page.dart';
import 'package:cocoa_supply/widgets/pages/dynamic_register_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the fermentation, drying, and processing-record sections', (tester) async {
    await tester.pumpWidget(wrapPage(
      const BatchDetailPage(batchNo: 'B-001', processingStationNo: 'PS-001'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ข้อมูลการหมัก'), findsOneWidget);
    expect(find.text('ข้อมูลการทำแห้ง'), findsOneWidget);
    expect(find.text('ข้อมูลบันทึกการแปรรูป'), findsOneWidget);
    expect(find.textContaining('หมัก ณ วันที่ 5 มกราคม 2569'), findsOneWidget);
  });

  testWidgets('the fermentation section\'s "ใส่ข้อมูล" button opens the dynamic form (KNOWN BUG: currently hits the route\'s error page)', (tester) async {
    await tester.pumpWidget(wrapPage(
      const BatchDetailPage(batchNo: 'B-001', processingStationNo: 'PS-001'),
    ));
    await tester.pumpAndSettle();

    final addButtons = find.text('ใส่ข้อมูล');
    expect(addButtons, findsWidgets);

    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    expect(find.byType(DynamicRegisterPage), findsOneWidget);
  });
}
