// Unit tests for lib/bloc/login/login_bloc.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/login/login_bloc.dart';
import 'package:cocoa_supply/bloc/login/login_event.dart';
import 'package:cocoa_supply/bloc/login/login_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cocoa_supply/config/hub_config.dart';

import '../../services/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginButtonPressed', () {
    blocTest<LoginBloc, LoginState>(
      'admin/password short-circuits straight to LoginSuccess without a network call',
      build: () {
        final client = MockClient((request) async => throw StateError('should not be called'));
        return LoginBloc(client: client);
      },
      act: (bloc) => bloc.add(const LoginButtonPressed(username: 'admin', password: 'password')),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>().having((s) => s.next_page, 'next_page', 'mock-jwt-token-12345'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a real user with an existing profile goes to HOME',
      build: () {
        final client = MockClient((request) async {
          expect(request.url.toString(), '$hubBaseUrl/api/v1/auth/login');
          return jsonResponse(hubPair(roles: ['farmer']), 200);
        });
        return LoginBloc(client: client);
      },
      act: (bloc) => bloc.add(const LoginButtonPressed(username: '0812345678', password: 'cocoa1234')),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>().having((s) => s.next_page, 'next_page', 'HOME'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a real user without a profile goes to REGIS_ROLE',
      build: () {
        final client = MockClient((request) async => jsonResponse(hubPair(roles: []), 200));
        return LoginBloc(client: client);
      },
      act: (bloc) => bloc.add(const LoginButtonPressed(username: '0812345678', password: 'cocoa1234')),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>().having((s) => s.next_page, 'next_page', 'REGIS_ROLE'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a rejected login emits LoginFailure',
      build: () {
        final client = MockClient(
          (request) async => jsonResponse({'detail': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'}, 401),
        );
        return LoginBloc(client: client);
      },
      act: (bloc) => bloc.add(const LoginButtonPressed(username: '0812345678', password: 'wrong')),
      expect: () => [
        isA<LoginLoading>(),
        // backend-hub's reason (`detail`) reaches the screen as-is.
        isA<LoginFailure>().having((s) => s.error, 'error', contains('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง')),
      ],
    );
  });

  group('LoadLogin', () {
    blocTest<LoginBloc, LoginState>(
      'emits LoginSuccess(HOME) when a stored session token is already valid',
      build: () {
        // The session token lives in flutter_secure_storage (APP-2), not
        // SharedPreferences -- ServiceProvider reads it back via _storage.
        SharedPreferences.setMockInitialValues({'auth_token': 'a-valid-jwt'});
        FlutterSecureStorage.setMockInitialValues({'auth_token': 'a-valid-jwt'});
        final client = MockClient((request) async => jsonResponse({'roles': ['farmer']}, 200));
        return LoginBloc(client: client);
      },
      act: (bloc) => bloc.add(LoadLogin()),
      expect: () => [
        isA<LoginSuccess>().having((s) => s.next_page, 'next_page', 'HOME'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits nothing when there is no valid session',
      build: () {
        final client = MockClient((request) async => http.Response('unauthorized', 401));
        return LoginBloc(client: client);
      },
      act: (bloc) => bloc.add(LoadLogin()),
      expect: () => [],
    );
  });
}
