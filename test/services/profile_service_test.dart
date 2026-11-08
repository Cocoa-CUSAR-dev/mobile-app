// Unit tests for lib/services/profile_service.dart (AuthService).

import 'dart:async';
import 'dart:convert';

import 'package:cocoa_supply/services/profile_service.dart';
import 'package:cocoa_supply/services/service_provider.dart';
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
        expect(request.url.toString(), '$testBaseUrl/api/v1/me');
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

    test('fills the place names from the location list', () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        if (request.url.path == '/api/v1/me') {
          return jsonResponse({
            'user_id': 'u1',
            'roles': ['farmer'],
            'profiles': {
              'farmer': {
                'first_name': 'สมชาย',
                'last_name': 'โกโก้ดี',
                'subdistrict_id': 'sd1',
                'zip_code': '50300',
              },
            },
          }, 200);
        }
        return jsonResponse([
          {
            'subdistrict_id': 'sd1',
            'subdistrict_name': 'ช้างเผือก',
            'district_name': 'เมือง',
            'province_name': 'เชียงใหม่',
            'zip_code': '50300',
            'full_name': 'ต.ช้างเผือก อ.เมือง จ.เชียงใหม่ 50300',
          },
        ], 200);
      });

      final profile = await AuthService(client: client).getProfile();

      expect(requests.last.path, '/api/v1/ref/constants/location');
      expect(requests.last.queryParameters, {'subdistrict_id': 'sd1'});
      expect(
        [profile?.subdistrictName, profile?.districtName, profile?.provinceName],
        ['ช้างเผือก', 'เมือง', 'เชียงใหม่'],
      );
    });

    test('still returns the profile when the place lookup fails', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/me') {
          return jsonResponse({
            'user_id': 'u1',
            'roles': ['farmer'],
            'profiles': {
              'farmer': {'first_name': 'สมชาย', 'last_name': 'โกโก้ดี', 'subdistrict_id': 'sd1'},
            },
          }, 200);
        }
        return http.Response('boom', 500);
      });

      final profile = await AuthService(client: client).getProfile();

      expect(profile?.fullName, 'สมชาย โกโก้ดี');
      expect(profile?.subdistrictName, isNull);
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

  group('updateEmail', () {
    Future<Object?> sentFor(String email) async {
      Object? sent;
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), '$testBaseUrl/api/v1/me/account');
        sent = jsonDecode(request.body);
        return jsonResponse({'user_id': 'u1', 'email': null}, 200);
      });
      await AuthService(client: client).updateEmail(email);
      return sent;
    }

    test('sends the trimmed email', () async {
      expect(await sentFor(' a@test.com '), {'email': 'a@test.com'});
    });

    test('blank removes it', () async {
      expect(await sentFor('  '), {'email': null});
    });

    test('a taken email comes back as the hub said it', () async {
      final client = MockClient(
        (request) async => jsonResponse({'detail': 'อีเมลนี้ถูกใช้งานแล้ว'}, 409),
      );
      await expectLater(
        AuthService(client: client).updateEmail('a@test.com'),
        throwsA(isA<ServerRejection>().having((e) => e.message, 'message', 'อีเมลนี้ถูกใช้งานแล้ว')),
      );
    });
  });

  test('getProfile keeps the email once the place names are filled in', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/me') {
        return jsonResponse({
          'user_id': 'u1',
          'email': 'a@test.com',
          'roles': ['farmer'],
          'profiles': {
            'farmer': {'first_name': 'สมชาย', 'subdistrict_id': 's1'},
          },
        }, 200);
      }
      return jsonResponse([], 200);
    });

    final profile = await AuthService(client: client).getProfile();

    expect(profile?.email, 'a@test.com');
  });
}
