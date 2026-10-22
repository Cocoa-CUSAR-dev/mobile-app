// Unit tests for lib/services/auth_session.dart -- backend-hub's token pair:
// keeping it, refreshing it before it expires, and signing out.

import 'dart:convert';

import 'package:cocoa_supply/config/hub_config.dart';
import 'package:cocoa_supply/services/auth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_helpers.dart';

/// An unsigned JWT-shaped token whose `exp` is [seconds] from now; the app
/// only reads `exp`, the server checks signatures.
String jwtExpiringIn(int seconds) {
  String encode(Map<String, dynamic> v) =>
      base64Url.encode(utf8.encode(jsonEncode(v))).replaceAll('=', '');
  final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + seconds;
  return '${encode({'alg': 'HS256'})}.${encode({'sub': 'u-1', 'exp': exp})}.sig';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps both tokens from a hub login response', () async {
    expect(
      await AuthSession.saveFrom(
        hubPair(accessToken: 'a.b.c', refreshToken: 'r-1'),
      ),
      isTrue,
    );

    expect(await AuthSession.accessToken(), 'a.b.c');
    expect(
      await const FlutterSecureStorage().read(key: AuthSession.refreshKey),
      'r-1',
    );
  });

  test('ignores a response that is not a token pair', () async {
    expect(await AuthSession.saveFrom({'message': 'ok'}), isFalse);
    expect(await AuthSession.saveFrom([1, 2]), isFalse);
    expect(await AuthSession.accessToken(), isNull);
  });

  test('reads seconds left from the token, null when it is not a JWT', () {
    expect(
      AuthSession.secondsLeft(jwtExpiringIn(600)),
      inInclusiveRange(598, 600),
    );
    expect(AuthSession.secondsLeft('not-a-jwt'), isNull);
  });

  test(
    'a token with plenty of time left is sent as is, without calling the hub',
    () async {
      final fresh = jwtExpiringIn(1800);
      FlutterSecureStorage.setMockInitialValues({
        AuthSession.accessKey: fresh,
        AuthSession.refreshKey: 'r-1',
      });
      final client = MockClient(
        (_) async => throw StateError('should not be called'),
      );

      expect(await AuthSession.freshAccessToken(client), fresh);
    },
  );

  test(
    'an expiring token is refreshed first, and the new pair is kept',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        AuthSession.accessKey: jwtExpiringIn(10),
        AuthSession.refreshKey: 'r-1',
      });
      final newAccess = jwtExpiringIn(3600);
      final client = MockClient((request) async {
        expect(request.url.toString(), '$hubBaseUrl/api/v1/auth/refresh');
        expect(jsonDecode(request.body), {'refresh_token': 'r-1'});
        return jsonResponse(
          hubPair(accessToken: newAccess, refreshToken: 'r-2'),
          200,
        );
      });

      expect(await AuthSession.freshAccessToken(client), newAccess);
      expect(
        await const FlutterSecureStorage().read(key: AuthSession.refreshKey),
        'r-2',
      );
    },
  );

  test('a refused refresh token signs out', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthSession.accessKey: jwtExpiringIn(-60),
      AuthSession.refreshKey: 'revoked',
    });
    final client = MockClient(
      (_) async => jsonResponse({'detail': 'Refresh token is not valid'}, 401),
    );

    expect(await AuthSession.freshAccessToken(client), isNull);
    expect(await AuthSession.accessToken(), isNull);
  });

  test(
    'offline during refresh keeps the old token for the request to decide',
    () async {
      final old = jwtExpiringIn(10);
      FlutterSecureStorage.setMockInitialValues({
        AuthSession.accessKey: old,
        AuthSession.refreshKey: 'r-1',
      });
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );

      expect(await AuthSession.freshAccessToken(client), old);
    },
  );

  test(
    'sign out revokes the refresh token at the hub and forgets both tokens',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        AuthSession.accessKey: 'a.b.c',
        AuthSession.refreshKey: 'r-1',
      });
      final calls = <http.Request>[];
      final client = MockClient((request) async {
        calls.add(request);
        return http.Response('', 204);
      });

      await AuthSession.signOut(client);

      expect(calls.single.url.toString(), '$hubBaseUrl/api/v1/auth/logout');
      expect(jsonDecode(calls.single.body), {'refresh_token': 'r-1'});
      expect(await AuthSession.accessToken(), isNull);
    },
  );

  test(
    'sign out still forgets the tokens when the hub cannot be reached',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        AuthSession.accessKey: 'a.b.c',
        AuthSession.refreshKey: 'r-1',
      });
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );

      await AuthSession.signOut(client);

      expect(await AuthSession.accessToken(), isNull);
    },
  );
}
