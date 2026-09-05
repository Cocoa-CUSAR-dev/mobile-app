// Widget tests for lib/widgets/pages/farm_page.dart.

import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/pages/farm_page.dart';
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

  testWidgets('shows a loading indicator, then the empty state when there are no farms', (tester) async {
    await tester.pumpWidget(wrapPage(const FarmPage(), client: emptyMockClient()));

    expect(find.byType(ThreeDotsLoading), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('ไม่พบข้อมูล'), findsOneWidget);
    expect(find.text('เพิ่มข้อมูลฟาร์ม'), findsOneWidget);
  });

  testWidgets('lists farms with their plots inside a DataRecordContainer', (tester) async {
    final client = MockClient((request) async => jsonResponse([
      {
        'farm_id': 1,
        'farm_name': 'ไร่โกโก้พรีเมียม',
        'plots': [
          {'plot_id': 1, 'plot_name': 'แปลง 1'},
        ],
      },
    ], 200));

    await tester.pumpWidget(wrapPage(const FarmPage(), client: client));
    await tester.pumpAndSettle();

    expect(find.text('ไร่โกโก้พรีเมียม'), findsOneWidget);
    expect(find.text('แปลง 1'), findsOneWidget);
  });

  testWidgets('M-FARM-01 — the "เพิ่มข้อมูลฟาร์ม" button navigates to the register page', (tester) async {
    await tester.pumpWidget(wrapPage(const FarmPage(), client: emptyMockClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มข้อมูลฟาร์ม'));
    await tester.pumpAndSettle();

    expect(find.text('ลงทะเบียนข้อมูลฟาร์ม'), findsOneWidget);
  });
}
