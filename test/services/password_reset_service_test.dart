// Unit tests for lib/services/password_reset_service.dart.

import 'dart:convert';

import 'package:cocoa_supply/services/password_reset_service.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_helpers.dart';

void main() {
  group('requestCode', () {
    test('posts the trimmed login to forgot-password, with no token', () async {
      late http.Request seen;
      final service = PasswordResetService(
        client: MockClient((request) async {
          seen = request;
          return jsonResponse({'message': 'ok'}, 202);
        }),
      );

      await service.requestCode(' 0812345678 ');

      expect(seen.method, 'POST');
      expect(seen.url.toString(), '$testBaseUrl/api/v1/auth/forgot-password');
      expect(jsonDecode(seen.body), {'login': '0812345678'});
      expect(seen.headers.containsKey('Authorization'), isFalse);
    });

    test('a server that refuses is a ServerRejection with its own message', () async {
      final service = PasswordResetService(
        client: MockClient((request) async => jsonResponse({'detail': 'ขอรหัสบ่อยเกินไป'}, 429)),
      );

      expect(
        service.requestCode('0812345678'),
        throwsA(isA<ServerRejection>().having((e) => e.message, 'message', 'ขอรหัสบ่อยเกินไป')),
      );
    });
  });

  group('confirm', () {
    test('sends the code and the new password under the field names of the backend', () async {
      late http.Request seen;
      final service = PasswordResetService(
        client: MockClient((request) async {
          seen = request;
          return http.Response('', 204);
        }),
      );

      await service.confirm(login: '0812345678', code: ' 123456 ', newPassword: 'new-pass-1');

      expect(seen.url.toString(), '$testBaseUrl/api/v1/auth/forgot-password/confirm');
      expect(jsonDecode(seen.body), {'login': '0812345678', 'code': '123456', 'new_password': 'new-pass-1'});
    });

    test('a wrong or expired code is reported with the message of the backend', () async {
      final service = PasswordResetService(
        client: MockClient(
          (request) async => jsonResponse({'detail': 'รหัสไม่ถูกต้องหรือหมดอายุ กรุณาขอรหัสใหม่'}, 400),
        ),
      );

      expect(
        service.confirm(login: 'a', code: '000000', newPassword: 'new-pass-1'),
        throwsA(
          isA<ServerRejection>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'รหัสไม่ถูกต้องหรือหมดอายุ กรุณาขอรหัสใหม่'),
        ),
      );
    });

    test('a body that is not JSON falls back to a plain message', () async {
      final service = PasswordResetService(client: MockClient((request) async => http.Response('<html>', 502)));

      expect(
        service.confirm(login: 'a', code: '1', newPassword: 'new-pass-1'),
        throwsA(isA<ServerRejection>().having((e) => e.message, 'message', contains('ลองใหม่'))),
      );
    });
  });
}
