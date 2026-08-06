// Widget tests for lib/widgets/pages/login_page.dart.
//
// Moved here from the old top-level test/auth_test.dart (split per page to
// mirror lib/widgets/pages/*.dart), with the same test cases preserved and
// the app's real, un-injected AppBloc.providers swapped for
// testBlocProviders() so LoginBloc's network calls are mocked instead of
// hitting a real http.Client().
//
// Test cases adapted from `test/testcase.md`:
//   * M-LOG-01/02  — username/password fields accept input
//   * M-LOG-03     — show-password button toggles visibility
//   * W-AUTH-01/02 — login page shows welcome banner + login form fields

import 'package:cocoa_supply/widgets/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

const Size _kTallPhoneSize = Size(1080, 2400);
const double _kDevicePixelRatio = 3.0;

Future<void> _setTallViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = _kDevicePixelRatio;
  tester.view.physicalSize = _kTallPhoneSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('W-AUTH-01 — login page renders welcome banner', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(wrapPage(const LoginPage()));
    await tester.pump();

    expect(find.text('ยินดีต้อนรับเข้าสู่แอปพลิเคชัน'), findsOneWidget);
  });

  testWidgets('W-AUTH-02 / M-LOG-01 / M-LOG-02 — login form shows input fields', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(wrapPage(const LoginPage()));
    await tester.pump();

    await tester.tap(find.text('มีบัญชีผู้ใช้แล้ว'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('M-LOG-03 — show-password button toggles visibility', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(wrapPage(const LoginPage()));
    await tester.pump();

    await tester.tap(find.text('มีบัญชีผู้ใช้แล้ว'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
  });

  testWidgets('M-REG-01 — registration button navigates to user-register page', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(wrapPage(const LoginPage()));
    await tester.pump();

    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    expect(find.text('ลงทะเบียนผู้ใช้งานใหม่'), findsOneWidget);
  });

  testWidgets('back button on the login form returns to the selection area', (tester) async {
    await _setTallViewport(tester);
    await tester.pumpWidget(wrapPage(const LoginPage()));
    await tester.pump();

    await tester.tap(find.text('มีบัญชีผู้ใช้แล้ว'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.text('ย้อนกลับ'));
    await tester.pumpAndSettle();

    expect(find.text('ท่านมีบัญชีผู้ใช้อยู่แล้วหรือไม่'), findsOneWidget);
  });
}
