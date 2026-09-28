// Smoke tests for lib/widgets/components/root_scaffold.dart.
//
// AuthService is now injectable (added alongside this test), so the
// profile fetch is backed by a MockClient instead of a real http.Client()
// — a real client's request doesn't resolve within flutter_test's
// fake-async pump() cycles even with HttpOverrides forcing a 400, since
// dart:io's callback doesn't advance on the fake clock the way a plain
// MockClient's Future-based response does.
//
// A profile with zero roles produces a nav item list of length 1 (just
// "หน้าหลัก"); BottomNavigationBar requires at least 2 items and asserts
// otherwise, so RootScaffold used to crash for any logged-in user with no
// roles assigned. Fixed by rendering no bottomNavigationBar at all below
// that threshold, instead of an unconditional BottomNavigationBar.

import 'package:cocoa_supply/services/profile_service.dart';
import 'package:cocoa_supply/widgets/components/root_scaffold.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

Future<void> _pumpUntilSpinnerGone(WidgetTester tester, {int maxPumps = 30}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(ThreeDotsLoading).evaluate().isEmpty) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'a profile with no roles renders a single-tab shell without crashing',
    (tester) async {
      final client = MockClient((request) async => jsonResponse({
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
        'roles': [],
      }, 200));

      await tester.pumpWidget(MaterialApp(
        home: RootScaffold(
          title: 'หน้าหลัก',
          currentIndex: 0,
          onItemSelected: (_) {},
          authService: AuthService(client: client),
          children: const [Text('home body')],
        ),
      ));

      expect(find.byType(ThreeDotsLoading), findsOneWidget);

      await _pumpUntilSpinnerGone(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('home body'), findsOneWidget);
    },
  );

  testWidgets(
    'a stale currentIndex from a previous, larger role set is clamped instead of crashing',
    (tester) async {
      // currentIndex=3 would have been valid for a farmer+processor+
      // hub_collector profile (4 tabs), but this profile only has
      // 'farmer' (2 tabs: home, farm) -- BottomNavigationBar/PageController
      // both assert index < item count, so this must clamp, not crash.
      final client = MockClient((request) async => jsonResponse({
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
        'roles': ['farmer'],
      }, 200));

      await tester.pumpWidget(MaterialApp(
        home: RootScaffold(
          title: 'หน้าหลัก',
          currentIndex: 3,
          onItemSelected: (_) {},
          authService: AuthService(client: client),
          children: const [Text('home body'), Text('farm body')],
        ),
      ));

      await _pumpUntilSpinnerGone(tester);

      expect(tester.takeException(), isNull);
      final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, 1); // clamped to the last real tab, not 3
    },
  );

  testWidgets('a farmer profile adds the ฟาร์ม tab', (tester) async {
    final client = MockClient((request) async => jsonResponse({
      'first_name': 'สมชาย',
      'last_name': 'โกโก้ดี',
      'roles': ['farmer'],
    }, 200));

    await tester.pumpWidget(MaterialApp(
      home: RootScaffold(
        title: 'หน้าหลัก',
        currentIndex: 0,
        onItemSelected: (_) {},
        authService: AuthService(client: client),
        children: const [Text('home body'), Text('farm body')],
      ),
    ));

    await _pumpUntilSpinnerGone(tester);

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.items, hasLength(2));
    expect(find.text('ฟาร์ม'), findsOneWidget);
  });

  group('address labels follow the province (APP-11)', () {
    // The register pages switch these labels for Bangkok. Without the same
    // switch here, a Bangkok farmer types their address under เขต/แขวง and
    // reads it back under อำเภอ/ตำบล.
    Future<void> openProfileSheet(WidgetTester tester, String provinceName) async {
      final client = MockClient((request) async => jsonResponse({
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
        'roles': ['farmer'],
        'subdistrict_name': 'ลุมพินี',
        'district_name': 'ปทุมวัน',
        'province_name': provinceName,
        'zip_code': '10330',
      }, 200));

      await tester.pumpWidget(MaterialApp(
        home: RootScaffold(
          title: 'หน้าหลัก',
          currentIndex: 0,
          onItemSelected: (_) {},
          authService: AuthService(client: client),
          children: const [Text('home body')],
        ),
      ));
      await _pumpUntilSpinnerGone(tester);
      await tester.tap(find.byIcon(Icons.account_circle).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('Bangkok shows เขต/แขวง', (tester) async {
      await openProfileSheet(tester, 'กรุงเทพมหานคร');

      expect(find.text('แขวง'), findsOneWidget);
      expect(find.text('เขต'), findsOneWidget);
      expect(find.text('ตำบล'), findsNothing);
      expect(find.text('อำเภอ'), findsNothing);
    });

    testWidgets('anywhere else keeps ตำบล/อำเภอ', (tester) async {
      await openProfileSheet(tester, 'จันทบุรี');

      expect(find.text('ตำบล'), findsOneWidget);
      expect(find.text('อำเภอ'), findsOneWidget);
      expect(find.text('แขวง'), findsNothing);
      expect(find.text('เขต'), findsNothing);
    });
  });
}
