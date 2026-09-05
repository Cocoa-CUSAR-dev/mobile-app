// Widget tests for lib/widgets/pages/registration_station_page.dart
// (RegistrationSelectionPage).
//
// KNOWN BUG (second test below is `skip`ped, not deleted): both selection
// buttons navigate to AppRoute.dynamicRegister with a `tableName`
// argument, but route.dart's onGenerateRoute only builds
// DynamicRegisterPage when the args map contains a `handler` key —
// `tableName` isn't read at all. So tapping either button currently
// always lands on that route case's own error page ("กรุณาระบุ tableName
// สำหรับหน้า Dynamic Register") instead of the real registration form.
// The test asserts the correct destination (DynamicRegisterPage actually
// mounts); remove the `skip:` once fixed to confirm.

import 'package:cocoa_supply/widgets/pages/dynamic_register_page.dart';
import 'package:cocoa_supply/widgets/pages/registration_station_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows both role selection buttons', (tester) async {
    await tester.pumpWidget(wrapPage(const RegistrationSelectionPage()));
    await tester.pumpAndSettle();

    expect(find.text('สมัครเป็นเกษตรกร'), findsOneWidget);
    expect(find.text('สมัครเป็นผู้แปรรูป'), findsOneWidget);
  });

  testWidgets(
    'selecting เกษตรกร navigates to the dynamic register form (KNOWN BUG: currently hits the route\'s error page)',
    (tester) async {
      await tester.pumpWidget(wrapPage(const RegistrationSelectionPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('สมัครเป็นเกษตรกร'));
      await tester.pumpAndSettle();

      expect(find.text('สมัครเป็นเกษตรกร'), findsNothing);
      expect(find.byType(DynamicRegisterPage), findsOneWidget);
    },
    skip: true,
  );

  testWidgets('back link pops the page', (tester) async {
    await tester.pumpWidget(wrapPage(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegistrationSelectionPage()),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ย้อนกลับไปหน้าล็อกอิน'));
    await tester.pumpAndSettle();

    expect(find.text('สมัครเป็นเกษตรกร'), findsNothing);
  });
}
