// Unit tests for lib/bloc/login/liff_login_bloc.dart: opening the LIFF link page
// (already linked? a login left half done?) and submitting the link form.

import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/login/liff_login_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/services/liff_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

/// A LIFF SDK that does what the test says and counts what it was asked.
class FakeLiff implements LiffApi {
  FakeLiff({this.loggedIn = false, this.token, this.initError});

  final bool loggedIn;
  final String? token;
  final Object? initError;

  int loginCalls = 0;

  @override
  Future<void> init(String liffId) async {
    if (initError != null) throw initError!;
  }

  @override
  bool get isLoggedIn => loggedIn;

  @override
  String? get idToken => token;

  @override
  void login() => loginCalls++;
}

MockClient neverCalled() =>
    MockClient((request) async => throw StateError('should not be called'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const submit = LiffLoginSubmitted(
    username: '0812345678',
    password: 'cocoa1234',
  );

  group('opening the page', () {
    blocTest<LiffLoginBloc, LiffLoginState>(
      'a LINE account that is already linked goes straight to success',
      build: () => LiffLoginBloc(
        liff: FakeLiff(loggedIn: true, token: 'line-token'),
        client: MockClient((request) async {
          expect(request.url.toString(), '$testBaseUrl/api/v1/auth/line/login');
          expect(jsonDecode(request.body), {'id_token': 'line-token'});
          return jsonResponse(tokenPairJson(roles: ['farmer']), 200);
        }),
      ),
      act: (bloc) => bloc.add(LiffInitRequested()),
      expect: () => [
        isA<LiffInitializing>(),
        isA<LiffLoginSuccess>().having((s) => s.hasProfile, 'hasProfile', true),
      ],
    );

    blocTest<LiffLoginBloc, LiffLoginState>(
      'a linked account that has no role yet is sent on to add one',
      build: () => LiffLoginBloc(
        liff: FakeLiff(loggedIn: true, token: 'line-token'),
        client: MockClient(
          (request) async => jsonResponse(tokenPairJson(), 200),
        ),
      ),
      act: (bloc) => bloc.add(LiffInitRequested()),
      expect: () => [
        isA<LiffInitializing>(),
        isA<LiffLoginSuccess>().having(
          (s) => s.hasProfile,
          'hasProfile',
          false,
        ),
      ],
    );

    blocTest<LiffLoginBloc, LiffLoginState>(
      'a LINE account that is not linked yet sees the landing page',
      build: () => LiffLoginBloc(
        liff: FakeLiff(loggedIn: true, token: 'line-token'),
        client: MockClient(
          (request) async => jsonResponse({'detail': 'not linked'}, 403),
        ),
      ),
      act: (bloc) => bloc.add(LiffInitRequested()),
      expect: () => [isA<LiffInitializing>(), isA<LiffLanding>()],
    );

    blocTest<LiffLoginBloc, LiffLoginState>(
      'a check that fails never blocks the landing page',
      build: () => LiffLoginBloc(
        liff: FakeLiff(loggedIn: true, token: 'line-token'),
        client: MockClient(
          (request) async => jsonResponse({'detail': 'down'}, 500),
        ),
      ),
      act: (bloc) => bloc.add(LiffInitRequested()),
      expect: () => [isA<LiffInitializing>(), isA<LiffLanding>()],
    );

    blocTest<LiffLoginBloc, LiffLoginState>(
      'not signed in with LINE yet: nothing is sent, the landing page shows',
      build: () =>
          LiffLoginBloc(liff: FakeLiff(loggedIn: false), client: neverCalled()),
      act: (bloc) => bloc.add(LiffInitRequested()),
      expect: () => [isA<LiffInitializing>(), isA<LiffLanding>()],
    );

    blocTest<LiffLoginBloc, LiffLoginState>(
      'signed in but LIFF has no ID token: nothing is sent, the landing page shows',
      build: () =>
          LiffLoginBloc(liff: FakeLiff(loggedIn: true), client: neverCalled()),
      act: (bloc) => bloc.add(LiffInitRequested()),
      expect: () => [isA<LiffInitializing>(), isA<LiffLanding>()],
    );
  });

  group('when LIFF cannot start', () {
    blocTest<LiffLoginBloc, LiffLoginState>(
      'the error is shown, with nothing to submit, and asking again can work',
      build: () => LiffLoginBloc(
        liff: FakeLiff(
          initError: Exception('Error: code_verifier does not match'),
        ),
        client: neverCalled(),
      ),
      act: (bloc) => bloc.add(LiffInitRequested()),
      expect: () => [
        isA<LiffInitializing>(),
        isA<LiffLoginFailure>()
            .having((s) => s.error, 'error', contains('code_verifier'))
            .having((s) => s.idToken, 'idToken', isNull),
      ],
    );
  });

  group('pressing "มีบัญชีผู้ใช้แล้ว"', () {
    test('starts the LINE login when not signed in with LINE', () async {
      final liff = FakeLiff(loggedIn: false);
      final bloc = LiffLoginBloc(liff: liff, client: neverCalled());

      bloc.add(LiffHasAccountPressed());
      await expectLater(bloc.stream, emits(isA<LiffInitializing>()));
      await Future<void>.delayed(Duration.zero);

      expect(liff.loginCalls, 1);
      await bloc.close();
    });

    blocTest<LiffLoginBloc, LiffLoginState>(
      'shows the form when LIFF has an ID token',
      build: () => LiffLoginBloc(
        liff: FakeLiff(loggedIn: true, token: 'line-token'),
        client: neverCalled(),
      ),
      act: (bloc) => bloc.add(LiffHasAccountPressed()),
      expect: () => [
        isA<LiffInitializing>(),
        isA<LiffReady>().having((s) => s.idToken, 'idToken', 'line-token'),
      ],
    );
  });

  blocTest<LiffLoginBloc, LiffLoginState>(
    'the form can be sent again after a refused submit',
    build: () => LiffLoginBloc(
      client: MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/api/v1/auth/line/link');
        return jsonResponse(tokenPairJson(roles: ['farmer']), 200);
      }),
    ),
    seed: () =>
        const LiffLoginFailure(error: 'wrong password', idToken: 'line-token'),
    act: (bloc) => bloc.add(submit),
    expect: () => [
      isA<LiffLoginLoading>().having((s) => s.idToken, 'idToken', 'line-token'),
      isA<LiffLoginSuccess>().having((s) => s.hasProfile, 'hasProfile', true),
    ],
  );

  blocTest<LiffLoginBloc, LiffLoginState>(
    'without an idToken there is nothing to send',
    build: () => LiffLoginBloc(
      client: MockClient(
        (request) async => throw StateError('should not be called'),
      ),
    ),
    seed: () => const LiffLoginFailure(error: 'liff.init failed'),
    act: (bloc) => bloc.add(submit),
    expect: () => [
      isA<LiffLoginFailure>().having((s) => s.idToken, 'idToken', isNull),
    ],
  );
}
