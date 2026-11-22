// Widget tests for lib/widgets/pages/forgot_password_page.dart.

import 'dart:convert';

import 'package:cocoa_supply/widgets/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../services/test_helpers.dart';

const Size _kTallPhoneSize = Size(1080, 2400);

Future<void> _tallViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = _kTallPhoneSize;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// The page on top of a first route, so that it can pop back to it.
Widget _app(http.Client client, {String login = ''}) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ForgotPasswordPage(initialLogin: login, client: client),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, http.Client client, {String login = ''}) async {
  await _tallViewport(tester);
  await tester.pumpWidget(_app(client, login: login));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks for a code, then shows the code step with a resend cooldown', (tester) async {
    final calls = <http.Request>[];
    final client = MockClient((request) async {
      calls.add(request);
      return jsonResponse({'message': 'ok'}, 202);
    });
    await _open(tester, client, login: '0812345678');

    expect(find.text('ส่งรหัส'), findsOneWidget);
    await tester.tap(find.text('ส่งรหัส'));
    await tester.pump();
    await tester.pump();

    expect(calls.single.url.path, '/api/v1/auth/forgot-password');
    expect(jsonDecode(calls.single.body), {'login': '0812345678'});
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsOneWidget);
    expect(find.textContaining('ขอรหัสใหม่ได้ใน 60 วินาที'), findsOneWidget);
    expect(find.text('ถ้าไม่ได้รับรหัส ให้ติดต่อผู้ดูแลเพื่อขอรีเซ็ต'), findsOneWidget);

    await tester.pump(const Duration(seconds: 61));
    expect(find.text('ขอรหัสใหม่'), findsOneWidget);
  });

  testWidgets('an empty login is refused without calling the backend', (tester) async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return jsonResponse({}, 202);
    });
    await _open(tester, client);

    await tester.tap(find.text('ส่งรหัส'));
    await tester.pump();

    expect(called, isFalse);
    expect(find.text('กรุณากรอกเบอร์มือถือหรืออีเมล'), findsOneWidget);
  });

  testWidgets('a short or mismatched password is refused before it is sent', (tester) async {
    final calls = <http.Request>[];
    final client = MockClient((request) async {
      calls.add(request);
      return jsonResponse({}, 202);
    });
    await _open(tester, client, login: '0812345678');
    await tester.tap(find.text('ส่งรหัส'));
    await tester.pump();
    await tester.pump();
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'abc');
    await tester.enterText(fields.at(2), 'abc');
    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pump();
    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'), findsOneWidget);

    await tester.enterText(fields.at(1), 'abcdef');
    await tester.enterText(fields.at(2), 'abcdeg');
    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pump();
    expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);
    expect(calls, hasLength(1)); // only the request for the code
  });

  testWidgets('a wrong code shows the message of the backend and stays on the page', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/confirm')) {
        return jsonResponse({'detail': 'รหัสไม่ถูกต้องหรือหมดอายุ กรุณาขอรหัสใหม่'}, 400);
      }
      return jsonResponse({'message': 'ok'}, 202);
    });
    await _open(tester, client, login: '0812345678');
    await tester.tap(find.text('ส่งรหัส'));
    await tester.pump();
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '000000');
    await tester.enterText(fields.at(1), 'new-pass-1');
    await tester.enterText(fields.at(2), 'new-pass-1');

    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pump();
    await tester.pump();

    expect(find.text('รหัสไม่ถูกต้องหรือหมดอายุ กรุณาขอรหัสใหม่'), findsOneWidget);
    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('a good code changes the password and goes back to the login page', (tester) async {
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/confirm')) {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 204);
      }
      return jsonResponse({'message': 'ok'}, 202);
    });
    await _open(tester, client, login: '0812345678');
    await tester.tap(find.text('ส่งรหัส'));
    await tester.pump();
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'new-pass-1');
    await tester.enterText(fields.at(2), 'new-pass-1');

    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();

    expect(sent, {'login': '0812345678', 'code': '123456', 'new_password': 'new-pass-1'});
    expect(find.byType(ForgotPasswordPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
