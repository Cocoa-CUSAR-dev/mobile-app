// Unit tests for lib/bloc/login/login_bloc.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/login/login_bloc.dart';
import 'package:cocoa_supply/bloc/login/login_event.dart';
import 'package:cocoa_supply/bloc/login/login_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          expect(request.url.toString(), 'http://localhost:8080/public/login');
          return jsonResponse({'has_profile': true}, 200);
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
        final client = MockClient((request) async => jsonResponse({'has_profile': false}, 200));
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
        final client = MockClient((request) async => jsonResponse({'error': 'invalid credentials'}, 401));
        return LoginBloc(client: client);
      },
      act: (bloc) => bloc.add(const LoginButtonPressed(username: '0812345678', password: 'wrong')),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginFailure>(),
      ],
    );
  });

  group('LoadLogin', () {
    blocTest<LoginBloc, LoginState>(
      'emits LoginSuccess(HOME) when a session cookie is already valid',
      build: () {
        SharedPreferences.setMockInitialValues({'auth_cookie': 'session=abc'});
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
