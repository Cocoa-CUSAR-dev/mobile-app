// Unit tests for lib/services/profile_service.dart (AuthService).

import 'dart:async';

import 'package:cocoa_supply/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getProfile', () {
    test('returns a parsed Profile on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/auth/me');
        return jsonResponse({
          'user_id': 1,
          'first_name': 'สมชาย',
          'last_name': 'โกโก้ดี',
          'roles': ['farmer'],
        }, 200);
      });

      final profile = await AuthService(client: client).getProfile();

      expect(profile?.fullName, 'สมชาย โกโก้ดี');
      expect(profile?.roles, ['farmer']);
    });

    test('fails instead of hanging when the connection stalls', () async {
      // RootScaffold has no exit from its full-screen spinner other than
      // this future settling, so a stalled request used to leave the app
      // unusable until force quit. Anything thrown is fine -- what matters
      // is that it finishes at all.
      final client = MockClient((request) => Completer<http.Response>().future);

      await expectLater(
        AuthService(client: client).getProfile(),
        throwsA(anything),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('fails readably when a 200 carries a body that is not JSON', () async {
      // An empty or HTML 200 (a proxy or tunnel answering instead of the
      // API) makes _updateToken return null. A bare cast threw an opaque
      // TypeError that RootScaffold's catch swallowed, reproducing the
      // silently empty profile page this endpoint was fixed to stop
      // producing.
      final client = MockClient((request) async => http.Response('', 200));

      await expectLater(
        AuthService(client: client).getProfile(),
        throwsA('รูปแบบข้อมูลโปรไฟล์ไม่ถูกต้อง'),
      );
    });

    test('rethrows when the request fails', () async {
      final client = MockClient((request) async => jsonResponse({'error': 'unauthorized'}, 401));

      await expectLater(
        AuthService(client: client).getProfile(),
        throwsA(anything),
      );
    });
  });
}
