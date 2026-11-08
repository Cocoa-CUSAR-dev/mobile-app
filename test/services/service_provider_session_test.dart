// The token and error contract of the merged backend, as ServiceProvider
// lives it: login-like answers carry a token pair in the body, an expired
// access token is renewed with the refresh token, errors come as {"detail"}.

import 'dart:convert';

import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_helpers.dart';

const _storage = FlutterSecureStorage();

ServiceProvider<Map<String, dynamic>> _provider(
  MockClient client, {
  String endpoint = ApiEndpoints.tasks,
  bool useCookie = true,
}) => ServiceProvider<Map<String, dynamic>>(
  storageKey: 'k',
  endpoint: endpoint,
  isRealApi: true,
  useCookie: useCookie,
  client: client,
);

Map<String, dynamic> _pair({
  String access = 'new.access.jwt',
  String refresh = 'refresh-2',
}) => {
  ...tokenPairJson(roles: ['farmer']),
  'access_token': access,
  'refresh_token': refresh,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('storing the token pair', () {
    test('a login answer stores the access and the refresh token', () async {
      final client = MockClient((_) async => jsonResponse(_pair(), 200));

      await _provider(
        client,
        endpoint: ApiEndpoints.authLogin,
        useCookie: false,
      ).postData({'username': 'u', 'password': 'p'});

      expect(await _storage.read(key: 'auth_token'), 'new.access.jwt');
      expect(await _storage.read(key: 'auth_refresh_token'), 'refresh-2');
    });

    test(
      'an answer whose access token is not shaped like a JWT stores nothing',
      () async {
        final client = MockClient(
          (_) async =>
              jsonResponse({'access_token': 'nope', 'refresh_token': 'x'}, 200),
        );

        await _provider(client).postData({});

        expect(await _storage.read(key: 'auth_token'), isNull);
        expect(await _storage.read(key: 'auth_refresh_token'), isNull);
      },
    );

    test(
      'later requests send the stored access token as a Bearer header',
      () async {
        FlutterSecureStorage.setMockInitialValues({'auth_token': 'a.b.c'});
        late http.Request sent;
        final client = MockClient((request) async {
          sent = request;
          return jsonResponse([], 200);
        });

        await _provider(client).fetchData((json) => json);

        expect(sent.headers['Authorization'], 'Bearer a.b.c');
      },
    );
  });

  group('an expired access token', () {
    test(
      'is renewed with the refresh token and the request is sent again',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'old.access.jwt',
          'auth_refresh_token': 'refresh-1',
        });
        final seen = <String>[];
        final client = MockClient((request) async {
          seen.add(
            '${request.method} ${request.url.path} ${request.headers['Authorization'] ?? ''}',
          );
          if (request.url.path == ApiEndpoints.authRefresh) {
            expect(jsonDecode(request.body), {'refresh_token': 'refresh-1'});
            return jsonResponse(_pair(), 200);
          }
          if (request.headers['Authorization'] == 'Bearer old.access.jwt') {
            return jsonResponse({'detail': 'Token expired'}, 401);
          }
          return jsonResponse([
            {'task_id': 't1'},
          ], 200);
        });

        final rows = await _provider(client).fetchData((json) => json);

        expect(rows, hasLength(1));
        expect(seen, [
          'GET /api/v1/tasks Bearer old.access.jwt',
          'POST /api/v1/auth/refresh ',
          'GET /api/v1/tasks Bearer new.access.jwt',
        ]);
        expect(await _storage.read(key: 'auth_refresh_token'), 'refresh-2');
      },
    );

    test('several requests that fail together share one refresh', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'old.access.jwt',
        'auth_refresh_token': 'refresh-1',
      });
      var refreshes = 0;
      final client = MockClient((request) async {
        if (request.url.path == ApiEndpoints.authRefresh) {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return jsonResponse(_pair(), 200);
        }
        return request.headers['Authorization'] == 'Bearer old.access.jwt'
            ? jsonResponse({'detail': 'Token expired'}, 401)
            : jsonResponse([], 200);
      });

      await Future.wait([
        _provider(client).fetchData((json) => json),
        _provider(client).fetchData((json) => json),
        _provider(
          client,
          endpoint: ApiEndpoints.farms,
        ).fetchData((json) => json),
      ]);

      expect(refreshes, 1);
    });

    test(
      'stays a 401 for the caller when the refresh token is refused',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'old.access.jwt',
          'auth_refresh_token': 'refresh-1',
        });
        final client = MockClient((request) async {
          if (request.url.path == ApiEndpoints.authRefresh) {
            return jsonResponse({'detail': 'Refresh token is not valid'}, 401);
          }
          return jsonResponse({'detail': 'Token expired'}, 401);
        });

        await expectLater(
          _provider(client).postData({'a': 1}),
          throwsA(
            isA<ServerRejection>().having(
              (e) => e.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
      },
    );

    test('is not retried when there is no refresh token', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'old.access.jwt',
      });
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return jsonResponse({'detail': 'Token expired'}, 401);
      });

      await expectLater(
        _provider(client).postData({}),
        throwsA(isA<ServerRejection>()),
      );
      expect(calls, 1);
    });

    test('a login that fails with 401 does not try to refresh', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_refresh_token': 'refresh-1',
      });
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        return jsonResponse({'detail': 'wrong password'}, 401);
      });

      await expectLater(
        _provider(
          client,
          endpoint: ApiEndpoints.authLogin,
          useCookie: false,
        ).postData({}),
        throwsA(isA<ServerRejection>()),
      );
      expect(paths, [ApiEndpoints.authLogin]);
    });
  });

  group('errors', () {
    test("a failed POST reads the reason from the backend's detail", () async {
      final client = MockClient(
        (_) async => jsonResponse({'detail': 'ข้อมูลไม่ผ่านการตรวจสอบ'}, 422),
      );

      await expectLater(
        _provider(client).postData({}),
        throwsA(
          isA<ServerRejection>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'ข้อมูลไม่ผ่านการตรวจสอบ'),
        ),
      );
    });

    test(
      'a validation list has no single reason, so the generic one is used',
      () async {
        final client = MockClient(
          (_) async => jsonResponse({
            'detail': [
              {'msg': 'Field required'},
            ],
          }, 422),
        );

        await expectLater(
          _provider(client).postData({}),
          throwsA(
            isA<ServerRejection>().having(
              (e) => e.message,
              'message',
              'Post Error',
            ),
          ),
        );
      },
    );
  });

  group('logout', () {
    test(
      'forgets both tokens and tells the backend to revoke the refresh token',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'a.b.c',
          'auth_refresh_token': 'refresh-1',
        });
        late http.Request sent;
        final client = MockClient((request) async {
          sent = request;
          return http.Response('', 204);
        });

        await _provider(client).logout();

        expect(await _storage.read(key: 'auth_token'), isNull);
        expect(await _storage.read(key: 'auth_refresh_token'), isNull);
        expect(sent.url.path, ApiEndpoints.authLogout);
        expect(jsonDecode(sent.body), {'refresh_token': 'refresh-1'});
      },
    );

    test(
      'still signs out on the device when the backend cannot be reached',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'a.b.c',
          'auth_refresh_token': 'refresh-1',
        });
        final client = MockClient(
          (_) async => throw http.ClientException('offline'),
        );

        await _provider(client).logout();

        expect(await _storage.read(key: 'auth_token'), isNull);
        expect(await _storage.read(key: 'auth_refresh_token'), isNull);
      },
    );
  });

  group('isLoggedIn', () {
    test(
      'asks GET /api/v1/me and is true for an account that holds a role',
      () async {
        FlutterSecureStorage.setMockInitialValues({'auth_token': 'a.b.c'});
        late http.Request sent;
        final client = MockClient((request) async {
          sent = request;
          return jsonResponse({
            'user_id': 'u-1',
            'roles': ['farmer'],
            'profiles': {},
          }, 200);
        });

        expect(
          await _provider(
            client,
            endpoint: ApiEndpoints.authLogin,
            useCookie: false,
          ).isLoggedIn(),
          isTrue,
        );
        expect(sent.url.path, ApiEndpoints.me);
        expect(sent.headers['Authorization'], 'Bearer a.b.c');
      },
    );

    test(
      'renews an expired access token instead of signing the person out',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'old.access.jwt',
          'auth_refresh_token': 'refresh-1',
        });
        final client = MockClient((request) async {
          if (request.url.path == ApiEndpoints.authRefresh)
            return jsonResponse(_pair(), 200);
          return request.headers['Authorization'] == 'Bearer old.access.jwt'
              ? jsonResponse({'detail': 'Token expired'}, 401)
              : jsonResponse({
                  'user_id': 'u-1',
                  'roles': ['farmer'],
                }, 200);
        });

        expect(
          await _provider(
            client,
            endpoint: ApiEndpoints.authLogin,
            useCookie: false,
          ).isLoggedIn(),
          isTrue,
        );
        expect(await _storage.read(key: 'auth_token'), 'new.access.jwt');
      },
    );

    test(
      'is false, and forgets the tokens, when the refresh is refused too',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'old.access.jwt',
          'auth_refresh_token': 'refresh-1',
        });
        final client = MockClient(
          (_) async => jsonResponse({'detail': 'no'}, 401),
        );

        expect(
          await _provider(
            client,
            endpoint: ApiEndpoints.authLogin,
            useCookie: false,
          ).isLoggedIn(),
          isFalse,
        );
        expect(await _storage.read(key: 'auth_token'), isNull);
      },
    );
  });
}
