// Widget tests for lib/widgets/pages/processing_station_page.dart.

import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/pages/processing_station_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';
import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows a loading indicator, then the empty state when there are no stations', (tester) async {
    await tester.pumpWidget(wrapPage(const ProcessingStationPage(), client: emptyMockClient()));

    expect(find.byType(ThreeDotsLoading), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('ไม่พบข้อมูลสถานีแปรรูป'), findsOneWidget);
    expect(find.text('เพิ่มข้อมูลสถานีแปรรูป'), findsOneWidget);
  });

  testWidgets('lists stations with their batches', (tester) async {
    final client = MockClient((request) async => jsonResponse([
      {
        'processing_station_id': 1,
        'processing_station_name': 'ศูนย์แปรรูปแม่จัน',
        'batches': [
          {'batch_id': 1, 'origin': 'ริมรั้ว'},
        ],
      },
    ], 200));

    await tester.pumpWidget(wrapPage(const ProcessingStationPage(), client: client));
    await tester.pumpAndSettle();

    expect(find.text('ศูนย์แปรรูปแม่จัน'), findsOneWidget);
  });

  testWidgets('M-STAT-01 — the "เพิ่มข้อมูลสถานีแปรรูป" button navigates to the register page', (tester) async {
    await tester.pumpWidget(wrapPage(const ProcessingStationPage(), client: emptyMockClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มข้อมูลสถานีแปรรูป'));
    await tester.pumpAndSettle();

    expect(find.text('ชื่อสถานีแปรรูป *', findRichText: true), findsOneWidget);
  });
}
