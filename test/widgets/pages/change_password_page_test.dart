// Widget tests for lib/widgets/pages/change_password_page.dart.

import 'dart:convert';

import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/pages/change_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../services/test_helpers.dart';

Future<void> _show(WidgetTester tester, http.Client client) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ChangePasswordPage(client: client),
      routes: {
        AppRoute.home: (_) => const Scaffold(body: Text('home page')),
        AppRoute.roleRegister: (_) => const Scaffold(body: Text('role page')),
      },
    ),
  );
}

Future<void> _fill(WidgetTester tester, String first, String second) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), first);
  await tester.enterText(fields.at(1), second);
  await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a short or mismatched password is refused before it is sent', (tester) async {
    var called = false;
    await _show(
      tester,
      MockClient((request) async {
        called = true;
        return jsonResponse(tokenPairJson(roles: ['farmer']), 200);
      }),
    );

    await _fill(tester, 'abc', 'abc');
    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'), findsOneWidget);

    await _fill(tester, 'abcdef', 'abcdeg');
    expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('sets the new password, keeps the new session and goes home', (tester) async {
    late http.Request seen;
    await _show(
      tester,
      MockClient((request) async {
        seen = request;
        return jsonResponse({
          ...tokenPairJson(roles: ['farmer']),
          'access_token': 'new.access.token',
          'refresh_token': 'refresh-2',
        }, 200);
      }),
    );

    await _fill(tester, 'new-pass-1', 'new-pass-1');

    expect(seen.method, 'PATCH');
    expect(seen.url.toString(), '$testBaseUrl/api/v1/auth/reset-password');
    expect(jsonDecode(seen.body), {'new_password': 'new-pass-1'});
    expect(find.text('home page'), findsOneWidget);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'), 'new.access.token');
  });

  testWidgets('an account with no role goes on to register one', (tester) async {
    await _show(tester, MockClient((request) async => jsonResponse(tokenPairJson(), 200)));

    await _fill(tester, 'new-pass-1', 'new-pass-1');

    expect(find.text('role page'), findsOneWidget);
  });

  testWidgets('a refusal shows its message and stays on the page', (tester) async {
    await _show(tester, MockClient((request) async => jsonResponse({'detail': 'รหัสผ่านยาวเกินไป'}, 422)));

    await _fill(tester, 'new-pass-1', 'new-pass-1');

    expect(find.text('รหัสผ่านยาวเกินไป'), findsOneWidget);
    expect(find.byType(ChangePasswordPage), findsOneWidget);
  });
}
