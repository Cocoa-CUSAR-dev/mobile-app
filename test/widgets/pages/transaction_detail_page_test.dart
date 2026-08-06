// Widget tests for lib/widgets/pages/transaction_detail_page.dart.
//
// TransactionBloc returns hard-coded mock data regardless of the
// processingStationNo/transactionNo passed in (see
// lib/bloc/transaction/transaction.dart), so this pins that both
// DataRecordContainer sections render it.

import 'package:cocoa_supply/widgets/pages/transaction_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the weight/price and grade sections', (tester) async {
    await tester.pumpWidget(wrapPage(
      const TransactionDetailPage(processingStationNo: 'PS-001', transactionNo: 'TD-001'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ข้อมูลน้ำหนักและราคา'), findsOneWidget);
    expect(find.text('ข้อมูลการจัดเกรดคุณภาพ'), findsOneWidget);
    expect(find.textContaining('น้ำหนักรวม: 50.5 กก.'), findsOneWidget);
    expect(find.textContaining('ราคารวม: 450.0 บาท'), findsOneWidget);
  });

  testWidgets('shows a green check for clean grades and a red error icon for unclean ones', (tester) async {
    await tester.pumpWidget(wrapPage(
      const TransactionDetailPage(processingStationNo: 'PS-001', transactionNo: 'TD-001'),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });
}
