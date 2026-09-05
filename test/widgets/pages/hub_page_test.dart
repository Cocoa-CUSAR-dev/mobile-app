// Widget tests for lib/widgets/pages/hub_page.dart.

import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/pages/hub_page.dart';
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

  testWidgets('shows a loading indicator, then the empty state when there are no hubs', (tester) async {
    await tester.pumpWidget(wrapPage(const HubPage(), client: emptyMockClient()));

    expect(find.byType(ThreeDotsLoading), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('ไม่พบข้อมูลหน่วยรวบรวม'), findsOneWidget);
    expect(find.text('เพิ่มข้อมูลหน่วยรวบรวม'), findsOneWidget);
  });

  testWidgets('lists hubs with their harvest transactions', (tester) async {
    final client = MockClient((request) async => jsonResponse([
      {
        'hub_id': 1,
        'hub_name': 'จุดรับซื้อกลาง',
        'harvests': [
          {'harvest_id': 1, 'farm_name': 'ไร่โกโก้พรีเมียม', 'grade_code': 'A'},
        ],
      },
    ], 200));

    await tester.pumpWidget(wrapPage(const HubPage(), client: client));
    await tester.pumpAndSettle();

    expect(find.text('จุดรับซื้อกลาง'), findsOneWidget);
    expect(find.text('ไร่โกโก้พรีเมียม'), findsOneWidget);
  });

  testWidgets('M-HUB-01 — the "เพิ่มข้อมูลหน่วยรวบรวม" button navigates to the register page', (tester) async {
    await tester.pumpWidget(wrapPage(const HubPage(), client: emptyMockClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มข้อมูลหน่วยรวบรวม'));
    await tester.pumpAndSettle();

    // HubRegisterPage doesn't set an explicit title (SimpleScaffold title:
    // '') so we confirm navigation via its step-indicator/heading text
    // instead of the (absent) AppBar title.
    expect(find.text('หน้า 1 จาก 3'), findsOneWidget);
  });
}
